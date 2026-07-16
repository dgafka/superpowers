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

# --- CLI dispatch -----------------------------------------------------------

cw_main() {
    echo "cleanup-worktree: not yet implemented" >&2
    return 1
}

# Only run when executed, not when sourced.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    cw_main "$@"
fi
