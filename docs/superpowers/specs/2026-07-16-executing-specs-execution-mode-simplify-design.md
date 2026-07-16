# Design: simplify executing-specs execution-mode menu

## Required Skills

_No specific skills required beyond defaults._

## Goal

Simplify the `executing-specs` skill's Step 3 execution-mode prompt from four
options down to two, and replace the old "Hold — manual changes first" option
with an optional custom-instructions follow-up that still executes (rather than
stopping).

## Non-goals

- No change to Step 1 (spec load/sanity-check), Step 2 (branch check), or
  Step 5 (relay/wrap-up) beyond the cross-reference edits listed below.
- No change to the `executing-specs` agent's TDD process (`agents/executing-specs.md`
  Steps 1–5) beyond removing the opus-override instruction from the dispatch note.
- No change to the agent's stated 1M-context-window capability — that's a real
  technical property of the agent, independent of how the parent's menu is worded.
- No new "plain stop, do nothing" path. If the user wants to hold off, they
  simply don't invoke the skill yet — there's no menu option for it anymore.

## Change

### 1. `skills/executing-specs/SKILL.md` — Step 3 becomes a 2-option menu

Replace the four-option table with:

| Option | When to recommend |
|---|---|
| **Continue in this session** | Small specs, or when the user wants to stay in this context. The parent runs the TDD loop directly. |
| **Subagent — sonnet 5** | Default for most specs. Isolates the long TDD loop from this conversation, at lower cost to the parent's context. |

Do not mark a default — the right answer depends on the spec (unchanged rule).

After the user picks one of the two options, ask a follow-up question (free
text, optional):

> "Any custom instructions for how to approach this execution? (optional —
> leave blank for standard auto-decomposition)"

- **Blank** → proceed exactly as today: standard spec re-read → decompose →
  parallel-safe grouping → per-task TDD → final verification.
- **Non-blank** → fold the instructions in as an additional constraint layered
  on top of the spec, before decomposition:
  - **In-session (4a):** treat the custom instructions as extra constraints
    the parent keeps in view alongside the spec while decomposing and
    executing tasks.
  - **Subagent (4b):** include the custom instructions verbatim in the
    dispatch prompt, alongside the spec path, branch, and any Step-1-surfaced
    constraints.

### 2. Step 4 — Execute

- **4a (Continue in this session):** unchanged, except it now folds in custom
  instructions (from the Step 3 follow-up) as an extra constraint before
  decomposition.
- **4b (Subagent — sonnet 5):** drop the opus-override note entirely. The
  agent always runs at its default frontmatter model (`sonnet`, defined in
  `agents/executing-specs.md`). Include the custom instructions (if any) in
  the dispatch prompt.
- **4c (Hold):** delete this subsection. There is no more third execution
  path — Step 3 has exactly two choices, and the custom-instructions
  follow-up governs approach, not whether to execute.

### 3. Frontmatter and cross-references — reword to match

- `skills/executing-specs/SKILL.md` frontmatter `description`: change "asks
  how to execute (in this session or via a subagent at sonnet 1M / opus)" to
  "asks how to execute (in this session or via a subagent at sonnet 5), with
  an optional custom-instructions follow-up".
- Overview numbered list, item 3: change "Asks the user how to execute: in
  this session, via subagent (sonnet 1M), via subagent (opus), or hold" to
  "Asks the user how to execute: in this session or via subagent (sonnet 5),
  then optionally takes custom instructions on approach".
- `## Remember` section: update "Ask the execution-mode question (Step 3)
  every time. Do not pick a default for the user." to reflect the 2-option
  menu; remove any Hold-specific reminder if present; add a line noting the
  optional custom-instructions follow-up applies to either choice.
- `## Integration` section, **Dispatches to**: change "(sonnet 1M by default;
  opus on user choice)" to "(sonnet 5)".

### 4. `agents/executing-specs.md` — no functional change

Leave the "You run on Claude Sonnet with a 1M-context window" line as-is —
this describes the agent's real technical capability, not the parent-side
menu label. No opus-related text exists in this file to remove.

### 5. Root `CLAUDE.md` — reword the three execution-mode-prompt mentions

- **"Execution-mode prompt" paragraph:** change "asks the user to choose:
  continue in this session, dispatch the subagent at sonnet 1M, dispatch the
  subagent at opus, or hold for manual changes first ... Sonnet 1M is the
  cost/context default; opus is for harder reasoning; in-session execution
  avoids the subagent boundary but burns the parent's context" to describe
  the new 2-option menu (continue in-session / subagent at sonnet 5) plus the
  optional custom-instructions follow-up that applies to either choice.
- **"Targeted subagent dispatch" paragraph:** change "optional offload of TDD
  execution onto sonnet 1M (cost/context) or opus (reasoning), user's choice
  at Step 3" to "optional offload of TDD execution onto sonnet 5, user's
  choice at Step 3".
- **Notes-for-working-in-this-repo bullet:** change "The execution-mode
  question (in-session / sonnet 1M / opus / hold) is required. Do not pick a
  default for the user; surface the trade-off and let them choose." to
  reflect the 2-option menu (in-session / sonnet 5) plus the optional
  custom-instructions follow-up; keep the "do not pick a default" rule.

## Testing

This is a documentation/behaviour-guidance edit to skill and agent prose —
there is no executable unit to test. Verification is a read-through
confirming:

1. Step 3 in `SKILL.md` presents exactly two options (in-session, subagent —
   sonnet 5), with no default marked.
2. A custom-instructions follow-up (optional, free text) is described after
   the Step 3 choice, applying to both options.
3. Step 4 no longer has a 4c (Hold) subsection; 4a and 4b both describe
   folding in custom instructions.
4. No remaining references to "sonnet 1M", "opus", or "Hold" as a menu choice
   anywhere in `skills/executing-specs/SKILL.md`, `agents/executing-specs.md`,
   or root `CLAUDE.md` (the agent's "1M-context window" capability sentence
   is the one intentional exception).
5. The `## Remember` and `## Integration` sections in `SKILL.md` are
   consistent with the new Step 3/4 wording.
