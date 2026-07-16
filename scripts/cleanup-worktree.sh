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

# --- CLI dispatch -----------------------------------------------------------

cw_main() {
    echo "cleanup-worktree: not yet implemented" >&2
    return 1
}

# Only run when executed, not when sourced.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    cw_main "$@"
fi
