---
name: orchestrator-agent
description: Use when the user explicitly requests Orca-coordinated implementation across one or more Codex task sub-worktrees without a research phase
argument-hint: "[objective, task DAG, and optional run-wide guidance]"
---

# Orchestrator Agent

## Overview

Coordinate an implementation objective from the main worktree without editing implementation code there. Accept a clear objective, approved design, or existing task DAG. When needed, decompose a clear request into implementation tasks in session state; do not start a research phase or create planning documents.

If missing knowledge requires investigation before tasks can be defined safely, ask the user to invoke `orchestration-research`. Keep this skill focused on implementation orchestration.

**REQUIRED SUB-SKILL:** Use orchestration for the live, version-matched Orca task, Dispatch, dependency, ask/reply, and worker lifecycle commands.

**REQUIRED SUB-SKILL:** Use orca-cli for Orca worktree and terminal operations not covered by orchestration.

## Task Context

Treat guidance supplied with the invocation as run-wide context. Preserve it across every task. Add task-specific guidance only where it narrows one assignment; it never silently overrides run-wide guidance or an approved user decision.

Give every implementation unit a short stable `implement-<topic>` name, such as `implement-payment-reschedule`. Reuse the exact name for the Orca task and its implementation sub-worktree. Use it in status and waiting messages; keep it out of PR titles.

Build the implementation DAG in Orca. Make ownership, dependencies, acceptance criteria, and verification commands explicit. Start all approved, dependency-ready, conflict-free tasks concurrently.

## Approval and Dispatch

Before starting each implementation sub-worktree, summarize:

- Task name, goal, and expected outcome
- Approved decisions and owned subsystem or file area
- Dependencies and Git base
- Acceptance and focused verification criteria
- Execution discipline: `orchestrator-subworktree-task` plus standalone TDD
- Run-wide and task-specific guidance
- Intended GitHub PR-stack position

Ask the user to confirm the task. One message may present a concurrent wave, but every task must be individually identifiable and explicitly approved. Dispatch only approved tasks.

Create each implementation as a separate Orca child sub-worktree from the main coordinator worktree. Independent tasks use sibling sub-worktrees based on the agreed trunk. A dependent task uses its prerequisite's stable branch as its Git base. When a task depends on multiple sibling branches, ask how to linearize or integrate them before choosing a base.

Every implementation task prompt must include these instructions:

- Invoke `orchestrator-subworktree-task` for the worker workflow.
- **REQUIRED SUB-SKILL:** Use superpowers:test-driven-development for every behavior change.
- Follow RED -> GREEN -> REFACTOR for each increment: write one focused test, watch it fail for the expected reason, write the minimum implementation, watch it pass, then refactor while green.
- Run only the focused inner-loop and task-relevant tests; broader repository coverage belongs to CI.

The coordinator remains in the main worktree.

## Questions and Decisions

Workers ask the coordinator through Orca's blocking `ask/reply` flow. Answer when approved context determines one unambiguous result. Ask the user when the answer changes behavior, scope, dependencies, acceptance criteria, or stack structure. Keep unrelated ready tasks moving while a decision is blocked.

## Requested Review Tasks

Create `review-<topic>` only when the user explicitly requests a separate review
of the matching completed `implement-<topic>` task. Make the review task depend
on that implementation task.

Run the review in a separate Codex session against the implementation task's
existing sub-worktree and stable commit. Do not create a review worktree. Its
task prompt must invoke `review-changes` in Orchestrated Review Mode and include:

- The matching implementation task, branch, base, and reviewed commit SHA
- The approved objective, decisions, scope, and acceptance criteria
- A local-diff target or a specific pull request
- Review focus, with the standard review checks as the default
- Whether inline PR comments are explicitly authorized

Local reviews and report-only PR reviews return findings through Orca without
external comments. A PR review may post inline comments only when the user's
request explicitly authorized them. The reviewer never fixes findings.

Present the findings to the user and route approved fixes to the exact
`implement-<topic>` worker in its existing sub-worktree. After fixes, reuse the
exact `review-<topic>` session to verify the same scope and commit delta. Keep
the implementation worker available through this review-and-fix cycle, and keep
unrelated dependency-ready tasks moving while review or fixes are in progress.

## Pull Requests

Orca dependencies are the execution source of truth. GitHub stacks express review and merge order.

For each completed dependency chain:

1. Verify every branch is pushed to the same repository and the history is linear.
2. Order branches bottom-to-top and use GitHub's native `gh stack link` workflow to create or reuse draft PRs with correct bases.
3. Keep PR titles human-readable and internal task names out of them.
4. Ask for an observation mode: manual, full, or CI-only. For either automatic mode, create one read-only `observe-<specific-topic>` Orca task per PR. Full mode routes CI and comment findings to the implementation worker; CI-only mode routes CI failures and never processes comments.
5. Treat independent dependency chains as separate stacks.

Include remote publication in the task approval summary. If it was not approved there, ask before creating remote PR state. Inspect current `gh stack` help or official documentation when the installed public-preview surface differs.

## Coordination Discipline

- Use Orca dependencies and `task-list --ready` rather than mental scheduling.
- Report exact task names and whether each is running, ready, blocked, or awaited.
- Treat timeouts as checkpoints while workers remain live.
- After accepted completion, reuse the exact worker for an immediate follow-up or release it through Orca.
- Reuse the exact reviewer for re-review after approved fixes.
- Never merge stacks, delete worktrees, or discard branches without user authorization.
