#!/usr/bin/env bash
# Decide what the PR-observation loop does on this tick.
#
# Pure decision function: no network, no git, no side effects. The caller
# probes the PR (see commands/create-pull-request.md Step 11), passes the
# resulting state in, and obeys the answer. Keeping the idle/backoff rule
# here means it is enforced mechanically rather than re-derived from prose
# on every wake-up.
#
# Usage:
#   observe-pr-tick.sh --state OPEN \
#                      --fingerprint "<probe output>" \
#                      --last-fingerprint "<stored probe output>" \
#                      --idle-count 0 \
#                      --pass-count 0 \
#                      --elapsed-minutes 0 \
#                      [--blocked]
#
# Emits key=value lines on stdout:
#   action=stop|dispatch|wait
#   reason=<short slug>
#   idle_count=<counter to store>
#   delay_seconds=<next ScheduleWakeup delay; 0 when action=stop>
#
#   dispatch — something moved: dispatch a pass agent, then wait delay_seconds
#   wait     — nothing moved: dispatch nothing, just reschedule
#   stop     — end observation; do not reschedule
#
# Exit status is 0 for any successful decision, 2 for bad usage.

set -uo pipefail

STATE=""
FINGERPRINT=""
LAST_FINGERPRINT=""
IDLE_COUNT=0
PASS_COUNT=0
ELAPSED_MINUTES=0
BLOCKED=0

# Hard limits. Idle backoff: 3 consecutive quiet checks end the loop.
IDLE_LIMIT=3
MAX_PASSES=20
MAX_ELAPSED_MINUTES=120

# Delay before the next check, indexed by the idle counter after this tick.
# 0 (something moved) -> 10min, 1 -> 20min, 2 -> 30min. A change resets the
# counter to 0, so the backoff always restarts from 10min.
delay_for_idle_count() {
    case "$1" in
        0) echo 600 ;;
        1) echo 1200 ;;
        2) echo 1800 ;;
        *) echo 0 ;;
    esac
}

die() { echo "observe-pr-tick: $1" >&2; exit 2; }

is_uint() { [[ "$1" =~ ^[0-9]+$ ]]; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --state)            STATE="${2:-}"; shift 2 ;;
        --fingerprint)      FINGERPRINT="${2:-}"; shift 2 ;;
        --last-fingerprint) LAST_FINGERPRINT="${2:-}"; shift 2 ;;
        --idle-count)       IDLE_COUNT="${2:-}"; shift 2 ;;
        --pass-count)       PASS_COUNT="${2:-}"; shift 2 ;;
        --elapsed-minutes)  ELAPSED_MINUTES="${2:-}"; shift 2 ;;
        --blocked)          BLOCKED=1; shift ;;
        -h|--help)          sed -n '2,30p' "$0"; exit 0 ;;
        *)                  die "unknown argument: $1" ;;
    esac
done

[[ -n "$STATE" ]] || die "--state is required"
for pair in "idle-count:$IDLE_COUNT" "pass-count:$PASS_COUNT" \
            "elapsed-minutes:$ELAPSED_MINUTES"; do
    is_uint "${pair#*:}" || die "--${pair%%:*} must be a non-negative integer"
done

decide() {
    # Avoid ${var^^}/${var,,}: macOS ships bash 3.2, where they are a syntax error.
    local upper_state lower_state
    upper_state="$(printf '%s' "$STATE" | tr '[:lower:]' '[:upper:]')"
    lower_state="$(printf '%s' "$STATE" | tr '[:upper:]' '[:lower:]')"

    # 1. Terminal PR state wins over everything else.
    if [[ "$upper_state" == "MERGED" || "$upper_state" == "CLOSED" ]]; then
        emit stop "pr_${lower_state}" "$IDLE_COUNT"
        return
    fi

    # 2. Blocked on the user: their reply is the resume signal, so waking up
    #    to rediscover the same blocked state is pure burn.
    if [[ "$BLOCKED" -eq 1 ]]; then
        emit stop blocked_on_user "$IDLE_COUNT"
        return
    fi

    # 3. Absolute ceiling. Backstops the case the idle rule cannot catch: a PR
    #    that keeps changing, so no check is ever idle.
    if [[ "$PASS_COUNT" -ge "$MAX_PASSES" ]]; then
        emit stop ceiling_passes "$IDLE_COUNT"
        return
    fi
    if [[ "$ELAPSED_MINUTES" -ge "$MAX_ELAPSED_MINUTES" ]]; then
        emit stop ceiling_elapsed "$IDLE_COUNT"
        return
    fi

    # 4. An idle counter already at the limit stops, whatever else is true.
    if [[ "$IDLE_COUNT" -ge "$IDLE_LIMIT" ]]; then
        emit stop idle_limit "$IDLE_COUNT"
        return
    fi

    # 5. No fingerprint means the probe failed. Fail toward doing work: treat
    #    it as changed rather than idling on data we do not have.
    if [[ -z "$FINGERPRINT" ]]; then
        emit dispatch probe_unavailable 0
        return
    fi

    # 6. Something moved -> reset the counter, restarting the backoff at 10min.
    if [[ "$FINGERPRINT" != "$LAST_FINGERPRINT" ]]; then
        emit dispatch changed 0
        return
    fi

    # 7. Nothing moved. Count the idle check; stop on the third one.
    local next=$((IDLE_COUNT + 1))
    if [[ "$next" -ge "$IDLE_LIMIT" ]]; then
        emit stop idle_limit "$next"
    else
        emit wait unchanged "$next"
    fi
}

emit() {
    local action="$1" reason="$2" idle="$3" delay=0
    [[ "$action" == "stop" ]] || delay="$(delay_for_idle_count "$idle")"
    printf 'action=%s\nreason=%s\nidle_count=%s\ndelay_seconds=%s\n' \
        "$action" "$reason" "$idle" "$delay"
}

decide
