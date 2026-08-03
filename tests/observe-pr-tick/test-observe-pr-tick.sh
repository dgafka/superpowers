#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_UNDER_TEST="$REPO_ROOT/scripts/observe-pr-tick.sh"

FAILURES=0
ONLY="${1:-}"

pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

run_test() {
    local name="$1"
    [[ -z "$ONLY" || "$ONLY" == "$name" ]]
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

# Run a tick and echo "action/reason/idle_count/delay_seconds" on one line, so a
# whole decision can be asserted in a single comparison.
tick() {
    local out
    out="$("$SCRIPT_UNDER_TEST" "$@")" || { echo "ERROR(exit=$?)"; return; }
    printf '%s/%s/%s/%s' \
        "$(awk -F= '/^action=/{print $2}'        <<<"$out")" \
        "$(awk -F= '/^reason=/{print $2}'        <<<"$out")" \
        "$(awk -F= '/^idle_count=/{print $2}'    <<<"$out")" \
        "$(awk -F= '/^delay_seconds=/{print $2}' <<<"$out")"
}

# A quiet PR: same fingerprint every check.
FP="OPEN|build:SUCCESS 3:1011 1:2022"

echo "== the three-strike idle sequence"
if run_test idle-sequence; then
    assert_equals "$(tick --state OPEN --fingerprint "$FP" --last-fingerprint "$FP" --idle-count 0)" \
        "wait/unchanged/1/1200" "first quiet check -> counter 1, next check in 20min"
    assert_equals "$(tick --state OPEN --fingerprint "$FP" --last-fingerprint "$FP" --idle-count 1)" \
        "wait/unchanged/2/1800" "second quiet check -> counter 2, next check in 30min"
    assert_equals "$(tick --state OPEN --fingerprint "$FP" --last-fingerprint "$FP" --idle-count 2)" \
        "stop/idle_limit/3/0" "third quiet check -> stop, no reschedule"
fi

echo "== no empty runs: a quiet check never dispatches an agent"
if run_test no-dispatch-when-quiet; then
    for n in 0 1; do
        local_action="$(tick --state OPEN --fingerprint "$FP" --last-fingerprint "$FP" --idle-count "$n" | cut -d/ -f1)"
        assert_equals "$local_action" "wait" "idle-count=$n quiet check does not dispatch"
    done
fi

echo "== a change restarts the backoff from the beginning"
if run_test change-resets; then
    assert_equals "$(tick --state OPEN --fingerprint "$FP-new" --last-fingerprint "$FP" --idle-count 2)" \
        "dispatch/changed/0/600" "change after 2 quiet checks -> counter 0, back to 10min"
    assert_equals "$(tick --state OPEN --fingerprint "$FP-new" --last-fingerprint "$FP" --idle-count 0)" \
        "dispatch/changed/0/600" "change from a fresh counter -> dispatch, 10min"
    # The reset must be a real reset, not a decrement: after the change the
    # full three-strike sequence has to be available again.
    assert_equals "$(tick --state OPEN --fingerprint "$FP" --last-fingerprint "$FP" --idle-count 0)" \
        "wait/unchanged/1/1200" "counting starts over at 1 after a reset"
fi

echo "== full lifecycle: quiet, quiet, change, then three quiet checks"
if run_test lifecycle; then
    idle=0
    last_fp_seen=""   # nothing stored yet, as on the very first check
    delays=()
    actions=()
    action=""
    # Feed a scripted sequence of fingerprints through the loop, carrying the
    # counter and stored fingerprint forward exactly as the parent session
    # would: one first look, two quiet checks, a change, then three quiet.
    for observed in "$FP" "$FP" "$FP" "$FP-moved" "$FP-moved" "$FP-moved" "$FP-moved"; do
        out="$("$SCRIPT_UNDER_TEST" --state OPEN --fingerprint "$observed" \
                --last-fingerprint "$last_fp_seen" --idle-count "$idle" 2>/dev/null)"
        action="$(awk -F= '/^action=/{print $2}' <<<"$out")"
        actions+=("$action")
        delays+=("$(awk -F= '/^delay_seconds=/{print $2}' <<<"$out")")
        idle="$(awk -F= '/^idle_count=/{print $2}' <<<"$out")"
        last_fp_seen="$observed"
        if [[ "$action" == "stop" ]]; then break; fi
    done
    assert_equals "${actions[*]}" "dispatch wait wait dispatch wait wait stop" \
        "sequence: first check dispatches, two quiet, change dispatches, then stop on the third quiet check"
    assert_equals "${delays[*]}" "600 1200 1800 600 1200 1800 0" \
        "delays follow 10/20/30 and restart at 10 after the change"
fi

echo "== terminal states and guards outrank the idle rule"
if run_test guards; then
    assert_equals "$(tick --state MERGED --fingerprint "$FP" --last-fingerprint "$FP" --idle-count 0)" \
        "stop/pr_merged/0/0" "merged PR stops immediately"
    assert_equals "$(tick --state CLOSED --fingerprint "$FP-new" --last-fingerprint "$FP" --idle-count 0)" \
        "stop/pr_closed/0/0" "closed PR stops even though the fingerprint changed"
    assert_equals "$(tick --state OPEN --fingerprint "$FP-new" --last-fingerprint "$FP" --idle-count 0 --blocked)" \
        "stop/blocked_on_user/0/0" "blocked on the user stops rescheduling"
    assert_equals "$(tick --state OPEN --fingerprint "$FP-new" --last-fingerprint "$FP" --idle-count 0 --pass-count 20)" \
        "stop/ceiling_passes/0/0" "pass ceiling stops a PR that never goes idle"
    assert_equals "$(tick --state OPEN --fingerprint "$FP-new" --last-fingerprint "$FP" --idle-count 0 --elapsed-minutes 120)" \
        "stop/ceiling_elapsed/0/0" "elapsed ceiling stops a PR that never goes idle"
    assert_equals "$(tick --state OPEN --fingerprint "$FP" --last-fingerprint "$FP" --idle-count 3)" \
        "stop/idle_limit/3/0" "a counter already at the limit stays stopped"
fi

echo "== a failed probe fails toward doing work"
if run_test probe-unavailable; then
    assert_equals "$(tick --state OPEN --fingerprint "" --last-fingerprint "$FP" --idle-count 2)" \
        "dispatch/probe_unavailable/0/600" "empty fingerprint dispatches instead of counting as idle"
fi

echo "== usage errors"
if run_test usage; then
    "$SCRIPT_UNDER_TEST" --fingerprint x >/dev/null 2>&1
    assert_equals "$?" "2" "missing --state exits 2"
    "$SCRIPT_UNDER_TEST" --state OPEN --idle-count -1 >/dev/null 2>&1
    assert_equals "$?" "2" "negative --idle-count exits 2"
fi

echo
if [[ "$FAILURES" -eq 0 ]]; then
    echo "All tests passed."
else
    echo "$FAILURES test(s) failed."
fi
exit $((FAILURES > 0))
