---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

**No completion claims without fresh verification evidence.**

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

Before claiming any status or expressing satisfaction:

1. **Identify** what command proves this claim.
2. **Run** the full command, fresh and complete — no extrapolation from a previous run.
3. **Read** the full output. Check the exit code. Count the failures.
4. **Verify** the output confirms the claim.
   - If no: state the actual status with evidence.
   - If yes: state the claim *with* evidence.
5. **Only then** make the claim.

Skip any step and you are lying, not verifying.

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:** ✅ Run the test command, see the pass count in the output, *then* say "all tests pass". ❌ "Should pass now" / "Looks correct".

**Regression tests (TDD Red-Green):** ✅ Write the test → run (pass) → revert the fix → run (must fail) → restore → run (pass). ❌ "I've written a regression test" without the red-green verification.

**Build:** ✅ Run the build, confirm exit 0, *then* say "build passes". ❌ "Linter passed" — the linter doesn't check compilation.

**Requirements:** ✅ Re-read the plan, build a checklist, verify each item, report gaps or completion. ❌ "Tests pass, phase complete" — tests passing isn't the same as requirements met.

**Agent delegation:** ✅ Agent reports success → check the VCS diff → verify the changes independently → report the actual state. ❌ Trust the agent's report.

## Why This Matters

From 24 failure memories:
- your human partner said "I don't believe you" - trust broken
- Undefined functions shipped - would crash
- Missing requirements shipped - incomplete features
- Time wasted on false completion → redirect → rework
- Violates: "Honesty is a core value. If you lie, you'll be replaced."

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.
