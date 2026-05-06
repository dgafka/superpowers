---
name: executing-plans
description: Use when you have an approved design spec from brainstorming and need to implement it - decomposes the spec into tasks, identifies parallel-safe work, and executes with per-task TDD discipline
---

# Executing Plans

## Overview

Read approved spec → decompose into tasks → identify parallel-safe groups → execute with TDD → hand off to finishing.

**Announce at start:** "I'm using the executing-plans skill to implement this spec."

**Input:** A design spec from brainstorming, typically at `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`. If the user didn't name a path, use the most recent spec in that directory or ask.

## The Process

### Step 1: Load and Review Spec

1. Read the spec file end-to-end
2. Review critically — gaps, ambiguity, contradictions, unstated decisions, missing edge cases
3. If any concern blocks execution: raise it with the user before starting
4. If clear: continue

Do not skip the critical read. The spec was reviewed at design-time, but execution surfaces gaps that design-time didn't.

### Step 2: Prepare the Plan

Decompose the spec into a TodoWrite checklist of bite-sized tasks. Each task:

- Touches a focused unit (one component, one function group, one file group)
- Produces a working, testable increment
- Has a clear acceptance signal (a test that passes, a command that exits 0)

After listing tasks, **group them by parallel-safety**:

- **Parallel-safe group:** Tasks that touch disjoint files and have no sequential dependency on each other. These can have their tool calls batched into a single assistant turn (parallel Read/Edit/Write/Bash).
- **Sequential:** Tasks that share files, depend on a prior task's output, or build on each other. These run one at a time, in order.

Mark each task in the TodoWrite list with its group. Show the grouped plan to the user once before starting Step 3 — this is the only checkpoint between spec approval and execution.

### Step 3: Execute Tasks (TDD per task)

For each task — running parallel-safe groups together, sequential ones in order:

1. Mark in_progress
2. **RED** — write the failing test, run it, confirm it fails for the expected reason
3. **GREEN** — write the minimal code to make the test pass, run it, confirm pass
4. **REFACTOR** — only if there's a real cleanup to do; otherwise skip
5. Commit (test + implementation together)
6. Mark completed

When running a parallel-safe group, batch the independent tool calls into a single assistant turn. Don't serialize work that has no dependency.

Never write implementation before its test exists. Tests prove the spec is being implemented; without them you're guessing.

### Step 4: Complete Development

After all tasks are completed and verified:

- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- The spec is missing information needed to proceed
- A test fails for a reason you can't explain
- An instruction is genuinely ambiguous
- Verification fails repeatedly with the same root cause
- You hit a blocker you can't unblock

**Ask for clarification rather than guessing.**

## When to Revisit the Spec

**Return to Step 1 when:**
- The user updates the spec mid-execution
- Implementation reveals a fundamental design issue (escalate; don't paper over)

**Don't force through blockers** — stop and ask.

## Remember

- Read and critique the spec before generating tasks
- Decompose into bite-sized, testable tasks
- Group by parallel-safety; batch tool calls for parallel-safe work
- TDD per task: RED → GREEN → REFACTOR → commit
- Don't write implementation before its test
- Never start implementation on main/master without explicit user consent
- Stop when blocked, don't guess

## Integration

**Called by:**
- **superpowers:brainstorming** — terminal handoff after the user approves the spec

**Required workflow skills:**
- **superpowers:test-driven-development** — applied per task during Step 3
- **superpowers:finishing-a-development-branch** — completes development after all tasks
