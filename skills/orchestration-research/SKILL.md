---
name: orchestration-research
description: Use when the user explicitly requests an Orca-coordinated research and implementation workflow with separate Codex sessions and task sub-worktrees
disable-model-invocation: true
argument-hint: "[global research or orchestration guidance]"
---

# Orchestration Research

## Overview

Act as the durable research orchestrator. Keep the main worktree as the knowledge and coordination surface, delegate bounded research, connect findings into an implementation DAG, and supervise approved Codex implementation sessions in separate sub-worktrees.

This session may create genuine research data or planning artifacts when useful. It does not edit implementation code, absorb worker fixes, or run implementation in the main worktree.

**REQUIRED SUB-SKILL:** Use orchestration for the live, version-matched Orca task, Dispatch, dependency, ask/reply, and worker lifecycle commands.

**REQUIRED SUB-SKILL:** Use orca-cli for Orca worktree and terminal operations not covered by orchestration.

## Guidance Layers

Treat guidance supplied with the invocation as run-wide context. Preserve it across every task. Add optional task-specific guidance only where it narrows or enriches one assignment; it never silently overrides run-wide guidance or an approved user decision.

Every delegated unit receives a short stable name:

`<action>-<specific-topic>`

Examples: `research-payment-flow`, `implement-payment-reschedule`.

Reuse the exact name for the Orca task and, for implementation, its sub-worktree. Use it in all status and waiting messages. Keep internal names out of PR titles.

## Research Loop

1. Bind one Orca Run to the user's objective.
2. Turn open questions into bounded research tasks with explicit outputs and dependencies.
3. Start every ready independent research task concurrently in a separate Codex session on the main worktree. Research workers are read-only and return findings through Orca; they do not create implementation branches or reports in private worktrees.
4. Wait for `worker_done`, questions, or escalations. Synthesize findings as they arrive instead of waiting for unrelated research.
5. Connect evidence, decisions, risks, and remaining unknowns into an implementation DAG held in conversation and Orca task state.

Research may continue while implementation proceeds when the remaining questions do not block an approved task.

## Implementation Gate

Before starting each implementation sub-worktree, summarize:

- Task name, goal, and expected outcome
- Relevant evidence and approved decisions
- Owned subsystem or file area
- Dependencies and base branch
- Acceptance and verification criteria
- Run-wide and task-specific guidance
- Intended position in a GitHub PR stack

Ask the user to confirm the task. A single message may present a concurrent wave, but every task must be individually identifiable and explicitly approved. Dispatch only approved tasks.

Create every implementation as a separate Orca child sub-worktree from the main research worktree. Independent tasks use sibling sub-worktrees based on the agreed trunk. A dependent task uses its prerequisite's stable branch as its Git base. Start all approved, dependency-ready, conflict-free tasks concurrently and invoke `executing-tasks` in each Codex session.

The main research session remains in the main worktree throughout.

## Questions and Decisions

Implementation workers ask this session through Orca's blocking `ask/reply` flow. Answer from accumulated research when the approved plan determines one unambiguous result. Ask the user when an answer changes behavior, scope, dependencies, acceptance criteria, or stack structure. Keep unrelated ready tasks moving while a decision is blocked.

## Stacked Pull Requests

Orca task dependencies are the execution source of truth. GitHub stacks express review and merge order.

For each completed dependency chain:

1. Verify every branch is pushed to the same repository and the history is linear.
2. Order branches bottom-to-top from trunk toward dependents.
3. Use GitHub's native `gh stack link` workflow to create or reuse draft PRs with the correct bases.
4. Keep human-readable PR titles. Put research context and review guidance in PR bodies without exposing internal task names as title prefixes.
5. After PR creation, ask for an observation mode: manual, full, or CI-only. Full mode routes CI and comment findings back to the PR's implementation worker; CI-only mode routes CI failures and never processes comments. For either automatic mode, create one read-only `observe-<specific-topic>` Orca task per PR. Route decision-required findings from full observation through this research session.
6. Treat independent chains as separate stacks.

Include stack publication in the approved task summary. If it was not approved there, ask before creating remote PR state. GitHub stacked PRs are a public-preview capability; inspect current `gh stack` help or official documentation instead of guessing when the installed surface differs.

## Coordination Discipline

- Use Orca task dependencies and `task-list --ready` rather than mental scheduling.
- Report progress with exact task names: what is running, ready, blocked, or awaited.
- A timeout is a checkpoint, not failure. Continue rolling waits while the worker remains live.
- After accepted completion, either reuse the exact worker for an immediate follow-up or release it through Orca.
- Never merge stacks, delete worktrees, or discard branches without the user's authorization.
