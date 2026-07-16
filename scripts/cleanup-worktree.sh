#!/usr/bin/env bash
# cleanup-worktree.sh — agnostic worktree + Docker teardown.
#
# Sourceable: when sourced, only defines cw_* functions (for tests).
# Executable: `cleanup-worktree.sh plan|execute [DIR] [opts]`.

# --- guard ------------------------------------------------------------------

# Physical absolute path of a directory (resolves symlinks), or empty.
cw_abspath() { ( cd "$1" 2>/dev/null && pwd -P ); }

# Echo the git toplevel for DIR; non-zero if DIR is not inside a git repo.
cw_resolve_root() {
    local dir="${1:-.}" top
    top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || return 1
    cw_abspath "$top"
}

# Return 0 if DIR is the main working tree (not a linked worktree).
# Agnostic: the main checkout's git-dir IS the common dir; a linked
# worktree's git-dir is <common>/worktrees/<name>.
cw_is_main_checkout() {
    local dir="${1:-.}" gd gc
    gd="$(git -C "$dir" rev-parse --absolute-git-dir 2>/dev/null)" || return 2
    gc="$(git -C "$dir" rev-parse --git-common-dir 2>/dev/null)" || return 2
    case "$gc" in /*) : ;; *) gc="$(cd "$dir" && cw_abspath "$gc")" ;; esac
    gd="$(cw_abspath "$gd")"
    gc="$(cw_abspath "$gc")"
    [ "$gd" = "$gc" ]
}

# Echo the main working tree path for the repo containing DIR.
cw_main_root() {
    local dir="${1:-.}" line
    line="$(git -C "$dir" worktree list --porcelain 2>/dev/null | grep '^worktree ' | head -1)" || return 1
    cw_abspath "${line#worktree }"
}

# --- Makefile discovery -----------------------------------------------------

# Teardown-ish target names, in preference order.
CW_MAKE_TARGETS="down stop teardown destroy compose-down docker-down kill clean rm"

# Return 0 if the make dry-run expansion in $1 actually tears docker down.
cw_expansion_is_teardown() {
    printf '%s\n' "$1" | grep -Eq \
        'docker[ -]compose[^&|;]*[[:space:]](down|stop|rm|kill)|docker[[:space:]]+(rm|stop|kill)[[:space:]]'
}

# Return 0 if the expansion in $1 removes named volumes.
cw_expansion_removes_volumes() {
    printf '%s\n' "$1" | grep -Eq -- '(^|[[:space:]])(-v|--volumes)([[:space:]]|$)'
}

# Discover Makefile teardown targets under ROOT. For each Makefile directory,
# emit at most one line: "<dir>\t<target>\t<volumes|novolumes>" for the highest
# preference target whose `make -n` expansion actually tears docker down.
# Returns 0 if at least one candidate was emitted.
cw_find_make_teardown() {
    local root="${1:-.}" mf dir target expansion found=1
    command -v make >/dev/null 2>&1 || return 1
    while IFS= read -r mf; do
        [ -n "$mf" ] || continue
        dir="$(cw_abspath "$(dirname "$mf")")"
        for target in $CW_MAKE_TARGETS; do
            expansion="$(make -C "$dir" -n "$target" 2>/dev/null)" || continue
            cw_expansion_is_teardown "$expansion" || continue
            if cw_expansion_removes_volumes "$expansion"; then
                printf '%s\t%s\t%s\n' "$dir" "$target" "volumes"
            else
                printf '%s\t%s\t%s\n' "$dir" "$target" "novolumes"
            fi
            found=0
            break
        done
    done < <(find "$root" -maxdepth 3 \
        \( -name node_modules -o -name vendor -o -name .git \) -prune -o \
        -type f \( -name Makefile -o -name makefile -o -name GNUmakefile \) -print 2>/dev/null | sort)
    return $found
}

# --- container-label discovery (docker) -------------------------------------

CW_WD_LABEL='com.docker.compose.project.working_dir'
CW_PROJ_LABEL='com.docker.compose.project'
CW_CFG_LABEL='com.docker.compose.project.config_files'

# Read one label ($2) off a container ($1).
cw_container_label() {
    docker inspect -f "{{index .Config.Labels \"$2\"}}" "$1" 2>/dev/null
}

# Return 0 if candidate path $1 is ROOT ($2) or under it. Robust to a
# candidate that no longer exists on disk (falls back to literal matching),
# so a straggler whose working_dir was already removed is still matched.
cw_path_under() {
    local c="$1" r="$2" cr rr
    rr="$(cw_abspath "$r" 2>/dev/null)"; [ -n "$rr" ] || rr="$r"
    cr="$(cw_abspath "$c" 2>/dev/null)"
    if [ -n "$cr" ]; then
        case "$cr" in "$rr"|"$rr"/*) return 0 ;; esac
    fi
    case "$c" in "$rr"|"$rr"/*|"$r"|"$r"/*) return 0 ;; esac
    return 1
}

# Echo container IDs (running or stopped) whose compose working_dir label is
# ROOT or under it. Empty output (rc 0) when docker is unavailable.
cw_list_worktree_containers() {
    local root id wd
    root="${1:-.}"
    docker ps -aq 2>/dev/null | while read -r id; do
        [ -n "$id" ] || continue
        wd="$(cw_container_label "$id" "$CW_WD_LABEL")"
        [ -n "$wd" ] || continue
        cw_path_under "$wd" "$root" && echo "$id"
    done
}

# Echo unique "<project>\t<config_files>" for compose stacks whose containers
# live under ROOT.
cw_discover_compose_projects() {
    local root="${1:-.}" id proj cfg
    cw_list_worktree_containers "$root" | while read -r id; do
        [ -n "$id" ] || continue
        proj="$(cw_container_label "$id" "$CW_PROJ_LABEL")"
        cfg="$(cw_container_label "$id" "$CW_CFG_LABEL")"
        [ -n "$proj" ] && printf '%s\t%s\n' "$proj" "$cfg"
    done | sort -u
}

# --- teardown + removal -----------------------------------------------------

# Run a Makefile teardown target from its directory.
cw_run_make_teardown() {
    local dir="$1" target="$2"
    make -C "$dir" "$target"
}

# Tear down a compose project reconstructed from its recorded labels.
# $1=project  $2=comma-separated config_files (may be empty)  $3=volumes|novolumes
cw_compose_down() {
    local proj="$1" cfg="${2:-}" vols="${3:-novolumes}"
    local args=() vflag=() f files
    IFS=',' read -ra files <<< "$cfg"
    for f in ${files[@]+"${files[@]}"}; do [ -n "$f" ] && args+=( -f "$f" ); done
    [ "$vols" = volumes ] && vflag=(-v)
    docker compose -p "$proj" ${args[@]+"${args[@]}"} down ${vflag[@]+"${vflag[@]}"} --remove-orphans
}

# Force-remove any straggler container whose working_dir is under ROOT.
cw_backstop_remove() {
    local root="$1" id
    cw_list_worktree_containers "$root" | while read -r id; do
        [ -n "$id" ] && docker rm -f "$id" >/dev/null 2>&1
    done
}

# Remove the git worktree at WT (from the safe MAIN cwd) and prune.
cw_remove_worktree() {
    local main="$1" wt="$2"
    git -C "$main" worktree remove --force "$wt" || return 1
    [ -d "$wt" ] && rm -rf "$wt"
    git -C "$main" worktree prune
}

# --- CLI dispatch -----------------------------------------------------------

cw_main() {
    echo "cleanup-worktree: not yet implemented" >&2
    return 1
}

# Only run when executed, not when sourced.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    cw_main "$@"
fi
