#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_UNDER_TEST="$REPO_ROOT/scripts/cleanup-worktree.sh"

FAILURES=0
ONLY="${1:-}"

pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }
skip() { echo "  [SKIP] $1"; }

docker_available() { command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; }

TEST_IMAGE="redis:7.2-alpine"

# Bring up a one-service compose stack rooted at $1, project name $2.
compose_up_stack() {
    local dir="$1" proj="$2"
    cat > "$dir/docker-compose.yml" <<EOF
services:
  cache:
    image: $TEST_IMAGE
    command: ["redis-server"]
EOF
    ( cd "$dir" && docker compose -p "$proj" up -d ) >/dev/null 2>&1
}
compose_down_stack() {
    local dir="$1" proj="$2"
    ( cd "$dir" && docker compose -p "$proj" down -v ) >/dev/null 2>&1 || true
}

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

# ---------------------------------------------------------------------------
# Task 3: container-label discovery (needs docker daemon)
# ---------------------------------------------------------------------------
test_container_discovery() {
    if ! docker_available; then skip "container discovery (no docker daemon)"; return; fi
    # shellcheck source=/dev/null
    source "$SCRIPT_UNDER_TEST"

    local in_dir out_dir in_proj out_proj in_id
    in_dir="$(mktemp -d)"; in_proj="cwtin$RANDOM"
    out_dir="$(mktemp -d)"; out_proj="cwtout$RANDOM"

    compose_up_stack "$in_dir" "$in_proj"
    compose_up_stack "$out_dir" "$out_proj"

    local listed
    listed="$(cw_list_worktree_containers "$in_dir")"
    in_id="$(cd "$in_dir" && docker compose -p "$in_proj" ps -q cache)"

    assert_contains "$listed" "${in_id:0:12}" "lists the container whose working_dir is under the target root"
    assert_equals "$(printf '%s\n' "$listed" | grep -c .)" "1" "lists exactly the in-root container, excludes the other stack"

    local projs
    projs="$(cw_discover_compose_projects "$in_dir")"
    assert_contains "$projs" "$in_proj" "discovers the compose project name from container labels"
    if printf '%s' "$projs" | grep -Fq "$out_proj"; then
        fail "compose project discovery excludes stacks outside the root"
    else
        pass "compose project discovery excludes stacks outside the root"
    fi

    compose_down_stack "$in_dir" "$in_proj"
    compose_down_stack "$out_dir" "$out_proj"
    rm -rf "$in_dir" "$out_dir"
}

run_test test_container_discovery

# ---------------------------------------------------------------------------
# Task 4a: worktree removal (no docker)
# ---------------------------------------------------------------------------
test_worktree_removal() {
    # shellcheck source=/dev/null
    source "$SCRIPT_UNDER_TEST"
    local roots main wt
    roots="$(make_repo_with_worktree)"
    main="${roots%% *}"; wt="${roots##* }"
    local wt_abs; wt_abs="$(cw_abspath "$wt")"

    cw_remove_worktree "$main" "$wt"
    assert_true $? "remove_worktree exits zero"
    [ ! -d "$wt" ]; assert_true $? "worktree directory is gone"
    if git -C "$main" worktree list --porcelain | grep -Fq "worktree $wt_abs"; then
        fail "worktree no longer registered in git"
    else
        pass "worktree no longer registered in git"
    fi
    rm -rf "$(dirname "$main")"
}

run_test test_worktree_removal

# ---------------------------------------------------------------------------
# Task 4b: compose teardown + backstop (needs docker daemon)
# ---------------------------------------------------------------------------
test_teardown_and_backstop() {
    if ! docker_available; then skip "teardown + backstop (no docker daemon)"; return; fi
    # shellcheck source=/dev/null
    source "$SCRIPT_UNDER_TEST"

    # compose_down tears the discovered stack down.
    local dir proj id
    dir="$(mktemp -d)"; proj="cwtd$RANDOM"
    compose_up_stack "$dir" "$proj"
    local line cfg
    line="$(cw_discover_compose_projects "$dir")"
    cfg="${line#*$'\t'}"
    cw_compose_down "$proj" "$cfg" novolumes
    assert_equals "$(cw_list_worktree_containers "$dir" | grep -c .)" "0" "compose_down removes the stack's containers"
    rm -rf "$dir"

    # backstop force-removes a straggler labelled under the root.
    local sroot sid
    sroot="$(mktemp -d)"
    sid="$(docker run -d --label com.docker.compose.project.working_dir="$sroot/svc" "$TEST_IMAGE" redis-server 2>/dev/null)"
    assert_equals "$(cw_list_worktree_containers "$sroot" | grep -c .)" "1" "straggler is discovered before backstop"
    cw_backstop_remove "$sroot"
    assert_equals "$(cw_list_worktree_containers "$sroot" | grep -c .)" "0" "backstop force-removes the straggler"
    docker rm -f "$sid" >/dev/null 2>&1 || true
    rm -rf "$sroot"
}

run_test test_teardown_and_backstop

# ---------------------------------------------------------------------------
# Task 5a: CLI guard/plan (no docker needed for the refusal path)
# ---------------------------------------------------------------------------
test_cli_refuses_main() {
    local roots main out rc
    roots="$(make_repo_with_worktree)"
    main="${roots%% *}"

    out="$(bash "$SCRIPT_UNDER_TEST" plan "$main" 2>&1)"; rc=$?
    assert_equals "$rc" "2" "plan on the main checkout exits 2 (refused)"
    assert_contains "$out" "main checkout" "refusal message mentions the main checkout"

    out="$(bash "$SCRIPT_UNDER_TEST" execute "$main" --yes 2>&1)"; rc=$?
    assert_equals "$rc" "2" "execute on the main checkout exits 2 (refused)"
    rm -rf "$(dirname "$main")"
}

run_test test_cli_refuses_main

# ---------------------------------------------------------------------------
# Task 5c: plan reports uncommitted changes (removal uses --force)
# ---------------------------------------------------------------------------
test_plan_reports_dirty_worktree() {
    local roots main wt out
    roots="$(make_repo_with_worktree)"
    main="${roots%% *}"; wt="${roots##* }"

    out="$(bash "$SCRIPT_UNDER_TEST" plan "$wt" 2>&1)"
    assert_contains "$out" "DIRTY=no" "clean worktree reports DIRTY=no"

    echo "scratch" > "$wt/untracked.txt"
    out="$(bash "$SCRIPT_UNDER_TEST" plan "$wt" 2>&1)"
    assert_contains "$out" "DIRTY=yes" "worktree with untracked file reports DIRTY=yes"

    rm -rf "$(dirname "$main")"
}

run_test test_plan_reports_dirty_worktree

# ---------------------------------------------------------------------------
# Task 5b: CLI plan + execute end-to-end (needs docker daemon)
# ---------------------------------------------------------------------------
test_cli_plan_and_execute() {
    if ! docker_available; then skip "CLI plan/execute end-to-end (no docker daemon)"; return; fi
    local roots main wt proj out rc cid
    roots="$(make_repo_with_worktree)"
    main="${roots%% *}"; wt="${roots##* }"
    proj="cwte$RANDOM"
    compose_up_stack "$wt" "$proj"
    cid="$(cd "$wt" && docker compose -p "$proj" ps -q cache)"

    out="$(bash "$SCRIPT_UNDER_TEST" plan "$wt" 2>&1)"; rc=$?
    assert_equals "$rc" "0" "plan on the worktree exits 0"
    assert_contains "$out" "MECHANISM=compose" "plan detects compose fallback when no Makefile"
    assert_contains "$out" "WORKTREE_ROOT=$(cd "$wt" && pwd -P)" "plan reports the worktree root"
    assert_contains "$out" "${cid:0:12}" "plan lists the container to be removed"

    out="$(bash "$SCRIPT_UNDER_TEST" execute "$wt" --yes 2>&1)"; rc=$?
    assert_equals "$rc" "0" "execute exits 0"
    assert_contains "$out" "removed" "execute confirms worktree removal"
    [ ! -d "$wt" ]; assert_true $? "worktree directory removed after execute"
    assert_equals "$(docker ps -aq --filter "id=$cid" | grep -c .)" "0" "stack container removed after execute"

    # Safety net in case execute failed partway.
    compose_down_stack "$wt" "$proj"
    rm -rf "$(dirname "$main")"
}

run_test test_cli_plan_and_execute

echo
if [[ "$FAILURES" -eq 0 ]]; then
    echo "All tests passed."
    exit 0
else
    echo "$FAILURES test(s) failed."
    exit 1
fi
