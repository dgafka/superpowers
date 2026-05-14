---
name: executing-specs
description: Use when you have an approved design spec from brainstorming and need to implement it — asks how to execute (in this session or via a subagent at sonnet 1M / opus), then either runs the work here or dispatches the executing-specs subagent
---

# Executing Specs

## Overview

Run the end-to-end TDD implementation of an approved spec. This skill runs in the parent session and chooses how the implementation happens:

1. Loads the spec and sanity-checks it
2. Confirms the working branch is sane
3. Asks the user how to execute: in this session, via subagent (sonnet 1M), via subagent (opus), or hold
4. Either executes the work here OR dispatches the executing-specs subagent
5. Relays the result back to the user (when dispatched) or wraps up directly (when run in-session)

**Announce at start:** "I'm using the executing-specs skill — first I'll sanity-check the spec and confirm execution mode."

**Input:** A design spec from brainstorming, typically at `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`. If the user didn't name a path, use the most recent spec in that directory or ask.

## The Process

### Step 1: Load and Sanity-Check the Spec

1. Read the spec file end-to-end
2. Look for blockers — missing sections, contradictions, undefined references, ambiguity that would stop execution
3. If any concern blocks execution: raise it with the user before continuing
4. If clear: continue

This is a quick check, not a deep review. The spec was reviewed at design time. The goal here is to catch obvious gaps before starting work.

### Step 2: Confirm Branch State

Before going further:

- Check `git status` and the current branch
- If on `main`/`master`, stop and ask the user whether to create a feature branch first
- Never start implementation on the default branch without explicit user consent

### Step 3: Ask Execution Mode

Use **AskUserQuestion** with these four options:

| Option | When to recommend |
|---|---|
| **Continue in this session** | Small specs, or when the user wants to stay in this context. The parent runs the TDD loop directly. |
| **Subagent — sonnet 1M** | Default for most specs. Large context window, lower cost, isolates the long TDD loop from this conversation. |
| **Subagent — opus** | Specs that need stronger reasoning (intricate refactors, novel design decisions during execution). |
| **Hold — manual changes first** | Pause so the user can make changes; they'll re-invoke when ready. |

Phrase the question so the user can choose by trade-off, not by guessing. Do not mark a default — the right answer depends on the spec.

### Step 4: Execute

Branch on the user's selection.

#### 4a. Continue in this session

The parent session runs the implementation directly, following the same internal process the subagent would:

1. Re-read the spec (already in context, but re-anchor).
2. Decompose the spec into bite-sized tasks.
3. Identify parallel-safe groups (where applicable).
4. For each task: RED → GREEN → commit (TDD discipline per `superpowers:test-driven-development`).
5. After all tasks: run `superpowers:verification-before-completion` for the full-suite check.
6. Go straight to Step 5 to report back and ask about integration.

This path keeps everything in one conversation but burns context. Use it for small specs.

#### 4b. Subagent — sonnet 1M (or opus)

Invoke the `executing-specs` agent via the Agent tool (`subagent_type: "executing-specs"`) with a self-contained prompt:

- Absolute path to the spec
- The branch the work should land on
- Any user-stated constraints surfaced in Step 1
- The instruction to follow the agent's own internal process: decompose → parallel-safe grouping → per-task TDD → final-suite verification via verification-before-completion → report back

For sonnet 1M, use the agent's default model (defined in `agents/executing-specs.md` frontmatter). For opus, pass `model: "opus"` to the Agent tool to override.

The subagent has its own tool access and is responsible for the entire implementation. **Do not** decompose tasks or write code in the parent session when running via subagent — that defeats the purpose of the dispatch.

#### 4c. Hold

Stop here. The user will re-invoke when ready.

### Step 5: Relay the Result

When the work finishes (subagent returns, or in-session implementation completes):

- Summarize what shipped (one or two sentences)
- Show the branch name and final commit SHA(s)
- Surface any blockers, deviations, or open questions
- Ask the user how they want to integrate the work (merge, push + PR, keep the branch, discard) — this skill never decides integration
- Offer the **recognize-and-learn** skill as an optional follow-up to capture friction points from this implementation cycle

If the subagent reports it could not finish (blocker, missing context, escalation), bring that back to the user with the subagent's own framing. Do not silently retry.

## When to Stop and Ask for Help

**STOP before execution when:**
- The spec is missing information needed to proceed
- The branch state is wrong and the user has not consented to the chosen branch
- An instruction in the spec is genuinely ambiguous

**STOP after dispatch when:**
- The subagent escalates a blocker — relay it, don't paper over

**Ask for clarification rather than guessing.**

## Remember

- Ask the execution-mode question (Step 3) every time. Do not pick a default for the user.
- When running in-session (4a), follow the same canonical TDD process the subagent would.
- When dispatching (4b), the parent does not write code or decompose tasks — the subagent owns that.
- Don't start work on main/master without explicit user consent.
- Relay subagent escalations faithfully; never silently retry.
- After the work finishes, offer **recognize-and-learn** as a retrospective option.

## Integration

**Called by:**
- **superpowers:brainstorming** — terminal handoff after the user approves the spec

**Dispatches to (when user selects subagent):**
- **executing-specs agent** (sonnet 1M by default; opus on user choice) — implements the spec end-to-end

**Follow-up (optional):**
- **superpowers:recognize-and-learn** — post-implementation retrospective on friction points

**Required workflow skills:**
- **superpowers:test-driven-development** — applied per task during execution (in-session or in subagent)
- **superpowers:verification-before-completion** — applied at end of implementation for full-suite verification
