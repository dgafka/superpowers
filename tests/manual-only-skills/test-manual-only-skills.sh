#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SELF="$SCRIPT_DIR/$(basename "$0")"

FAILURES=0
ONLY="${1:-}"

pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

run_test() {
    local name="$1"
    [[ -z "$ONLY" || "$ONLY" == "$name" ]]
}

assert_file_exists() {
    local path="$1" desc="$2"
    if [[ -f "$path" ]]; then
        pass "$desc"
    else
        fail "$desc"
        echo "    missing: ${path#"$REPO_ROOT"/}"
    fi
}

assert_file_absent() {
    local path="$1" desc="$2"
    if [[ ! -e "$path" ]]; then
        pass "$desc"
    else
        fail "$desc"
        echo "    should not exist: ${path#"$REPO_ROOT"/}"
    fi
}

assert_contains() {
    local path="$1" needle="$2" desc="$3"
    if [[ ! -f "$path" ]]; then
        fail "$desc"
        echo "    missing file: ${path#"$REPO_ROOT"/}"
    elif grep -qF -- "$needle" "$path"; then
        pass "$desc"
    else
        fail "$desc"
        echo "    not found in ${path#"$REPO_ROOT"/}: $needle"
    fi
}

assert_not_contains() {
    local path="$1" needle="$2" desc="$3"
    if [[ ! -f "$path" ]]; then
        fail "$desc"
        echo "    missing file: ${path#"$REPO_ROOT"/}"
    elif grep -qF -- "$needle" "$path"; then
        fail "$desc"
        echo "    unexpectedly found in ${path#"$REPO_ROOT"/}: $needle"
    else
        pass "$desc"
    fi
}

# Search a set of files for a fixed string and fail listing every hit. Scoping is
# deliberate per caller: release notes and docs/ legitimately record the old shape.
assert_no_hits() {
    local needle="$1" desc="$2"
    shift 2
    local hits
    hits="$(grep -rIlF -- "$needle" "$@" 2>/dev/null | grep -vF -- "$SELF" || true)"
    if [[ -z "$hits" ]]; then
        pass "$desc"
    else
        fail "$desc"
        while IFS= read -r h; do echo "    still references it: ${h#"$REPO_ROOT"/}"; done <<<"$hits"
    fi
}

# Workflow skills that must be manual-only on both platforms.
WORKFLOW_SKILLS=(review-changes create-pull-request improve-workflow cleanup-worktree orchestration-research)

echo "== manual-only workflow skills live under skills/"
if run_test relocated; then
    for s in "${WORKFLOW_SKILLS[@]}"; do
        assert_file_exists "$REPO_ROOT/skills/$s/SKILL.md" "skills/$s/SKILL.md exists"
    done
    assert_file_absent "$REPO_ROOT/commands" "commands/ is gone"
fi

echo "== each is blocked from model invocation in Claude Code"
if run_test claude_code_manual_only; then
    for s in "${WORKFLOW_SKILLS[@]}"; do
        assert_contains "$REPO_ROOT/skills/$s/SKILL.md" "disable-model-invocation: true" \
            "$s blocks model invocation"
    done
fi

echo "== each is blocked from implicit invocation in Codex"
if run_test codex_manual_only; then
    for s in "${WORKFLOW_SKILLS[@]}"; do
        assert_contains "$REPO_ROOT/skills/$s/agents/openai.yaml" "allow_implicit_invocation: false" \
            "$s opts out of Codex implicit invocation"
    done
fi

echo "== the shared rule set stays agent-invocable"
if run_test shared_rules_invocable; then
    RFW="$REPO_ROOT/skills/reader-friendly-writing/SKILL.md"
    assert_file_exists "$RFW" "skills/reader-friendly-writing/SKILL.md exists"
    assert_not_contains "$RFW" "disable-model-invocation" \
        "reader-friendly-writing does not block model invocation"
    assert_file_absent "$REPO_ROOT/skills/reader-friendly-writing/agents/openai.yaml" \
        "reader-friendly-writing has no Codex opt-out"
fi

echo "== callers invoke the shared rule set instead of including a path"
if run_test callers_invoke_shared_rules; then
    for s in review-changes create-pull-request improve-workflow brainstorming; do
        assert_contains "$REPO_ROOT/skills/$s/SKILL.md" "reader-friendly-writing" \
            "$s references the reader-friendly-writing skill"
    done
fi

echo "== no leftover Claude-Code-only constructs in skills/"
if run_test no_leftovers; then
    # hooks/ keeps CLAUDE_PLUGIN_ROOT for the session-start hook — skills/ must not.
    assert_no_hits 'CLAUDE_PLUGIN_ROOT' "no skill resolves paths via CLAUDE_PLUGIN_ROOT" \
        "$REPO_ROOT/skills"
    assert_no_hits '$ARGUMENTS' "no SKILL.md relies on \$ARGUMENTS substitution" \
        $(find "$REPO_ROOT/skills" -name SKILL.md)
    assert_no_hits 'commands/' "nothing in skills/, tests/ or the moved helpers points at commands/" \
        "$REPO_ROOT/skills" "$REPO_ROOT/tests" \
        "$REPO_ROOT/skills/cleanup-worktree/cleanup-worktree.sh" \
        "$REPO_ROOT/skills/create-pull-request/observe-pr-tick.sh"
fi

echo "== helper scripts moved beside the skills that call them"
if run_test helpers_colocated; then
    for pair in "cleanup-worktree/cleanup-worktree.sh" "create-pull-request/observe-pr-tick.sh"; do
        p="$REPO_ROOT/skills/$pair"
        assert_file_exists "$p" "skills/$pair exists"
        if [[ -x "$p" ]]; then
            pass "skills/$pair is executable"
        else
            fail "skills/$pair is executable"
        fi
    done
    assert_file_absent "$REPO_ROOT/scripts/cleanup-worktree.sh" "old scripts/cleanup-worktree.sh is gone"
    assert_file_absent "$REPO_ROOT/scripts/observe-pr-tick.sh" "old scripts/observe-pr-tick.sh is gone"
fi

echo
if [[ $FAILURES -gt 0 ]]; then
    echo "FAILED: $FAILURES assertion(s)"
    exit 1
fi
echo "All assertions passed."
