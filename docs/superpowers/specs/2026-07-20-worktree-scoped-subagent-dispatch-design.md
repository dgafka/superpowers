# Design: worktree-scoped subagent dispatch for executing-specs

## Required Skills

_No specific skills required beyond defaults._

## Environment & Test Execution

This is a documentation/behaviour-guidance change to skill and agent markdown
files in this repo — no build or install step. There is no automated test
suite for skill/agent prose; verification is a read-through (see Testing
section below).

## Goal

When `executing-specs` dispatches the subagent while the parent session is
running inside a linked git worktree (e.g. `.claude/worktrees/activity-projection`),
the subagent must be explicitly scoped to that worktree — not the main
checkout, not a sibling worktree — and must know how to prepare the
environment and run tests there. Today the dispatch prompt (Step 4b) lists
spec path, branch, and constraints, but never the working-directory scope or
how to run tests, so a dispatched subagent has no explicit guardrail against
polluting the main checkout or another worktree.

This also establishes a new required spec section, `## Environment & Test
Execution`, so setup/test-run information is captured once at design time
instead of guessed or rediscovered at dispatch time.

## Non-goals

- No change to Step 3 (execution-mode question) or the wrap-up items in Step 5
  beyond what's needed for consistency with the new Step 0 in the agent.
- No use of the `Agent` tool's `isolation: "worktree"` option — this design
  relies on the subagent inheriting the parent's already-existing worktree
  cwd, made explicit and verified in the dispatch prompt and agent process.
- No auto-discovery of setup/test commands by `executing-specs` at dispatch
  time — that information comes from the spec (Change 1), not live detection.
- No backfill of the new section into specs written before this change lands.

## Change 1: New spec section — `## Environment & Test Execution`

Edit `skills/brainstorming/SKILL.md`.

During "Explore project context" (checklist item 1), also look for setup/test
conventions in the target project: Makefile, composer.json / package.json
scripts, docker-compose.yml, README instructions.

- If confidently discovered, draft the `## Environment & Test Execution`
  section directly from what was found.
- If ambiguous or nothing found, ask the user one clarifying question: "How do
  you set up the environment and run tests for this project?"

At the Documentation step, this section is **always** written into the spec —
regardless of whether the user chose to run skill mapping (it is not part of
the optional Phase 1/Phase 2 flow). Placement: directly after `## Required
Skills`.

Format:

```
## Environment & Test Execution

**Setup:**
1. <command>
2. <command>

**Running tests:**
- <command>
```

Scale to complexity — a single line like "Running tests: `npm test`, no setup
required" is fine for simple projects.

## Change 2: `executing-specs` skill — detect worktree, enrich dispatch

Edit `skills/executing-specs/SKILL.md`.

### Step 2 (Confirm Branch State) — add worktree detection

After the existing branch-state checks, add:

> Also detect whether the current checkout is a linked worktree: the checkout
> is linked when `git rev-parse --git-dir` differs from `git rev-parse
> --git-common-dir`. If linked, capture the absolute worktree root
> (`git rev-parse --show-toplevel`) — it's needed for Step 4b's subagent
> dispatch prompt. If they match (the main checkout), there is no worktree
> scope to pass along.

### Step 4b (Subagent dispatch) — two new prompt items

Add to the existing bullet list of what the dispatch prompt must contain:

> - If Step 2 detected a linked worktree: the absolute worktree root path,
>   framed as the subagent's **exclusive project scope** — instruct it to
>   read, write, and run all commands only inside this path, and never touch
>   the main checkout or any sibling worktree under `.claude/worktrees/`.
> - The spec's `## Environment & Test Execution` section, copied verbatim
>   into the prompt, with an instruction to run its setup commands before
>   starting task decomposition.

### Step 4a (in-session) — early environment-prep sub-step

Insert as the new first item in the numbered list (renumbering the rest):

> 1. If the spec's `## Environment & Test Execution` section lists setup
>    commands and the environment isn't already up, run them now — before
>    doing anything else.

## Change 3: `executing-specs` agent — scope confirmation + environment prep

Edit `agents/executing-specs.md`.

### New Step 0: Confirm Scope & Prepare Environment

Insert before the existing Step 1 (Load and Critique the Spec):

> ### Step 0: Confirm Scope & Prepare Environment
>
> 1. If the dispatching prompt gave you a worktree root path: verify your
>    actual working directory matches it (`pwd`, and `git rev-parse
>    --show-toplevel` should equal the given path). If it doesn't match,
>    **stop and report back** — do not proceed in the wrong directory.
> 2. Treat that path as your project root for everything that follows: read,
>    write, and run commands only inside it. Never touch the main checkout or
>    any sibling worktree under `.claude/worktrees/`.
> 3. If the dispatching prompt included `Environment & Test Execution` setup
>    commands, run them now, before doing anything else.

### "Inputs You Will Receive" — add two items

> - The worktree root path to scope your work to, if the parent session is
>   running from a linked worktree
> - The spec's `Environment & Test Execution` instructions (setup commands and
>   how to run tests)

### "Stop Conditions" — add one bullet

> - Your working directory doesn't match the worktree root path given by the
>   parent, after verification

### "What You Must Not Do" — add one bullet

> - Operate outside the given worktree scope (read, write, or run commands
>   against the main checkout or another worktree) when a worktree path was
>   provided

### "Remember" — add one bullet

> - Confirm scope and run environment setup (Step 0) before critiquing the
>   spec or decomposing tasks

## Testing

This is a documentation/behaviour-guidance edit to skill and agent files —
there is no executable unit to test. Verification is a read-through
confirming:

1. `skills/brainstorming/SKILL.md`'s project-context step drafts or asks for
   the `Environment & Test Execution` section, and the Documentation step
   always writes it after `Required Skills`, regardless of the skill-mapping
   choice.
2. `skills/executing-specs/SKILL.md` Step 2 detects a linked worktree via the
   `git-dir`/`git-common-dir` rule and captures the absolute root.
3. Step 4b's dispatch-prompt bullet list includes the worktree-scope
   instruction (when detected) and the copied `Environment & Test Execution`
   section.
4. Step 4a includes the environment-setup sub-step before decomposition.
5. `agents/executing-specs.md`'s new Step 0 verifies cwd against the given
   worktree path, stops on mismatch, and runs environment setup before Step 1.
6. The agent's "Inputs You Will Receive", "Stop Conditions", "What You Must
   Not Do", and "Remember" sections are updated consistently with Step 0.
7. No other step or section changed beyond what's listed above.
