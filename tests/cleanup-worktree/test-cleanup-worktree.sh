#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_UNDER_TEST="$REPO_ROOT/scripts/cleanup-worktree.sh"

FAILURES=0
ONLY="${1:-}"

pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

assert_equals() {
    local actual="$1" expected="$2" desc="$3"
    if [[ "$actual" == "$expected" ]]; then
        pass "$desc"
    else
        fail "$desc"
        echo "    expected: $expected"
        echo "    actual:   $actual"
    fi
}

assert_contains() {
    local haystack="$1" needle="$2" desc="$3"
    if printf '%s' "$haystack" | grep -Fq -- "$needle"; then
        pass "$desc"
    else
        fail "$desc"
        echo "    expected to find: $needle"
        echo "    in: $haystack"
    fi
}

assert_true() {
    local desc="$2"
    if [[ "$1" -eq 0 ]]; then pass "$desc"; else fail "$desc (expected success, got exit $1)"; fi
}

assert_false() {
    local desc="$2"
    if [[ "$1" -ne 0 ]]; then pass "$desc"; else fail "$desc (expected failure, got exit 0)"; fi
}

# Build a throwaway repo with one committed file and a linked worktree.
# Echoes: "<main_root> <worktree_root>"
make_repo_with_worktree() {
    local base main wt
    base="$(mktemp -d)"
    main="$base/main"
    wt="$base/wt"
    git init -q "$main"
    git -C "$main" config user.email t@t.t
    git -C "$main" config user.name t
    : > "$main/README.md"
    git -C "$main" add -A
    git -C "$main" commit -qm init
    git -C "$main" worktree add -q -b feature "$wt" >/dev/null 2>&1
    echo "$main $wt"
}

run_test() {
    local name="$1"
    if [[ -n "$ONLY" && "$ONLY" != "$name" ]]; then return; fi
    echo "== $name =="
    "$name"
}

# ---------------------------------------------------------------------------
# Task 1: guard logic
# ---------------------------------------------------------------------------
test_guard_detects_main_vs_worktree() {
    # shellcheck source=/dev/null
    source "$SCRIPT_UNDER_TEST"
    local roots main wt
    roots="$(make_repo_with_worktree)"
    main="${roots%% *}"
    wt="${roots##* }"

    assert_equals "$(cw_resolve_root "$main")" "$(cd "$main" && pwd -P)" "resolve_root on main returns main toplevel"
    assert_equals "$(cw_resolve_root "$wt")"   "$(cd "$wt" && pwd -P)"   "resolve_root on worktree returns worktree toplevel"

    cw_is_main_checkout "$main"; assert_true $? "main checkout detected as main"
    cw_is_main_checkout "$wt";   assert_false $? "linked worktree not detected as main"

    assert_equals "$(cw_main_root "$wt")" "$(cd "$main" && pwd -P)" "main_root from worktree points at main checkout"

    rm -rf "$(dirname "$main")"
}

run_test test_guard_detects_main_vs_worktree

# ---------------------------------------------------------------------------
# Task 2: Makefile teardown-target discovery (dry-run validated, no docker)
# ---------------------------------------------------------------------------
test_makefile_discovery() {
    # shellcheck source=/dev/null
    source "$SCRIPT_UNDER_TEST"
    local root out

    # A: single Makefile, `down` removes volumes.
    root="$(mktemp -d)"
    printf 'down:\n\tdocker compose down -v\n' > "$root/Makefile"
    out="$(cw_find_make_teardown "$root")"
    assert_true $? "find_make_teardown succeeds when a docker teardown target exists"
    assert_contains "$out" "$(cw_abspath "$root")	down	volumes" "picks 'down' target and detects volume removal"
    rm -rf "$root"

    # B: prefer `down` over `stop` when both are docker teardowns.
    root="$(mktemp -d)"
    printf 'stop:\n\tdocker compose stop\ndown:\n\tdocker compose down\n' > "$root/Makefile"
    out="$(cw_find_make_teardown "$root")"
    assert_contains "$out" "	down	novolumes" "prefers 'down' over 'stop'; no -v means novolumes"
    rm -rf "$root"

    # C: a 'down' target that does not touch docker is rejected.
    root="$(mktemp -d)"
    printf 'down:\n\techo nothing-to-do\n' > "$root/Makefile"
    out="$(cw_find_make_teardown "$root")"
    assert_false $? "rejects a teardown-named target that does not tear docker down"
    assert_equals "$out" "" "no candidate emitted for non-docker target"
    rm -rf "$root"

    # D: two Makefiles in different dirs -> ambiguous (two candidates).
    root="$(mktemp -d)"
    mkdir -p "$root/a" "$root/b"
    printf 'down:\n\tdocker compose down\n' > "$root/a/Makefile"
    printf 'down:\n\tdocker compose down\n' > "$root/b/Makefile"
    out="$(cw_find_make_teardown "$root")"
    assert_equals "$(printf '%s\n' "$out" | grep -c '	down	')" "2" "emits one candidate per Makefile dir (ambiguous)"
    rm -rf "$root"
}

run_test test_makefile_discovery

echo
if [[ "$FAILURES" -eq 0 ]]; then
    echo "All tests passed."
    exit 0
else
    echo "$FAILURES test(s) failed."
    exit 1
fi
