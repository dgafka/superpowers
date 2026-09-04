---
name: orchestrator-subworktree
description: Use when implementing approved work directly inside its dedicated Orca sub-worktree
---

# Orchestrator Sub-worktree

## Overview

Implement the approved work directly in the current sub-worktree and Codex session. Orca represents this assignment as a task; use sub-worktree in user-facing updates. The task prompt is the plan: it carries the goal, boundaries, dependencies, guidance, acceptance criteria, and environment commands.

Execute the approved assignment directly in this worker session.

**REQUIRED SUB-SKILL:** Use superpowers:test-driven-development for every behavior change.

**REQUIRED SUB-SKILL:** Use superpowers:create-pull-request after verification to publish the implementation PR and start its approved CI observation sub-session.

**REQUIRED SUB-SKILL:** Use orchestration for Orca task questions and lifecycle reporting.

## 1. Anchor to the Sub-worktree

Read the injected Orca task prompt end-to-end. Identify:

- Sub-worktree name, goal, and observable outcome
- Run-wide guidance and task-specific additions
- Owned scope and explicit exclusions
- Dependency branch and expected stack position
- Acceptance criteria and verification commands

Verify the current checkout is the task's dedicated sub-worktree, its name matches the Orca task where tooling permits, and the branch is not the repository's default branch. If placement differs, report the error and await the coordinator's corrected placement before editing.

If required task context is absent, use Orca's blocking `ask/reply` flow. Keep the resolved context in the task prompt and conversation.

## 2. Execute Directly

1. Run the supplied environment setup when needed.
2. Decompose the task into small, testable increments in session state.
3. For each increment, follow RED -> GREEN -> REFACTOR.
4. Commit coherent test-and-implementation increments on the task branch.
5. Stay within the approved task. Send a blocking question to the orchestrator when ambiguity affects behavior, scope, dependencies, or acceptance criteria.

The orchestrator may answer when accumulated research already determines the result. A material plan change goes back to the user through the orchestrator.

## 3. Verify, Publish, and Report

Run only the focused tests and checks relevant to the task's owned behavior and affected surface. Leave broader repository coverage to CI. Confirm that the committed changes and remaining worktree state match the approved scope.

Invoke `superpowers:create-pull-request` in its orchestrated implementation mode. Pass the approved repository, PR base (the prerequisite branch for dependent work), publication authorization, named CI observer launch, and original worker/Dispatch route. Create or reuse a ready-for-review PR, then send its URL to the main coordinator through Orca immediately.

For automatic observation, trigger the approved `observe-<topic>` sub-session in this implementation worktree using the observation entry point in `superpowers:create-pull-request`. Use mode `ci` by default, or `full` when explicitly approved. An explicit manual override skips observation and its launch receipt. Ask the coordinator to dispatch it in the same Run when worker-side dispatch is unavailable; wait for the launch receipt before reporting successful completion. Reuse an existing observer. Report missing launch approval or a failed automatic launch as a blocker.

Report completion through the active Orca Dispatch with:

- Sub-worktree name and outcome
- PR URL, target branch, and final commit SHA
- Observer name, selected mode, launch receipt, and findings route (or the explicit manual override)
- Verification commands and results
- Files modified
- Deviations, blockers, or follow-up dependencies

Send `worker_done` exactly once using the IDs injected by Orca, then end the dispatched turn. The orchestrator owns dependency release, stacked-PR linkage, integration choices, and worker cleanup. It retains the original worker terminal for CI fixes during the approved observation cycle; after settlement, a fix arrives as a fresh Dispatch in that exact terminal. Use the lifecycle IDs from each fresh Dispatch.

## Stop Conditions

Stop and ask through Orca when:

- The checkout is not the approved implementation sub-worktree
- The task requires an unapproved behavioral or architectural decision
- A dependency is missing or unstable
- Required verification cannot be run or repeatedly fails for an unexplained reason

Resume implementation in the approved sub-worktree after the coordinator resolves the blocking condition.
