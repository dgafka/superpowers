---
name: orchestration-research
description: Use when the user explicitly requests concurrent read-only research sub-sessions in an existing worktree before Orca-coordinated implementation
disable-model-invocation: true
argument-hint: "[run-wide research or orchestration guidance]"
---

# Orchestration Research

## Overview

Act as the durable research session. Keep the main worktree as the knowledge surface, delegate bounded read-only research, connect findings, and turn the result into an implementation objective and task DAG.

This session may create research data when useful. Implementation workers own code changes and fixes.

**REQUIRED SUB-SKILL:** Use orchestration for the live, version-matched Orca research tasks, Dispatches, dependencies, and worker lifecycle.

**REQUIRED SUB-SKILL:** Use orchestrator-agent after research establishes an implementation direction.

## Guidance

Treat guidance supplied with the invocation as run-wide context. Preserve it in every research task and pass it unchanged to `orchestrator-agent`. Add task-specific research guidance only where it narrows one question.

Name every research sub-session `<action>-<specific-topic>`, such as `research-payment-flow`. Reuse the exact name for its underlying Orca task and all progress updates. A sub-session is a separate Codex terminal within an existing worktree.

## Research Loop

1. Bind one Orca Run to the user's objective.
2. Turn open questions into bounded research tasks with explicit outputs and dependencies.
3. Before launching each research sub-session, show the shared launch confirmation table from `../orchestrator-agent/launch-confirmation.md`, resolved from this skill directory, and obtain explicit approval. Identify the main worktree as its execution location, research question, dependencies, and expected evidence. Use the table's defined rows. A wave may be approved together when each sub-session has its own table. Start every approved, ready independent sub-session concurrently in the main worktree; track it as an Orca task.
4. Keep research workers read-only. They investigate in the existing worktree and return findings through Orca.
5. Synthesize evidence, decisions, risks, dependencies, and remaining unknowns as results arrive. Use each finding as soon as its prerequisites are established.
6. Beyond launch confirmations, ask the user only when research exposes a decision that materially changes the intended direction.

Research may continue while later work proceeds when remaining questions do not block it.

## Implementation Handoff

When the implementation direction is clear, invoke `orchestrator-agent` with:

- The objective and expected outcome
- The synthesized implementation DAG
- Evidence and approved decisions relevant to each task
- Dependencies, ownership boundaries, and acceptance criteria
- Run-wide guidance and any task-specific additions
- Remaining non-blocking research and known risks

`orchestrator-agent` owns implementation decomposition refinements, user approval gates, sub-worktrees, worker questions, concurrent execution, stacked PRs, and observation. Hand control of those procedures to that skill.
