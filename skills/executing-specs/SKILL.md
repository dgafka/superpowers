---
name: executing-specs
description: Use when you have an approved design spec from brainstorming and need to implement it - hands the spec off to the executing-specs subagent (sonnet, 1M context) for end-to-end TDD execution
---

# Executing Specs

## Overview

Hand an approved spec off to the dedicated `executing-specs` subagent (sonnet, 1M context) for end-to-end implementation. This skill runs in the parent session (typically opus) and does **not** do the implementation itself — it loads the spec, performs a quick sanity check, then dispatches.

**Why a subagent:** brainstorming and spec authoring benefit from a stronger reasoning model (opus). The TDD execution loop — decompose, write failing test, write minimal code, commit — is mechanical and ideal for sonnet with a 1M context window. Splitting the work this way keeps opus context clean and reduces cost.

**Announce at start:** "I'm using the executing-specs skill to hand this spec off to the executing-specs subagent."

**Input:** A design spec from brainstorming, typically at `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`. If the user didn't name a path, use the most recent spec in that directory or ask.

## The Process

### Step 1: Load and Sanity-Check the Spec

1. Read the spec file end-to-end
2. Look for blockers — missing sections, contradictions, undefined references, ambiguity that would stop a fresh agent from proceeding
3. If any concern blocks execution: raise it with the user before dispatching
4. If clear: continue

This is a quick check, not a deep review. The spec was reviewed at design time. The goal here is to catch obvious gaps before paying the cost of spinning up the subagent.

### Step 2: Confirm Branch State

Before dispatching:

- Check `git status` and the current branch
- If on `main`/`master`, stop and ask the user whether to create a feature branch first
- Never start implementation on the default branch without explicit user consent

### Step 3: Dispatch the Subagent

Invoke the `executing-specs` agent (Agent tool, `subagent_type: "executing-specs"`) with a self-contained prompt:

- Absolute path to the spec
- The branch the work should land on
- Any user-stated constraints surfaced in Step 1
- The instruction to follow the agent's own internal process: decompose → parallel-safe grouping → per-task TDD → final test run → report back

The subagent runs sonnet with a 1M context window and has its own tool access. It is responsible for the entire implementation. **Do not** decompose tasks or write code in the parent session — that defeats the purpose of the dispatch.

### Step 4: Relay the Result

When the subagent returns:

- Summarize what shipped (one or two sentences)
- Show the branch name and final commit SHA
- Surface any blockers, deviations, or open questions the subagent reported
- Ask the user how they want to integrate the work (merge, push + PR, keep the branch, discard) — the subagent doesn't decide this

If the subagent reports it could not finish (blocker, missing context, escalation), bring that back to the user with the subagent's own framing. Do not silently retry.

## When to Stop and Ask for Help

**STOP before dispatching when:**
- The spec is missing information needed to proceed
- The branch state is wrong and the user has not consented to the chosen branch
- An instruction in the spec is genuinely ambiguous

**STOP after dispatch when:**
- The subagent escalates a blocker — relay it, don't paper over

**Ask for clarification rather than guessing.**

## Remember

- This skill is a thin orchestration layer — the heavy lifting happens in the subagent
- Don't decompose tasks, write tests, or write implementation in the parent session
- Don't start work on main/master without explicit user consent
- Relay subagent escalations faithfully

## Integration

**Called by:**
- **superpowers:brainstorming** — terminal handoff after the user approves the spec

**Dispatches to:**
- **executing-specs agent** (sonnet, 1M context) — implements the spec end-to-end

**Required workflow skills (used inside the subagent):**
- **superpowers:test-driven-development** — applied per task during execution
