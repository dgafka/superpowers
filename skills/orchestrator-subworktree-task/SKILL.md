---
name: orchestrator-subworktree-task
description: Use when implementing one approved Orca task inside its dedicated implementation sub-worktree
---

# Orchestrator Subworktree Task

## Overview

Implement the active Orca task directly in the current Codex session. The task prompt is the plan: it carries the goal, boundaries, dependencies, guidance, acceptance criteria, and environment commands.

There is one execution path. Do not ask how to execute and do not dispatch another implementation agent.

**REQUIRED SUB-SKILL:** Use superpowers:test-driven-development for every behavior change.

**REQUIRED SUB-SKILL:** Use superpowers:verification-before-completion before reporting success.

**REQUIRED SUB-SKILL:** Use orchestration for Orca task questions and lifecycle reporting.

## 1. Anchor to the Task

Read the injected Orca task prompt end-to-end. Identify:

- Task name, goal, and observable outcome
- Global guidance and task-specific additions
- Owned scope and explicit exclusions
- Dependency branch and expected stack position
- Acceptance criteria and verification commands

Verify the current checkout is the task's dedicated sub-worktree, its name matches the Orca task where tooling permits, and the branch is not the repository's default branch. Stop and report a placement error rather than editing the main coordinator worktree or a sibling sub-worktree.

If required task context is absent, use Orca's blocking `ask/reply` flow. Do not turn the missing context into a new local planning artifact.

## 2. Execute Directly

1. Run the supplied environment setup when needed.
2. Decompose the task into small, testable increments in session state.
3. For each increment, follow RED -> GREEN -> REFACTOR.
4. Commit coherent test-and-implementation increments on the task branch.
5. Stay within the approved task. Send a blocking question to the orchestrator when ambiguity affects behavior, scope, dependencies, or acceptance criteria.

The orchestrator may answer when accumulated research already determines the result. A material plan change goes back to the user through the orchestrator.

## 3. Verify and Report

Run only the focused tests and checks relevant to the task's owned behavior and affected surface. Leave broader repository coverage to CI. Confirm the intended work is committed and the worktree contains no accidental changes.

Report completion through the active Orca Dispatch with:

- Task name and outcome
- Branch and final commit SHA
- Verification commands and results
- Files modified
- Deviations, blockers, or follow-up dependencies

Send `worker_done` exactly once using the IDs injected by Orca, then end the dispatched turn. The orchestrator owns dependency release, stacked-PR linkage, integration choices, and worker cleanup.

## Stop Conditions

Stop and ask through Orca when:

- The checkout is not the approved task sub-worktree
- The task requires an unapproved behavioral or architectural decision
- A dependency is missing or unstable
- Required verification cannot be run or repeatedly fails for an unexplained reason

Never implement in the main coordinator worktree, broaden the task silently, create sibling worktrees, or re-dispatch implementation.
