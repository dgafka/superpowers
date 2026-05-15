# Skill-Driven Spec Design

## Required Skills

> Before starting implementation, invoke each skill in **Required Skills** via the Skill tool.

- **superpowers:writing-skills** — This spec edits `skills/brainstorming/SKILL.md` (checklist, graphviz flow, subsections, subagent prompt) and touches `CLAUDE.md`'s skill-related paragraph; the writing-skills skill governs how skill files must be structured and verified.
- **superpowers:verification-before-completion** — Acceptance Criteria require grep-based checks for absent phrases and visual re-reads of both edited files; evidence (grep output, re-read confirmation) must be collected before claiming done.
- **superpowers:test-driven-development** — Applies at the "test the docs" level: each acceptance criterion (checklist order, graphviz edges, subsection order, table presence, frontmatter integrity, forbidden-phrase greps) is a verifiable check that should drive the edits and confirm them.

## Problem

Skills are consulted exactly once during brainstorming, at the end, after the spec body is already written. The "Spec Skill Mapping" step dispatches a `general-purpose` subagent that scans the finished spec and prepends a `## Required Skills` block to it. Two costs:

1. **Skills don't shape spec content.** Acceptance Criteria, Testing, and Scope sections are written before any skill has been read. The brainstormer's judgment is the only filter. Whether skill-driven requirements (TDD discipline, evidence enumeration, frontmatter integrity for skill edits, etc.) reach the spec is luck-based.
2. **Retrospective labelling, not prospective shaping.** The mapping step adds a block listing which skills the *implementer* should load. The spec body itself doesn't reflect what those skills require.

The fix: move the mapping pass *before* the spec is written, use the returned skill expectations to drive spec content, and insert a re-investigation pass between mapping and writing. Re-investigation applies technical-detail gaps silently and only stops to ask the user when a skill expectation would change behaviour, flow, or business logic.

## Decision

Restructure `skills/brainstorming/SKILL.md` so:

- The skill mapping subagent runs **after** verbal design approval but **before** the spec file is written.
- The subagent receives a design summary (not a spec path) and returns structured expectations — it does **not** edit any file.
- A new re-investigation pass walks each `(skill, expectation)` pair against the approved design and classifies each into one of four states. Three of the four are resolved without user interaction; only one triggers a clarifying question.
- The current post-spec mapping step is deleted. There is exactly one skill consultation per brainstorm, before writing.

The Required Skills block format inside specs is unchanged from today. Only the timing and source of the block changes.

## Scope

**In scope:**
- Edits to `skills/brainstorming/SKILL.md`: checklist, process flow diagram, "After the Design" section restructure, mapping subagent prompt rewrite, new re-investigation subsection.
- Edits to `CLAUDE.md` "What's different from upstream" — update the "Spec skill mapping" paragraph.

**Out of scope:**
- `skills/executing-specs/SKILL.md` — no change. The implementer still reads `## Required Skills` from the spec; only the provenance of that block shifts.
- `agents/executing-specs.md` — no change.
- The Required Skills block format inside specs.
- Any other skill in the repo.

## Changes to `skills/brainstorming/SKILL.md`

### Change 1 — Checklist

The existing numbered checklist (items 1–10) currently runs: explore context → offer visual companion → ask clarifying questions → propose approaches → present design → write design doc → spec self-review → map required skills → user reviews spec → transition to implementation.

Reorder the post-design items. New ordering:

1. Explore project context
2. Offer visual companion (when applicable)
3. Ask clarifying questions
4. Propose 2–3 approaches
5. Present design
6. **Map required skills (dispatch subagent on design summary)**
7. **Re-investigate design against skill expectations**
8. Write design doc → save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
9. Spec self-review
10. User reviews the written spec
11. Transition to implementation (invoke `executing-specs`)

The item that previously read "Map required skills (dispatch a subagent...)" is moved to position 6. The new item 7 is added. The previous "Write design doc" item moves to position 8.

### Change 2 — Process flow diagram

Update the graphviz block so the post-approval edges run:

```
"User approves design?" -> "Map required skills (dispatch subagent)" [label="yes"]
"Map required skills (dispatch subagent)" -> "Re-investigate design against skill expectations"
"Re-investigate design against skill expectations" -> "Write design doc"
"Write design doc" -> "Spec self-review (fix inline)"
"Spec self-review (fix inline)" -> "User reviews spec?"
"User reviews spec?" -> "Write design doc" [label="changes requested"]
"User reviews spec?" -> "Invoke executing-specs skill" [label="approved"]
```

Delete the current post-spec mapping node and its edges (`"Spec self-review (fix inline)" -> "Map required skills (dispatch subagent)"` and `"Map required skills (dispatch subagent)" -> "User reviews spec?"`).

### Change 3 — "After the Design" section restructure

The current sub-sections appear in this order: Documentation, Spec Self-Review, Spec Skill Mapping, User Review Gate, Implementation.

Rearrange to:

1. **Skill Mapping (Before Writing)**
2. **Re-investigation**
3. **Documentation**
4. **Spec Self-Review**
5. **User Review Gate**
6. **Implementation**

The Skill Mapping subsection moves up and is rewritten (Change 4). Re-investigation is new (Change 5). Documentation is updated (Change 6). Spec Self-Review, User Review Gate, and Implementation subsections keep their existing content.

### Change 4 — Skill Mapping (Before Writing) content

Replace the body of the (now-relocated) Skill Mapping subsection. The new content covers:

- **The subagent prompt MUST include three things:**
  1. The structured design summary, composed inline by the brainstormer from the approved-design conversational state. The summary contains: goal, scope, approach, key constraints. The subagent does **not** receive a spec path because the spec doesn't exist yet.
  2. The verbatim list of skill names + descriptions visible in the parent session's `<system-reminder>` "available skills" block. The subagent's own system-reminder may differ; the parent must pass its list so the mapping reflects the actual environment.
  3. The explicit instruction set described below.
- **The subagent does not edit any file.** It returns a structured response only.
- **Per matched skill, the subagent returns three fields:**
  - `name` — skill identifier (e.g., `superpowers:test-driven-development`).
  - `why_relevant` — one sentence tying the skill to *this* design.
  - `expectations` — bullet list of items the spec should specify if this skill applies. Examples: "Acceptance Criteria must enumerate the evidence the implementer collects to prove done", "Testing must specify per-task verification approach for non-code edits", "Scope must call out frontmatter integrity if editing a skill file".
- **Match rule:** conservative. Prefer fewer, high-signal matches over a long list. `superpowers:test-driven-development` and `superpowers:verification-before-completion` apply to nearly every spec and should default in unless clearly inapplicable.
- **Zero matches fallback:** if the subagent returns no skills, the Required Skills block written at Step 8 becomes `_No specific skills required beyond defaults._` and the re-investigation pass at Step 7 is skipped.

Subagent prompt template to embed verbatim in the SKILL.md:

> Read the following approved design summary end-to-end. Scan the provided skill list and identify which skills apply to *this specific* implementation. Be conservative — prefer fewer, high-signal matches. `superpowers:test-driven-development` and `superpowers:verification-before-completion` apply to nearly every spec and should default in unless clearly inapplicable.
>
> For each matched skill, read the skill file end-to-end and extract concrete expectations the spec should address. Each expectation should be a single bullet stating something the spec ought to specify (e.g., "Acceptance Criteria must enumerate evidence", "Testing must define per-task verification approach").
>
> Return a structured response. For each matched skill, include: `name` (skill identifier), `why_relevant` (one sentence specific to this design), `expectations` (bullet list). Do not edit any file.
>
> If you cannot match any skill with confidence, return an empty list.

### Change 5 — Re-investigation pass

Add a new subsection `### Re-investigation` immediately after Skill Mapping (Before Writing).

Content of the new subsection:

The brainstormer walks each `(skill, expectation)` pair returned by the mapping subagent against the approved design and classifies each into one of four states:

| State | Action |
|---|---|
| **Covered** | The design already specifies what the expectation asks for. Move on. |
| **Silent — technical only** | The expectation only refines HOW the work is verified or structured (verification evidence, testing detail, scope clarification, restructuring to a skill's expected template). Apply directly: incorporate the requirement into the spec content the brainstormer is about to write. **No user question.** |
| **Silent — affects flow or business logic** | The expectation would change WHAT gets built, the task decomposition, external dependencies, or the order of work. Ask the user a clarifying question (one at a time, per the existing rule). |
| **Contradicts** | The design specifies something incompatible with the expectation. Surface the conflict; the user either revises the design or consciously waives the expectation. Record any waiver as a deliberate deviation in the spec body. |

One-sentence decision heuristic to embed in the SKILL.md:

> Apply silently when the skill expectation only specifies HOW to verify or structure work the user already approved; ask when it would change WHAT gets built, the decomposition, or external dependencies.

After the loop: if any silent changes were applied, the brainstormer surfaces a one-line transparency note before writing the spec, e.g. "Applied 3 skill-driven refinements: enumerated evidence in Acceptance Criteria, added grep-check to Testing, tightened Scope to call out frontmatter integrity." This is a statement, not a question — the user is not asked to confirm.

Skip the entire re-investigation pass if the mapping subagent returned zero skills.

### Change 6 — Documentation subsection

Update the writing step so the Required Skills block is written inline as part of the initial spec write, using the Step 6 mapping output.

The block format remains:

```
## Required Skills

> Before starting implementation, invoke each skill in **Required Skills** via the Skill tool.

- **<skill name>** — <one-sentence why_relevant>
```

If the mapping returned zero skills, the block becomes:

```
## Required Skills

_No specific skills required beyond defaults._
```

The spec body itself (Acceptance Criteria, Testing, Scope, etc.) already reflects the skill-driven refinements applied during re-investigation. No separate post-write skill mapping pass.

### Change 7 — Delete post-spec mapping flow

Remove every reference to dispatching the skill-mapping subagent *after* writing the spec. Specifically, delete (or rewrite to remove the post-spec assertion):

- The previous Spec Skill Mapping subsection content (replaced by Change 4 in its new location).
- Any sentence in the SKILL.md asserting the mapping happens "after the spec passes self-review" or "before the user reviews it."
- Any instruction that the subagent edits the spec file or prepends a block to it. The subagent now returns a structured response only.

## Changes to `CLAUDE.md`

### Change 8 — Update "Spec skill mapping" paragraph

The current paragraph in the "What's different from upstream" section reads:

> **Spec skill mapping.** During brainstorming, after the spec passes self-review and before the user reviews it, a `general-purpose` subagent is dispatched to scan the available skills list against the spec and prepend a `## Required Skills` block to the spec.

Replace it with:

> **Spec skill mapping.** During brainstorming, after the user verbally approves the design but before the spec file is written, a `general-purpose` subagent scans the available skills list against the approved design summary and returns structured expectations per matched skill (no file edits). The brainstormer then runs a re-investigation pass: technical-detail gaps (verification evidence, testing details, scope refinements) are applied silently to the spec being drafted; gaps that would change behaviour, flow, or business logic trigger one-at-a-time clarifying questions to the user. The `## Required Skills` block is written inline as part of the initial spec write. There is no second mapping pass after the spec exists.

## Non-changes (explicit)

- `skills/executing-specs/SKILL.md` is unchanged. The implementer still reads `## Required Skills` from the spec; only the provenance of that block changes.
- `agents/executing-specs.md` is unchanged.
- The Required Skills block *format* inside specs is unchanged.
- The one-question-at-a-time rule for clarifying questions is unchanged.
- The hard-gate ("no implementation skills until user approves the spec") is unchanged.
- The visual companion offer flow is unchanged.

## Acceptance Criteria

The implementation is done when:

1. The checklist in `skills/brainstorming/SKILL.md` lists skill mapping (item 6) → re-investigation (item 7) → write design doc (item 8) in that order. No checklist item references mapping happening after writing.
2. The process flow graphviz block in `skills/brainstorming/SKILL.md` shows the post-approval flow as `User approves design? → Map required skills → Re-investigate → Write design doc → Spec self-review → User reviews spec?`. The post-write mapping node and its edges are gone.
3. The "After the Design" section in `skills/brainstorming/SKILL.md` contains, in order: Skill Mapping (Before Writing), Re-investigation, Documentation, Spec Self-Review, User Review Gate, Implementation.
4. The Skill Mapping subsection in `skills/brainstorming/SKILL.md` specifies that the subagent prompt MUST include (a) a structured design summary instead of a spec path, (b) the parent's verbatim skill list from its `<system-reminder>`, and (c) the instruction set. The subagent returns `{ name, why_relevant, expectations }` per matched skill and edits no files. The default-in line for `superpowers:test-driven-development` and `superpowers:verification-before-completion` is preserved.
5. The Re-investigation subsection in `skills/brainstorming/SKILL.md` contains the four-state decision table (Covered / Silent — technical only / Silent — affects flow or business logic / Contradicts), the one-sentence decision heuristic, the transparency-note rule for silent changes, and the zero-skills skip rule.
6. The Documentation subsection in `skills/brainstorming/SKILL.md` instructs that the `## Required Skills` block is written inline as part of the initial spec write using the Step 6 mapping output, and shows the unchanged block format plus the zero-skills fallback.
7. `CLAUDE.md`'s "Spec skill mapping" paragraph reflects the pre-write timing, the re-investigation step, and the technical-vs-behaviour/flow/business-logic split.
8. The phrase "after the spec passes self-review" does not appear in `CLAUDE.md` or `skills/brainstorming/SKILL.md`.
9. The phrases "Edit the spec to insert a `## Required Skills` section" and "After the subagent returns, scan its added section" do not appear in `skills/brainstorming/SKILL.md`. The phrase "prepend a `## Required Skills` block to the spec" does not appear in `CLAUDE.md`.
10. Markdown remains well-formed in both files (tables intact, code fences balanced, headings nested correctly, graphviz block parses).
11. YAML frontmatter in `skills/brainstorming/SKILL.md` is unchanged.

## Testing

This is a skill + documentation edit. Verification is by reading and grepping:

- Re-read `skills/brainstorming/SKILL.md` end-to-end after edits. Confirm: checklist order matches Acceptance Criterion 1; graphviz block matches Acceptance Criterion 2; "After the Design" subsection order matches Acceptance Criterion 3; the mapping subagent prompt takes a design summary and returns a structured response; the re-investigation four-state table is present with the one-sentence heuristic.
- Re-read `CLAUDE.md` "Spec skill mapping" paragraph. Confirm it matches the new wording.
- Grep `skills/brainstorming/SKILL.md` for `After the spec passes self-review` — expect zero matches.
- Grep `skills/brainstorming/SKILL.md` for `Edit the spec to insert` — expect zero matches.
- Grep `skills/brainstorming/SKILL.md` for `After the subagent returns, scan its added section` — expect zero matches.
- Grep `CLAUDE.md` for `after the spec passes self-review` — expect zero matches.
- Grep `CLAUDE.md` for `prepend a` — expect zero matches (or only matches unrelated to Required Skills).
- Confirm Markdown well-formedness by visual scan (tables, fences, headings).
- Confirm `skills/brainstorming/SKILL.md` YAML frontmatter (`name`, `description`) is character-identical to before the change.

No code tests are appropriate.

## Follow-up Work

None as part of this spec.
