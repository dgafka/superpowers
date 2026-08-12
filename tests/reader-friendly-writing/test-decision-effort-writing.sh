#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RFW="$REPO_ROOT/skills/reader-friendly-writing/SKILL.md"
CREATE_PR="$REPO_ROOT/skills/create-pull-request/SKILL.md"
REVIEW="$REPO_ROOT/skills/review-changes/SKILL.md"
BRAINSTORMING="$REPO_ROOT/skills/brainstorming/SKILL.md"
IMPROVE_WORKFLOW="$REPO_ROOT/skills/improve-workflow/SKILL.md"
FIXTURES="$SCRIPT_DIR/decision-effort-fixtures.md"

FAILURES=0

pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

assert_contains() {
    local path="$1" needle="$2" description="$3"
    if grep -qF -- "$needle" "$path"; then
        pass "$description"
    else
        fail "$description"
        echo "    missing: $needle"
    fi
}

assert_not_contains() {
    local path="$1" needle="$2" description="$3"
    if grep -qF -- "$needle" "$path"; then
        fail "$description"
        echo "    still present: $needle"
    else
        pass "$description"
    fi
}

echo "== shared rule optimizes the reader's next decision"
assert_contains "$RFW" "reader's next decision" "shared rule names the decision-effort end"
assert_contains "$RFW" "workflow-learning summaries" "shared rule declares every direct caller's narrative scope"
assert_contains "$RFW" "improve-workflow" "shared rule names improve-workflow as a caller"
assert_contains "$RFW" "reduces more reconstruction work than it adds" "shared rule requires a visual to earn its cost"
assert_contains "$RFW" "does not govern" "shared rule excludes comment prose"
assert_contains "$RFW" "thread replies" "shared rule excludes thread replies"
assert_not_contains "$RFW" "Default to a visual." "shared rule does not mandate a visual"
assert_not_contains "$RFW" "Pair the flow diagrams" "shared rule does not mandate a before/after pair"
assert_not_contains "$RFW" "Does the first sentence state the outcome" "shared rule does not force outcome-first wording"
assert_not_contains "$RFW" "After the bottom line" "shared rule does not assume outcome-first sequencing"

echo "== callers do not reintroduce mandatory visual defaults"
for path in "$CREATE_PR" "$REVIEW" "$BRAINSTORMING"; do
    assert_contains "$path" "only when it reduces reconstruction work" "$(basename "$(dirname "$path")") inherits the decision-effort threshold"
done
assert_not_contains "$CREATE_PR" "A visual is the default" "create-pull-request does not force a visual"
assert_not_contains "$CREATE_PR" "Diagrams are paired" "create-pull-request does not force a pair"
assert_not_contains "$REVIEW" "pairing is **unconditional in this phase**" "review-changes does not force diagrams"
assert_not_contains "$BRAINSTORMING" "a visual by default" "brainstorming does not force visuals"
assert_not_contains "$BRAINSTORMING" "paired Mermaid diagram" "brainstorming does not force paired diagrams"
assert_contains "$IMPROVE_WORKFLOW" "decision-relevant" "improve-workflow inherits the decision-relevant opening"

echo "== behavioral fixtures cover both omission and use"
for heading in \
    "## Rejected: outcome-first adds work" \
    "## Accepted: causal Motivation" \
    "## Counterexample: diagram earns its place" \
    "## Accepted: terse review reply"; do
    assert_contains "$FIXTURES" "$heading" "fixture includes $heading"
done

if [[ $FAILURES -gt 0 ]]; then
    echo "FAILED: $FAILURES assertion(s)"
    exit 1
fi

echo "All assertions passed."
