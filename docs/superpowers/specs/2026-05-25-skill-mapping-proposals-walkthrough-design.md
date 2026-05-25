# Skill Mapping — Proposals File + Two-Phase Walk-through

## Required Skills

_No specific skills required beyond defaults._

## Problem

The current skill-mapping flow has two issues:

1. **Silent application of skill expectations.** The re-investigation pass applies "technical-only" refinements without asking the user; only "behaviour/flow" gaps trigger a clarifying question. In practice, deciding what counts as "technical only" is judgement-laden, and the user has no visibility into what the brainstormer absorbed silently.
2. **Over-eager Required Skills block.** The current `spec-behaviour-driving` category lists a skill in `## Required Skills` whenever it has *any* runtime aspect, even when the spec body has already absorbed the substantive value. The executor is then handed a list of skills whose work is largely fulfilled by the spec content. The block grows; signal-to-noise drops.

The fix:

- Replace the structured-return + silent-application flow with a **proposals file** the subagent writes to disk. The parent walks the user through every proposal in two phases. Nothing is applied without explicit user confirmation.
- Drop the `spec-behaviour-driving` category. Every matched skill is exactly one of `spec-driving` or `behaviour-driving`. Strictness rule: default to `spec-driving` when ambiguous, so the spec absorbs the value and the Required Skills block stays lean.
- Make the proposals file **ephemeral**: written by the subagent, consumed during the walk-through, deleted before the spec is committed. Only the design spec persists on disk.

## Decision

Restructure `skills/brainstorming/SKILL.md` so:

- **Subagent writes** `docs/superpowers/specs/YYYY-MM-DD-<topic>-skill-proposals.md` and returns only the file path. It edits no other file. The proposals file is split into two sections: Phase 1 (proposed spec changes) and Phase 2 (behaviour-driven skill candidates).
- **Parent runs two-phase walk-through:**
  - **Phase 1 — Proposed spec changes.** Batched message listing each numbered change. User replies `confirm all` / a list of numbers / `refine N` / `reject all`. `refine N` opens a focused exchange on one change, ending in confirm or reject. After Phase 1 resolves, accepted changes are folded into the design state.
  - **Phase 2 — Behaviour-driven skills.** Batched message listing all candidates (pre-accepted by default). User replies `accept all` (or just acknowledges to keep defaults) / `opt out N` or `opt out 1, 3` / `none`. The two hard-coded defaults `superpowers:test-driven-development` and `superpowers:verification-before-completion` are always present in the Phase 2 list, regardless of subagent output, and are pre-accepted like the rest.
- **Both phases always run**, even when one is empty (predictable structure). An empty Phase 1 surfaces "no proposed spec changes — moving on." An empty Phase 2 still shows the two pre-accepted defaults and asks for opt-outs.
- **Categories drop from three to two:** `spec-driving` and `behaviour-driving`. The `spec-behaviour-driving` category and all references to it are removed.
- **Documentation step** writes the design spec with Phase 1 confirmations baked in and a `## Required Skills` block listing every Phase 2 skill the user did not opt out of. Then the proposals file is deleted (`rm`). Only the design spec is committed.

Rejected and refined-then-rejected proposals never appear in the design spec — the design spec contains only the final agreed state.

## Scope

**In scope:**
- Edits to `skills/brainstorming/SKILL.md`: checklist items 7–9, process flow graphviz block, "Skill Mapping (Before Writing)" subsection, "Re-investigation" subsection (replaced), "Documentation" subsection, category reference table, one bullet inside the "Confirm Skill Mapping" subsection that references the removed re-investigation pass.
- Edits to `CLAUDE.md` "Spec skill mapping" paragraph and the "Targeted subagent dispatch" paragraph's dispatch-point (2) description.

**Out of scope:**
- `skills/executing-specs/SKILL.md` — unchanged. The executor still reads `## Required Skills` from the spec; only the filter that produces the block changes.
- `agents/executing-specs.md` — unchanged.
- The Required Skills block format inside specs (still skill name + one-sentence rationale).
- The one-question-at-a-time rule for clarifying questions inside Phase 1 refinements.
- The hard-gate ("no implementation skills until user approves the spec").
- The visual companion offer flow.
- The recognize-and-learn skill.
- The brainstorming "Confirm Skill Mapping" step at checklist item 6 — the user still chooses opt-in vs skip; only the post-confirm flow changes.

## Changes to `skills/brainstorming/SKILL.md`

### Change 1 — Checklist items 7, 8, 9

Current items 7–9 read:

```
7. Map required skills — only if the user confirmed at step 6: dispatch a subagent on the approved design summary to identify which available skills apply, categorize each, and return structured expectations (see Skill Mapping (Before Writing) below)
8. Re-investigate design against skill expectations — only if the user confirmed at step 6: walk each (skill, expectation) pair against the approved design and apply silently for technical gaps; ask the user only when a gap would change behaviour, flow, or business logic (see Re-investigation below)
9. Write design doc — save to docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md and commit; the ## Required Skills block is written inline as part of this step (using the Step 7 mapping output filtered by category, or the zero-listable-skills fallback if the user declined skill mapping)
```

Replace with:

```
7. Dispatch skill-mapping subagent to write proposals file — only if the user confirmed at step 6: dispatch a general-purpose subagent on the approved design summary to write docs/superpowers/specs/YYYY-MM-DD-<topic>-skill-proposals.md, with Phase 1 (proposed spec changes) and Phase 2 (behaviour-driven skill candidates). Subagent returns only the file path (see Skill Mapping (Before Writing) below).
8. Walk user through proposals — only if the user confirmed at step 6: Phase 1 first (confirm/refine/reject per spec change, batched), then Phase 2 (opt-out batched for behaviour skills; the two defaults superpowers:test-driven-development and superpowers:verification-before-completion are always pre-accepted) (see Walk-through (Phase 1 + Phase 2) below).
9. Write design doc — save to docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md with Phase 1 confirmations baked into the body and a ## Required Skills block listing every Phase 2 skill the user did not opt out of. Delete the proposals file with rm before committing. Commit only the design spec.
```

### Change 2 — Process flow diagram

Update the graphviz block. Remove edges `"Run skill mapping?" -> "Map required skills\n(dispatch subagent)"` and `"Map required skills\n(dispatch subagent)" -> "Re-investigate design\nagainst skill expectations"` and `"Re-investigate design\nagainst skill expectations" -> "Write design doc"`. Remove the nodes `"Map required skills\n(dispatch subagent)"` and `"Re-investigate design\nagainst skill expectations"`.

Add nodes:
- `"Subagent writes proposals file"` [shape=box]
- `"Phase 1: walk through spec changes"` [shape=box]
- `"Phase 2: confirm behaviour skills"` [shape=box]
- `"Delete proposals file"` [shape=box]

Add edges:
- `"Run skill mapping?" -> "Subagent writes proposals file"` [label="yes"]
- `"Subagent writes proposals file" -> "Phase 1: walk through spec changes"`
- `"Phase 1: walk through spec changes" -> "Phase 2: confirm behaviour skills"`
- `"Phase 2: confirm behaviour skills" -> "Delete proposals file"`
- `"Delete proposals file" -> "Write design doc"`

The existing `"Run skill mapping?" -> "Write design doc"` [label="no, skip"] edge is unchanged.

### Change 3 — "Skill Mapping (Before Writing)" subsection — full rewrite

Replace the entire body of the "Skill Mapping (Before Writing)" subsection (currently lines 138–167 of `skills/brainstorming/SKILL.md`) with the following content:

After the user confirms skill mapping at the Confirm Skill Mapping step and before writing the spec file, dispatch a `general-purpose` subagent to **write a proposals file** at `docs/superpowers/specs/YYYY-MM-DD-<topic>-skill-proposals.md`. The subagent returns only the file path. It writes no other file. The brainstormer determines the topic slug and date before dispatching, and passes the exact path in the prompt.

The proposals file structure the subagent MUST produce:

~~~markdown
# Skill-Driven Improvement Proposals — <topic>

> Generated by skill-mapping subagent on <YYYY-MM-DD>.
> Ephemeral — deleted after the walk-through. Source design summary follows.

## Design summary
<1–3 paragraph copy of the design summary the subagent received>

## Phase 1 — Proposed spec changes
(walked through first; each is confirm / refine / reject)

### 1. <Short title of the change>
**Change:** <concrete edit: where in the spec and the text to add or modify>
**Rationale:** <why this change improves the spec, in one or two sentences>
**From skill:** `<skill-name>`

### 2. ...

## Phase 2 — Behaviour-driven skill candidates
(asked after Phase 1; all pre-accepted, user opts out as needed)

### 1. `superpowers:test-driven-development`  [default]
**Why relevant:** <one sentence tying skill to the design>

### 2. `superpowers:verification-before-completion`  [default]
**Why relevant:** <one sentence tying skill to the design>

### 3. `<subagent candidate>`
**Why relevant:** <one sentence>

### 4. ...
~~~

The subagent prompt MUST include:

1. **The exact file path** to write the proposals file to (the parent constructs this from `docs/superpowers/specs/YYYY-MM-DD-<topic>-skill-proposals.md` using the slug and date it will also use for the design spec).
2. **The structured design summary**, composed inline by the brainstormer from the approved-design conversational state. Cover: goal, scope, approach, key constraints.
3. **The verbatim list of skill names + descriptions** visible in the parent session's `<system-reminder>` "available skills" block.
4. **Explicit instructions** the subagent must follow:
   - Read the design summary end-to-end.
   - Scan the provided skill list. For each skill, decide whether it applies to *this specific* implementation. Be conservative — prefer fewer, high-signal matches over a long list.
   - For each matched skill, assign exactly one **category**:
     - `spec-driving` — the skill's value can be captured by editing the spec (content, examples, structural requirements, acceptance items). After the change lands in the spec, the executor has no runtime job for the skill.
     - `behaviour-driving` — the skill governs *how* the executor works at runtime; its value cannot be captured by spec content.
   - **Strictness rule:** when a skill could plausibly be either category, default to `spec-driving`. Only assign `behaviour-driving` when the runtime discipline is the substantive value AND the spec cannot absorb it.
   - For each `spec-driving` skill: emit zero, one, or several **Phase 1 proposals** — each a concrete proposed edit to the spec (where to add or modify, what text). Skip the skill if it produces no proposed edit.
   - For each `behaviour-driving` skill: emit one **Phase 2 candidate** with a one-sentence `Why relevant`.
   - **Two hard-coded Phase 2 defaults** are always included in the Phase 2 list and marked `[default]` regardless of whether the subagent independently matched them: `superpowers:test-driven-development` and `superpowers:verification-before-completion`. The subagent writes both into the Phase 2 section as items 1 and 2.
   - Write the proposals file at the exact path provided. Return only the file path in the response. Do not edit any other file.
   - If no skills match beyond the two defaults, the Phase 1 section is "_No proposed spec changes._" and the Phase 2 section contains only the two defaults.

After the subagent returns the path, the brainstormer reads the file and runs the Walk-through (Phase 1 + Phase 2) described below.

### Change 4 — Category reference table

Replace the existing 3-row category reference table with a 2-row table. The new table:

| Category | When to use | Example | Listed in `## Required Skills`? |
|---|---|---|---|
| **spec-driving** | The skill's value can be captured by editing the spec — content, examples, structural requirements, acceptance items. After the change lands, the executor has no runtime job. | "Collect comments on related pull requests and surface anything worth investigating" — the output becomes spec context; no runtime invocation needed. | No (changes are absorbed into the spec body via Phase 1) |
| **behaviour-driving** | The skill governs *how* the executor works at runtime. The spec body cannot absorb the value. | `superpowers:test-driven-development` — RED → GREEN → REFACTOR at runtime; spec doesn't restate the cycle. | Yes (added to the block in Phase 2, subject to user opt-out) |

The `spec-behaviour-driving` row is removed. No reference to that category remains in the SKILL.md.

### Change 5 — Replace "Re-investigation" subsection with "Walk-through (Phase 1 + Phase 2)"

Delete the entire current "Re-investigation" subsection (currently lines 168–186 of `skills/brainstorming/SKILL.md`, starting at the `**Re-investigation:**` heading). Replace with a new subsection titled `**Walk-through (Phase 1 + Phase 2):**` containing:

After the subagent returns the proposals file path, read the file. Run Phase 1, then Phase 2. Both phases always run, even when one is empty.

**Phase 1 — Proposed spec changes.** Show the user a single batched message listing every Phase 1 proposal by number, title, and rationale (collapsed enough to scan; full proposal text is in the file if the user wants to see it):

> Phase 1 — Proposed spec changes:
> 1. <title> — <one-line rationale>
> 2. <title> — <one-line rationale>
> 3. <title> — <one-line rationale>
>
> Reply with: `confirm all`, a list of numbers to confirm (e.g. `1, 3`), `refine N` to negotiate a specific change, or `reject all` to discard everything.

If Phase 1 has zero proposals, the message becomes "Phase 1 — No proposed spec changes. Moving on." and you proceed directly to Phase 2.

When the user picks `refine N`: enter a focused exchange on that one proposal. After the user is satisfied with the revised wording, ask them to `confirm` or `reject` it. Then re-show the remaining unresolved Phase 1 items. Track each item's disposition (confirmed / refined-and-confirmed / rejected) in memory.

When Phase 1 is fully resolved (every numbered proposal either confirmed or rejected), proceed to Phase 2.

**Phase 2 — Behaviour-driven skills.** Show the user a single batched message listing all Phase 2 candidates. Defaults (items 1 and 2) are marked `[default]`:

> Phase 2 — Required Skills candidates (all pre-accepted, opt out as needed):
> 1. `superpowers:test-driven-development`  [default]
> 2. `superpowers:verification-before-completion`  [default]
> 3. `<subagent candidate>` — <one-sentence why relevant>
> 4. `<subagent candidate>` — <one-sentence why relevant>
>
> Reply with: `accept all` (default), `opt out N` or `opt out 1, 3`, or `none` to clear the block.

If Phase 2 has only the two defaults and no subagent candidates, show those two and ask the same question.

Track which Phase 2 candidates the user opted out of. Everything not opted out is accepted.

**Rejected, refined-then-rejected, and opted-out items never appear in the design spec.** No record of them survives to disk after the proposals file is deleted.

Skip the entire Walk-through if the user declined skill mapping at the Confirm Skill Mapping step.

### Change 6 — Documentation subsection

Update the "Documentation" subsection (currently starting at line 188). The new content:

- Write the validated design (spec) to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`, baking in every Phase 1 proposal the user confirmed (using the final wording from any refinement loop, not the original subagent wording when the user negotiated a revision).
- The `## Required Skills` block at the top of the spec lists every Phase 2 skill the user did **not** opt out of. The block format is unchanged from today.
- (User preferences for spec location override the default path.)
- Use `elements-of-style:writing-clearly-and-concisely` skill if available.
- **Delete the proposals file** with `rm docs/superpowers/specs/YYYY-MM-DD-<topic>-skill-proposals.md`. The file is ephemeral. Verify the deletion succeeded before continuing (e.g., `ls` the path and confirm it returns a "no such file" error).
- Commit only the design spec to git.

**Filter rule for the `## Required Skills` block:** list every Phase 2 candidate that the user did not opt out of. No category-based filtering happens at this step — Phase 2 *is* the filter. Skills assigned `spec-driving` by the subagent never appear in the block because they never reach Phase 2 in the first place.

The block format (unchanged):

~~~
## Required Skills

> Before starting implementation, invoke each skill in **Required Skills** via the Skill tool.

- **<skill name>** — <one-sentence why_relevant>
~~~

**Zero-listable-skills fallback:** if after Phase 2 the user opted out of every Phase 2 candidate (including both defaults), OR if the user declined skill mapping at the Confirm Skill Mapping step, the block becomes:

~~~
## Required Skills

_No specific skills required beyond defaults._
~~~

No separate post-write skill mapping pass.

### Change 7 — Confirm Skill Mapping subsection — bullet update

In the "Confirm Skill Mapping" subsection of `skills/brainstorming/SKILL.md`, the "If the user picks **Skip**" list currently includes the bullet `Do not run the re-investigation pass.` Replace that bullet with `Do not run the Phase 1 / Phase 2 walk-through.` The other two bullets in that list (`Do not dispatch the mapping subagent.` and `Proceed directly to Documentation. The spec's ## Required Skills block uses the zero-listable-skills fallback.`) are unchanged.

## Changes to `CLAUDE.md`

### Change 8 — "Spec skill mapping" paragraph

Replace the current "Spec skill mapping" paragraph (line 13) with:

> **Spec skill mapping.** During brainstorming, after the user verbally approves the design, the brainstormer asks whether to run skill mapping for this design (opt-in — overhead isn't worth it for small or throwaway changes; TDD and verification-before-completion still apply at execution time via `executing-specs`'s own required workflow skills regardless of this choice). If confirmed, a `general-purpose` subagent scans the available skills list against the approved design summary and writes an ephemeral proposals file at `docs/superpowers/specs/YYYY-MM-DD-<topic>-skill-proposals.md`. The file has two sections: Phase 1 (proposed spec changes from `spec-driving` skills) and Phase 2 (behaviour-driven skill candidates). The brainstormer then runs a two-phase walk-through with the user: Phase 1 (each proposed spec change is confirmed, refined-then-confirmed, or rejected — batched message, one-by-one for refinement) and Phase 2 (all candidates pre-accepted, user opts out as needed; the two hard-coded defaults `superpowers:test-driven-development` and `superpowers:verification-before-completion` are always included). Categories are now just two: `spec-driving` (value absorbed into the spec via Phase 1, never listed in `## Required Skills`) and `behaviour-driving` (listed in `## Required Skills` unless opted out in Phase 2). The `spec-behaviour-driving` category is removed; when a skill could be either, the strictness rule defaults to `spec-driving`. After the walk-through, the design spec is written with Phase 1 confirmations baked in and `## Required Skills` populated from Phase 2 acceptances, then the proposals file is deleted with `rm`. Only the design spec is committed; rejected and opted-out items leave no trace. If the user declined skill mapping, the block uses the zero-listable-skills fallback (`_No specific skills required beyond defaults._`). There is no second mapping pass after the spec exists.

### Change 9 — "Targeted subagent dispatch" paragraph

Update the second dispatch point's description (currently line 17) so it reflects the new flow. Change the sentence describing dispatch point (2) from:

> (2) brainstorming's spec-skill-mapping step — a one-shot `general-purpose` agent that scans the approved design summary, categorizes matched skills (spec-driving / behaviour-driving / spec-behaviour-driving), and returns structured expectations for the brainstormer to consume during the re-investigation pass and inline spec write. The mapping subagent edits no files.

to:

> (2) brainstorming's spec-skill-mapping step — a one-shot `general-purpose` agent that scans the approved design summary, categorizes matched skills (spec-driving or behaviour-driving — the strictness rule defaults to `spec-driving`), and writes an ephemeral proposals file at `docs/superpowers/specs/YYYY-MM-DD-<topic>-skill-proposals.md` with Phase 1 (proposed spec changes) and Phase 2 (behaviour-driven skill candidates). The brainstormer then walks the user through both phases, applies confirmed Phase 1 changes to the design spec, populates `## Required Skills` from Phase 2 acceptances, and deletes the proposals file. The mapping subagent writes only the proposals file; all other file edits are the brainstormer's.

## Non-changes (explicit)

- `skills/executing-specs/SKILL.md` is unchanged.
- `agents/executing-specs.md` is unchanged.
- The Required Skills block format inside specs is unchanged.
- The one-question-at-a-time rule for clarifying questions inside Phase 1 refinements is unchanged.
- The hard-gate (no implementation skills until user approves the spec) is unchanged.
- The visual companion offer flow is unchanged.
- The "Confirm Skill Mapping" step at checklist item 6 is unchanged — same yes/skip question, same two options. (One bullet inside its subsection body is updated by Change 7 to remove a stale reference to the deleted re-investigation pass; the user-facing question and its options are not touched.)
- The `recognize-and-learn` skill is unchanged.
- YAML frontmatter in `skills/brainstorming/SKILL.md` is unchanged.

## Acceptance Criteria

The implementation is done when:

1. The checklist in `skills/brainstorming/SKILL.md` items 7, 8, 9 match the text specified in Change 1. Item 7 references writing the proposals file. Item 8 references Phase 1 and Phase 2 and names both hard-coded defaults. Item 9 references deleting the proposals file before committing.
2. The process flow graphviz block in `skills/brainstorming/SKILL.md` contains the four new nodes (`Subagent writes proposals file`, `Phase 1: walk through spec changes`, `Phase 2: confirm behaviour skills`, `Delete proposals file`) and the edges specified in Change 2. The nodes `Map required skills\n(dispatch subagent)` and `Re-investigate design\nagainst skill expectations` are absent from the graphviz block.
3. The "Skill Mapping (Before Writing)" subsection in `skills/brainstorming/SKILL.md` instructs the subagent to write `docs/superpowers/specs/YYYY-MM-DD-<topic>-skill-proposals.md` and return only the file path. The proposals file template (with Phase 1 and Phase 2 sections) is shown verbatim in the subsection. The subagent instructions list both `superpowers:test-driven-development` and `superpowers:verification-before-completion` as hard-coded Phase 2 defaults that are always included regardless of independent matching.
4. The category reference table in `skills/brainstorming/SKILL.md` contains exactly two rows: `spec-driving` and `behaviour-driving`. The `spec-behaviour-driving` row is absent. The "Listed in `## Required Skills`?" column reflects the new flow ("No (changes are absorbed into the spec body via Phase 1)" and "Yes (added to the block in Phase 2, subject to user opt-out)").
5. The "Walk-through (Phase 1 + Phase 2)" subsection in `skills/brainstorming/SKILL.md` replaces the old "Re-investigation" subsection. It contains the Phase 1 batched-message template (`confirm all`/numbers/`refine N`/`reject all`), the Phase 2 batched-message template with the opt-out semantics, the rule that both phases always run even when empty, and the explicit "Rejected, refined-then-rejected, and opted-out items never appear in the design spec" rule. The old four-state table (Covered / Silent — technical only / Silent — affects flow or business logic / Contradicts) is absent.
6. The "Documentation" subsection in `skills/brainstorming/SKILL.md` instructs that the design spec is written with Phase 1 confirmations baked in, `## Required Skills` is populated from Phase 2 non-opt-outs, the proposals file is deleted with `rm`, and only the design spec is committed. The zero-listable-skills fallback is preserved and triggers when the user opted out of every Phase 2 candidate or declined skill mapping at step 6.
7. The "Confirm Skill Mapping" subsection's "If the user picks **Skip**" list in `skills/brainstorming/SKILL.md` contains the bullet `Do not run the Phase 1 / Phase 2 walk-through.` and does NOT contain `Do not run the re-investigation pass.` (Change 7).
8. The `CLAUDE.md` "Spec skill mapping" paragraph matches the new wording in Change 8. The paragraph mentions the ephemeral proposals file, both phases, the two-category model, the strictness rule, and the deletion step.
9. The `CLAUDE.md` "Targeted subagent dispatch" paragraph's dispatch-point (2) description matches the new wording in Change 9 — it mentions writing the proposals file and the two-phase walk-through, and lists exactly two categories.
10. The string `spec-behaviour-driving` appears nowhere in `skills/brainstorming/SKILL.md` or `CLAUDE.md`. (Verify by grep.)
11. The phrase `re-investigation` (case-insensitive) appears nowhere in `skills/brainstorming/SKILL.md` or `CLAUDE.md` except in commit messages or git history (which are not in scope). (Verify by grep.)
12. The phrase `Silent — technical only` appears nowhere in `skills/brainstorming/SKILL.md`. (Verify by grep.)
13. Markdown remains well-formed in both files (tables intact, code fences balanced, headings nested correctly, graphviz block parses).
14. YAML frontmatter in `skills/brainstorming/SKILL.md` is character-identical to before the change (lines 1–4: `---`, `name: brainstorming`, `description: "..."`, `---`).

## Testing

This is a skill + documentation edit. Verification is by reading and grepping:

- Re-read `skills/brainstorming/SKILL.md` end-to-end after edits. Confirm:
  - Checklist items 7, 8, 9 match Change 1 verbatim (or close paraphrase preserving every named element).
  - Graphviz block contains the four new nodes and the edges from Change 2, and the two old nodes/edges are absent.
  - "Skill Mapping (Before Writing)" subsection contains the proposals-file template verbatim and lists both hard-coded defaults.
  - Category reference table has exactly two rows.
  - "Walk-through (Phase 1 + Phase 2)" subsection replaces "Re-investigation" and contains both batched-message templates.
  - "Documentation" subsection contains the `rm` instruction and the zero-listable-skills fallback.
- Re-read `CLAUDE.md` "Spec skill mapping" and "Targeted subagent dispatch" paragraphs. Confirm they match Change 8 and Change 9.
- Re-read the "Confirm Skill Mapping" subsection in `skills/brainstorming/SKILL.md`. Confirm its "If the user picks **Skip**" bullet list contains `Do not run the Phase 1 / Phase 2 walk-through.` and no bullet referencing "re-investigation".
- `grep -n 'spec-behaviour-driving' skills/brainstorming/SKILL.md CLAUDE.md` — expect zero matches.
- `grep -ni 're-investigation' skills/brainstorming/SKILL.md CLAUDE.md` — expect zero matches.
- `grep -n 'Silent — technical only' skills/brainstorming/SKILL.md` — expect zero matches.
- `grep -n 'Map required skills' skills/brainstorming/SKILL.md` — expect zero matches.
- `grep -n 'Subagent writes proposals file' skills/brainstorming/SKILL.md` — expect at least one match (in the graphviz block).
- `grep -n 'Phase 1: walk through spec changes' skills/brainstorming/SKILL.md` — expect at least one match.
- `grep -n 'Phase 2: confirm behaviour skills' skills/brainstorming/SKILL.md` — expect at least one match.
- `grep -n 'Delete proposals file' skills/brainstorming/SKILL.md` — expect at least one match.
- `grep -n 'skill-proposals.md' skills/brainstorming/SKILL.md CLAUDE.md` — expect multiple matches across both files.
- Confirm Markdown well-formedness by visual scan (tables intact, code fences balanced, headings correctly nested).
- Confirm YAML frontmatter in `skills/brainstorming/SKILL.md` is byte-identical to pre-edit by diffing lines 1–4 against a saved snapshot or by visual re-read.

No code tests are appropriate.

## Follow-up Work

None as part of this spec.
