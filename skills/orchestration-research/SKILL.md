---
name: orchestration-research
description: Use when the user explicitly requests concurrent Codex research before Orca-coordinated implementation
disable-model-invocation: true
argument-hint: "[global research or orchestration guidance]"
---

# Orchestration Research

## Overview

Act as the durable research session. Keep the main worktree as the knowledge surface, delegate bounded read-only research, connect findings, and turn the result into an implementation objective and task DAG.

This session may create genuine research data when useful. It does not edit implementation code or absorb worker fixes.

**REQUIRED SUB-SKILL:** Use orchestration for the live, version-matched Orca research tasks, Dispatches, dependencies, and worker lifecycle.

**REQUIRED SUB-SKILL:** Use orchestrator-agent after research establishes an implementation direction.

## Guidance

Treat guidance supplied with the invocation as run-wide context. Preserve it in every research task and pass it unchanged to `orchestrator-agent`. Add task-specific research guidance only where it narrows one question.

Name every research task `<action>-<specific-topic>`, such as `research-payment-flow`. Reuse the exact name for its Orca task and all progress updates.

## Research Loop

1. Bind one Orca Run to the user's objective.
2. Turn open questions into bounded research tasks with explicit outputs and dependencies.
3. Start every ready independent task concurrently in a separate Codex session on the main worktree.
4. Keep research workers read-only. They return findings through Orca and do not create implementation branches, private worktrees, or standalone reports.
5. Synthesize evidence, decisions, risks, dependencies, and remaining unknowns as results arrive. Do not wait for unrelated research before using a finding.
6. Ask the user only when research exposes a decision that materially changes the intended direction.

Research may continue while later work proceeds when remaining questions do not block it.

## Implementation Handoff

When the implementation direction is clear, invoke `orchestrator-agent` with:

- The objective and expected outcome
- The synthesized implementation DAG
- Evidence and approved decisions relevant to each task
- Dependencies, ownership boundaries, and acceptance criteria
- Run-wide guidance and any task-specific additions
- Remaining non-blocking research and known risks

`orchestrator-agent` owns implementation decomposition refinements, user approval gates, sub-worktrees, worker questions, concurrent execution, stacked PRs, and observation. Do not repeat those procedures here.
