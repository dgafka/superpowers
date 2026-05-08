---
name: executing-specs
description: Use when you have an approved design spec from brainstorming and need to implement it — asks how to execute (main session vs executing-specs subagent) and at what model, then runs end-to-end TDD execution
---

# Executing Specs

## Overview

Run the end-to-end TDD implementation of an approved spec. This skill runs in the parent session and asks the user up front **how** the work should be executed:

- **Execution mode** — main window (this session) or sub-agent (the dedicated `executing-specs` subagent)
- **Execution model** — keep the current model or use sonnet with the 1M-context window

Branch on the answers: dispatch to the subagent (Agent tool) for the sub-agent path, or run the agent's process directly in this session for the main-window path.

**Why offer a choice:** the historical default — dispatch to a sonnet 1M subagent — is great for keeping opus context clean and reducing cost on long, mechanical TDD loops. But sometimes you want the spec executed in the main window (small change, want to watch every step, want full conversation continuity) or with a specific model (already on sonnet, or want to keep opus for tricky logic). Asking lets the user pick what fits the task.

**Announce at start:** "I'm using the executing-specs skill — first I'll confirm how you want this executed."

**Input:** A design spec from brainstorming, typically at `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`. If the user didn't name a path, use the most recent spec in that directory or ask.

## The Process

### Step 1: Load and Sanity-Check the Spec

1. Read the spec file end-to-end
2. Look for blockers — missing sections, contradictions, undefined references, ambiguity that would stop a fresh agent from proceeding
3. If any concern blocks execution: raise it with the user before dispatching
4. If clear: continue

This is a quick check, not a deep review. The spec was reviewed at design time. The goal here is to catch obvious gaps before paying the cost of spinning up the subagent.

### Step 2: Confirm Branch State

Before going further:

- Check `git status` and the current branch
- If on `main`/`master`, stop and ask the user whether to create a feature branch first
- Never start implementation on the default branch without explicit user consent

### Step 3: Ask Execution Preferences

Use **AskUserQuestion** to ask both of these in a single call:

**Question 1 — Execution mode:**
- *Sub-agent (Recommended)* — dispatch to the `executing-specs` subagent. Keeps the parent context clean, isolates the long TDD loop, can run on a cheaper/larger-context model.
- *Main window* — run the agent's process directly in this session. Use when you want to watch every step, the change is small, or conversation continuity matters.

**Question 2 — Execution model:**
- *Sonnet 1M (Recommended)* — use Claude Sonnet with the 1M-context window. Default for the subagent path.
- *Keep current model* — whatever this session is running.

Resolving the matrix:

| Mode      | Model         | Action                                                                           |
|-----------|---------------|----------------------------------------------------------------------------------|
| Sub-agent | Sonnet 1M     | Dispatch agent (default `model: sonnet` from agent frontmatter)                  |
| Sub-agent | Keep current  | Dispatch agent with `model` override matching the parent session                 |
| Main      | Keep current  | Execute inline (Step 4-Main); the parent session's model runs the work          |
| Main      | Sonnet 1M     | The parent session can't switch its own model. Tell the user and offer two options: dispatch to the subagent at sonnet (recommended), or proceed in main window with the current model. Re-ask if needed. |

### Step 4-Sub: Dispatch the Subagent

If the user chose **sub-agent** mode, invoke the `executing-specs` agent (Agent tool, `subagent_type: "executing-specs"`) with a self-contained prompt:

- Absolute path to the spec
- The branch the work should land on
- Any user-stated constraints surfaced in Step 1
- The instruction to follow the agent's own internal process: decompose → parallel-safe grouping → per-task TDD → final test run → report back

Pass the resolved `model` parameter on the Agent call (sonnet for "Sonnet 1M", or the parent's current model for "Keep current"). The subagent has its own tool access and is responsible for the entire implementation. **Do not** decompose tasks or write code in the parent session — that defeats the purpose of the dispatch.

### Step 4-Main: Execute Inline

If the user chose **main window** mode, run the same process the subagent would run, in this session:

1. **Critique the spec** — read it end-to-end as if you'd never seen it. Look for gaps, ambiguity, contradictions, missing edge cases, hidden assumptions. Stop and ask the user if any concern blocks implementation.
2. **Decompose** — use TodoWrite to build a checklist of bite-sized tasks. Each task touches a focused unit, produces a working testable increment, and has a clear acceptance signal. Group by parallel-safety (disjoint files + no sequential dep = parallel; otherwise sequential).
3. **Execute per task (TDD)** — for each task: mark `in_progress` → **RED** (failing test, run, confirm fails for the right reason) → **GREEN** (minimal code to pass, run, confirm) → **REFACTOR** only if there's real cleanup → commit (test + impl together) → mark `completed`. Batch parallel-safe tool calls into a single turn. **Never write implementation before its test exists.**
4. **Verify** — run the full project test suite. Don't report success on a red suite. Confirm clean `git status`.
5. **Report** — proceed to Step 5.

Apply the `superpowers:test-driven-development` skill for the discipline and `superpowers:verification-before-completion` before marking each task done.

### Step 5: Relay the Result

When the work returns (subagent reply, or your own completion in main-window mode):

- Summarize what shipped (one or two sentences)
- Show the branch name and final commit SHA
- Surface any blockers, deviations, or open questions
- Ask the user how they want to integrate the work (merge, push + PR, keep the branch, discard) — this skill never decides integration

If the subagent reports it could not finish (blocker, missing context, escalation), bring that back to the user with the subagent's own framing. Do not silently retry.

## When to Stop and Ask for Help

**STOP before executing (either path) when:**
- The spec is missing information needed to proceed
- The branch state is wrong and the user has not consented to the chosen branch
- An instruction in the spec is genuinely ambiguous
- The execution mode + model combination is incoherent (e.g., main window + Sonnet 1M) and the user hasn't chosen a fallback

**STOP after dispatch (sub-agent mode) when:**
- The subagent escalates a blocker — relay it, don't paper over

**STOP during inline execution (main-window mode) when:**
- A test fails for a reason you can't explain after a genuine investigation
- Verification fails repeatedly with the same root cause
- You'd need to make an architectural decision the spec doesn't cover

**Ask for clarification rather than guessing.**

## Remember

- Always ask the two preference questions (mode + model) before executing
- In sub-agent mode this skill is a thin orchestration layer — the heavy lifting happens in the subagent. Don't decompose or write code in the parent session.
- In main-window mode this skill *is* the executor — apply TDD discipline per task as the agent would
- Don't start work on main/master without explicit user consent
- Relay subagent escalations faithfully; never silently retry

## Integration

**Called by:**
- **superpowers:brainstorming** — terminal handoff after the user approves the spec

**Dispatches to (sub-agent mode):**
- **executing-specs agent** (sonnet, 1M context by default; model overridable on the Agent call) — implements the spec end-to-end

**Required workflow skills (used in either mode):**
- **superpowers:test-driven-development** — applied per task during execution
- **superpowers:verification-before-completion** — applied before marking each task done
