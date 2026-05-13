---
name: executing-specs
description: Use when you have an approved design spec from brainstorming and need to implement it — confirms readiness with the user, then dispatches the executing-specs subagent for end-to-end TDD implementation
---

# Executing Specs

## Overview

Run the end-to-end TDD implementation of an approved spec. This skill runs in the parent session as a thin orchestration layer:

1. Loads the spec and sanity-checks it
2. Confirms the working branch is sane
3. Asks the user a single readiness question — "ready to proceed, or do manual changes need to happen first?"
4. Dispatches the dedicated `executing-specs` subagent (sonnet, 1M context) to do the implementation
5. Relays the result back to the user

**Do not ask about model or execution mode.** The dispatch target is fixed: the `executing-specs` subagent at sonnet 1M. That keeps the parent context clean, isolates the long TDD loop, and uses the cheaper/larger-context model the agent was designed for. If the user wants a different setup, they will say so without being prompted.

**Announce at start:** "I'm using the executing-specs skill — first I'll sanity-check the spec and confirm we're ready."

**Input:** A design spec from brainstorming, typically at `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`. If the user didn't name a path, use the most recent spec in that directory or ask.

## The Process

### Step 1: Load and Sanity-Check the Spec

1. Read the spec file end-to-end
2. Look for blockers — missing sections, contradictions, undefined references, ambiguity that would stop a fresh agent from proceeding
3. If any concern blocks execution: raise it with the user before continuing
4. If clear: continue

This is a quick check, not a deep review. The spec was reviewed at design time. The goal here is to catch obvious gaps before paying the cost of spinning up the subagent.

### Step 2: Confirm Branch State

Before going further:

- Check `git status` and the current branch
- If on `main`/`master`, stop and ask the user whether to create a feature branch first
- Never start implementation on the default branch without explicit user consent

### Step 3: Confirm Readiness

Use **AskUserQuestion** to ask one question:

> "Spec looks clean and the branch is set. We're prepared for implementation. Proceed now, or do any manual changes need to happen first?"

Options:
- *Proceed now (Recommended)* — dispatch the executing-specs subagent immediately
- *Hold — manual changes first* — pause so the user can make changes; ask them to re-invoke when ready

Do **not** ask about model or execution mode here. The dispatch target is the `executing-specs` subagent at its default model (sonnet 1M).

### Step 4: Dispatch the Subagent

If the user chose **Proceed now**, invoke the `executing-specs` agent (Agent tool, `subagent_type: "executing-specs"`) with a self-contained prompt:

- Absolute path to the spec
- The branch the work should land on
- Any user-stated constraints surfaced in Step 1
- The instruction to follow the agent's own internal process: decompose → parallel-safe grouping → per-task TDD → final test run → report back

The subagent runs at its default model (`model: sonnet` from agent frontmatter, 1M context). The subagent has its own tool access and is responsible for the entire implementation. **Do not** decompose tasks or write code in the parent session — that defeats the purpose of the dispatch.

If the user chose **Hold**, stop here and let them work. They will re-invoke when ready.

### Step 5: Relay the Result

When the subagent returns:

- Summarize what shipped (one or two sentences)
- Show the branch name and final commit SHA
- Surface any blockers, deviations, or open questions
- Ask the user how they want to integrate the work (merge, push + PR, keep the branch, discard) — this skill never decides integration
- Offer the **recognize-and-learn** skill as an optional follow-up to capture friction points from this implementation cycle

If the subagent reports it could not finish (blocker, missing context, escalation), bring that back to the user with the subagent's own framing. Do not silently retry.

## When to Stop and Ask for Help

**STOP before dispatch when:**
- The spec is missing information needed to proceed
- The branch state is wrong and the user has not consented to the chosen branch
- An instruction in the spec is genuinely ambiguous

**STOP after dispatch when:**
- The subagent escalates a blocker — relay it, don't paper over

**Ask for clarification rather than guessing.**

## Remember

- Ask exactly one readiness question; do not prompt for model or mode
- This skill is a thin orchestration layer — the heavy lifting happens in the subagent. Don't decompose or write code in the parent session.
- Don't start work on main/master without explicit user consent
- Relay subagent escalations faithfully; never silently retry
- After the subagent returns, offer **recognize-and-learn** as a retrospective option

## Integration

**Called by:**
- **superpowers:brainstorming** — terminal handoff after the user approves the spec

**Dispatches to:**
- **executing-specs agent** (sonnet, 1M context) — implements the spec end-to-end

**Follow-up (optional):**
- **superpowers:recognize-and-learn** — post-implementation retrospective on friction points

**Required workflow skills (applied inside the subagent):**
- **superpowers:test-driven-development** — applied per task during execution
- **superpowers:verification-before-completion** — applied before marking each task done
