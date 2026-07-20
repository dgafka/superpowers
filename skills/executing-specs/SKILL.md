---
name: executing-specs
description: Use when you have an approved design spec from brainstorming and need to implement it — asks how to execute (in this session or via a subagent at sonnet 5), with an optional custom-instructions follow-up, then either runs the work here or dispatches the executing-specs subagent
---

# Executing Specs

## Overview

Run the end-to-end TDD implementation of an approved spec. This skill runs in the parent session and chooses how the implementation happens:

1. Loads the spec and sanity-checks it
2. Confirms the working branch is sane
3. Asks the user how to execute: in this session or via subagent (sonnet 5), then optionally takes custom instructions on approach
4. Either executes the work here OR dispatches the executing-specs subagent
5. Relays the result back to the user (when dispatched) or wraps up directly (when run in-session)

**Announce at start:** "I'm using the executing-specs skill — first I'll sanity-check the spec and confirm execution mode."

**Input:** A design spec from brainstorming, typically at `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`. If the user didn't name a path, use the most recent spec in that directory or ask. Some specs are marked ephemeral (generated for direct execution without a user review pass) — see Step 1 and Step 5 for how those are handled differently.

## The Process

### Step 1: Load and Sanity-Check the Spec

1. Read the spec file end-to-end
2. Look for blockers — missing sections, contradictions, undefined references, ambiguity that would stop execution
3. If any concern blocks execution: raise it with the user before continuing
4. Check whether the spec carries the ephemeral marker (`> **Ephemeral spec** — ...` near the top). If present, remember this for Step 5 — the spec was generated for direct execution without a user review pass, and must be deleted after the work is relayed.
5. If clear: continue

This is a quick check, not a deep review. For a reviewed spec, the design was already vetted at design time. For an ephemeral spec (no review pass happened), give the read slightly more scrutiny before continuing — this is the first check anyone has given it.

### Step 2: Confirm Branch State

Before going further:

- Check `git status` and the current branch
- If on `main`/`master`, stop and ask the user whether to create a feature branch first
- Never start implementation on the default branch without explicit user consent
- Also detect whether the current checkout is a linked worktree: the checkout is linked when `git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`. If linked, capture the absolute worktree root (`git rev-parse --show-toplevel`) — it's needed for Step 4b's subagent dispatch prompt. If they match (the main checkout), there is no worktree scope to pass along.

### Step 3: Ask Execution Mode

Use **AskUserQuestion** with these two options:

| Option | When to recommend |
|---|---|
| **Continue in this session** | Small specs, or when the user wants to stay in this context. The parent runs the TDD loop directly. |
| **Subagent — sonnet 5** | Default for most specs. Isolates the long TDD loop from this conversation, at lower cost to the parent's context. |

Phrase the question so the user can choose by trade-off, not by guessing. Do not mark a default — the right answer depends on the spec.

After the user picks one of the two options, ask a follow-up question (free text, optional):

> "Any custom instructions for how to approach this execution? (optional — leave blank for standard auto-decomposition)"

- **Blank** — proceed exactly as normal: standard spec re-read → decompose → parallel-safe grouping → per-task TDD → final verification.
- **Non-blank** — fold the instructions in as an additional constraint layered on top of the spec, before decomposition. See Step 4 for how each execution path applies this.

### Step 4: Execute

Branch on the user's selection.

#### 4a. Continue in this session

The parent session runs the implementation directly, following the same internal process the subagent would:

1. If the spec's `## Environment & Test Execution` section lists setup commands and the environment isn't already up, run them now — before doing anything else.
2. Re-read the spec (already in context, but re-anchor).
3. If the user gave custom instructions in Step 3's follow-up, keep them in view as an extra constraint alongside the spec.
4. Decompose the spec into bite-sized tasks.
5. Identify parallel-safe groups (where applicable).
6. For each task: RED → GREEN → commit (TDD discipline per `superpowers:test-driven-development`).
7. After all tasks: run `superpowers:verification-before-completion` for the full-suite check.
8. Go straight to Step 5 to report back and ask about integration.

This path keeps everything in one conversation but burns context. Use it for small specs.

#### 4b. Subagent — sonnet 5

Invoke the `executing-specs` agent via the Agent tool (`subagent_type: "executing-specs"`) with a self-contained prompt:

- Absolute path to the spec
- The branch the work should land on
- Any user-stated constraints surfaced in Step 1
- Any custom instructions the user gave in Step 3's follow-up, included verbatim
- If Step 2 detected a linked worktree: the absolute worktree root path, framed as the subagent's **exclusive project scope** — instruct it to read, write, and run all commands only inside this path, and never touch the main checkout or any sibling worktree under `.claude/worktrees/`.
- The spec's `## Environment & Test Execution` section, copied verbatim into the prompt, with an instruction to run its setup commands before starting task decomposition.
- The instruction to follow the agent's own internal process: decompose → parallel-safe grouping → per-task TDD → final-suite verification via verification-before-completion → report back

Use the agent's default model (defined in `agents/executing-specs.md` frontmatter, currently `sonnet`).

The subagent has its own tool access and is responsible for the entire implementation. **Do not** decompose tasks or write code in the parent session when running via subagent — that defeats the purpose of the dispatch.

### Step 5: Relay the Result

When the work finishes (subagent returns, or in-session implementation completes):

- Summarize what shipped (one or two sentences)
- Show the branch name and final commit SHA(s)
- **If the spec was marked ephemeral** (noted in Step 1): delete it now — `rm <path>` — verify the deletion succeeded (e.g., `ls` the path and confirm it returns a "no such file" error), then commit the removal separately from the implementation commits.
- Surface any blockers, deviations, or open questions
- Ask the user how they want to integrate the work (merge, push + PR, keep the branch, discard) — this skill never decides integration
- Offer the **recognize-and-learn** skill as an optional follow-up to capture friction points from this implementation cycle
- **If the current checkout is a linked worktree**, offer to clean it up (this item is last, after integration): recommend the user run **`/cleanup-worktree`**, which tears down the worktree's Docker stack and removes the worktree in one step. Two caveats to state in the offer:
  - It is **user-invocable only** — recommend it, do not run it yourself.
  - Do it **after integration** — removal is destructive (`--force` discards anything uncommitted), so the work must be merged / PR'd / preserved first.

  Detect a linked worktree agnostically: the current checkout is linked when `git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`. If they match (the main checkout) or the directory is not a git repo, skip this item silently.

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
- Always follow the mode question with the optional custom-instructions follow-up; fold any answer into whichever path (4a or 4b) the user picked.
- When running in-session (4a), follow the same canonical TDD process the subagent would.
- When dispatching (4b), the parent does not write code or decompose tasks — the subagent owns that.
- Don't start work on main/master without explicit user consent.
- Relay subagent escalations faithfully; never silently retry.
- If the spec was marked ephemeral, delete it after relaying results and commit the removal — verify the deletion succeeded.
- After the work finishes, offer **recognize-and-learn** as a retrospective option.
- If the work was done in a linked worktree, offer `/cleanup-worktree` at the end (after integration) — recommend it, don't run it.

## Integration

**Called by:**
- **superpowers:brainstorming** — terminal handoff after the user approves the spec

**Dispatches to (when user selects subagent):**
- **executing-specs agent** (sonnet 5) — implements the spec end-to-end

**Follow-up (optional):**
- **superpowers:recognize-and-learn** — post-implementation retrospective on friction points
- **/cleanup-worktree** — offered at wrap-up when the work was done in a linked worktree; tears down its Docker stack and removes the worktree

**Required workflow skills:**
- **superpowers:test-driven-development** — applied per task during execution (in-session or in subagent)
- **superpowers:verification-before-completion** — applied at end of implementation for full-suite verification
