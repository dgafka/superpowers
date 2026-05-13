# TDD Fast Inner Loop

## Required Skills

> Before starting implementation, invoke each skill in **Required Skills** via the Skill tool.

- **superpowers:writing-skills** — the entire spec is an edit to a skill file (`skills/test-driven-development/SKILL.md`); this skill governs how to edit skill files correctly.
- **superpowers:verification-before-completion** — acceptance requires re-reading the resulting `SKILL.md` end-to-end to confirm internal consistency, well-formed Markdown, unchanged frontmatter, and no orphan references — exactly the evidence-before-assertion check this skill enforces.

## Problem

Two issues with the current `test-driven-development` skill:

1. **Wide inner loop.** After each GREEN step, the skill instructs the implementer to verify "other tests still pass," which drives suite-wide runs after every red-green-refactor cycle. On real projects the suite is slow enough that this dominates iteration cost.
2. **Persuasion-heavy framing.** The skill contains long anti-rationalization sections (`Why Order Matters`, `Common Rationalizations`, `Red Flags - STOP and Start Over`) that argue against bad behavior rather than specify desired behavior. The AI implementer does not need to be convinced; it needs to be told what to do.

A third, smaller issue: the skill negatively frames the preferred testing tactic as "no mocks unless unavoidable" rather than naming the positive position.

## Decision

Edit `skills/test-driven-development/SKILL.md` in place. Three changes in one pass:

1. **Tighten the inner loop.** The implementer runs only the test they just wrote during RED, GREEN, and REFACTOR. Suite-wide regression is deferred to `verification-before-completion`.
2. **Reframe testing tactic.** Remove all "mock"-language and label the preferred tactic positively: **Detroit/Chicago School TDD** (real collaborators, state-based assertions).
3. **Strip persuasion content.** Remove sections that try to argue the AI out of bad behavior. Keep only specificational content: what to do, when, and how to recognize completion.

The cycle-speed tradeoff is accepted explicitly: regressions in code outside the new test's scope will not surface until completion-time. That is the deal.

## Scope

- **In scope:** edits to `skills/test-driven-development/SKILL.md` only.
- **Out of scope:** edits to any other skill, including `verification-before-completion`, `using-superpowers`, and `writing-skills`. See **Follow-up Work** at the end for skills that need a similar persuasion-strip in a future spec.
- **Out of scope:** new files, new sections beyond those listed below, or restructuring of existing material that isn't directly relevant.
- **Out of scope:** the `testing-anti-patterns.md` companion file.

## Implementation note on voice

The upstream skill design uses long persuasive blocks to "bulletproof against rationalization." This spec explicitly rejects that approach for the TDD skill. The implementer must **not** preserve persuasive wording out of deference to the upstream voice — the persuasive content is what's being removed. Preserve declarative wording (the Iron Law, process steps, the Final Rule); remove argumentative wording.

## Changes to `skills/test-driven-development/SKILL.md`

### Change 1 — Tighten "Verify RED"

The current "Verify RED" section shows running a single test file (`vendor/bin/phpunit tests/Path/SomeTest.php`). Tighten further: target the single new test method.

- Update the example command to a single-test filter (e.g., `vendor/bin/phpunit --filter testMethodName tests/Path/SomeTest.php`).
- Add one sentence above the command: *"Run only the test you just wrote. Not the file, not the suite — just this test method."*
- Leave the existing "Confirm:" bullet list and "Test passes? / Test errors?" follow-up untouched.

### Change 2 — Surgical edit to "Verify GREEN"

- In the **Confirm:** bullet list under "Verify GREEN", **remove** `- Other tests still pass`.
- Keep the remaining bullets: `Test passes` and `Output pristine (no errors, warnings)`.
- Update the example command to a single-test filter (same form as Verify RED).
- Add one sentence above the command: *"Run only the test you just wrote. Not the file, not the suite."*
- Remove the `**Other tests fail?** Fix now.` line at the bottom of the section — it presupposes the deleted check.

### Change 3 — New "Inner Loop Scope" section

Insert a new section `## Inner Loop Scope` immediately after `## Red-Green-Refactor` (before `## Good Tests`).

Content (keep specificational, no persuasion):

- The rule: during RED → GREEN → REFACTOR for a single cycle, run **only** the test you're driving. No other tests. No suite.
- Where the suite **is** run: `verification-before-completion` owns full-suite verification before commit / PR.
- One concrete command example using a PHPUnit single-test filter. One line noting the same pattern applies to other runners (`pytest -k`, `jest -t`, `go test -run`, etc.) — do not enumerate exhaustively.

Half a screen at most. Do **not** include a "why this matters" paragraph or rationale block — the rule stands on its own.

### Change 4 — Disambiguate "Verification Checklist"

The current checklist contains `- [ ] All tests pass`. Replace with two specific items:

- `- [ ] Your new test passes (inner loop)`
- `- [ ] Full suite verified separately via verification-before-completion`

Leave every other checklist item untouched.

### Change 5 — Reframe testing tactic as Detroit/Chicago School

Remove every mention of "mock", "mocks", and "mocking" from `SKILL.md`. Label the preferred tactic positively as **Detroit/Chicago School** (real collaborators, state-based assertions).

Specific edits:

a) **RED — Write Failing Test, lead-in.** Add one sentence at the very top of the section (before "Write one minimal test showing what should happen."): *"Default to **Detroit/Chicago School TDD**: real collaborators, assertions on observable state — not on interactions."*

b) **RED, "Good test" paragraph.** Currently: "the body drives the real implementation through real code without mocks; and the assertions check what the code returned, not what intermediate steps were called." Reframe to: "the body drives the real implementation through real collaborators (Detroit/Chicago School); and the assertions check what the code returned or the observable state, not what intermediate steps were called."

c) **RED, "Bad test" paragraph.** Currently: "heavy mock setup that pre-arranges the answer; assertions on the mock's interaction count rather than the result. You're testing the mock, not the code." Reframe to: "heavy test-double setup that pre-arranges the answer; assertions on interactions between collaborators rather than the result. You're testing your test scaffold, not the code."

d) **RED, Requirements bullet list.** Replace `- Real code (no mocks unless unavoidable)` with `- Detroit/Chicago School: real collaborators, state-based assertions`.

e) **Verification Checklist.** Replace `- [ ] Tests use real code (mocks only if unavoidable)` with `- [ ] Tests follow Detroit/Chicago School (real collaborators, state-based)`.

f) **When Stuck table.** Replace the row `Must mock everything | Code too coupled. Use dependency injection.` with `Hard to test without faking every collaborator | Code too coupled. Use dependency injection or test at a higher boundary.`

g) **Testing Anti-Patterns section.** Replace the lead-in `When adding mocks or test utilities, read @testing-anti-patterns.md to avoid common pitfalls:` with `If you must reach for test doubles (rare under Detroit/Chicago School), read @testing-anti-patterns.md to avoid common pitfalls:`. Also rephrase the bullets that use mock-language:
   - `Testing mock behavior instead of real behavior` → `Testing test-double behavior instead of real behavior`
   - `Mocking without understanding dependencies` → `Substituting collaborators without understanding what they do`
   - Leave `Adding test-only methods to production classes` unchanged.

Do not edit `testing-anti-patterns.md`. The cross-reference still works because the companion file still covers test-double pitfalls.

### Change 6 — Strip persuasion content

The TDD skill currently contains substantial content that argues against bad behavior rather than specifies desired behavior. Remove it.

**Sections to remove entirely:**

- `## Why Order Matters` (the four "I'll write tests after..." / "I already manually tested..." / "Deleting X hours of work is wasteful" / "TDD is dogmatic..." / "Tests after achieve the same goals" blocks).
- `## Common Rationalizations` (the entire table).
- `## Red Flags - STOP and Start Over` (the entire bulleted list, including the "All of these mean: Delete code. Start over with TDD." trailing line).

**Lines / sub-blocks to remove inside surviving sections:**

- In `## When to Use`: remove the line *"Thinking 'skip TDD just this once'? Stop. That's rationalization."*
- In `## The Iron Law`: remove the `**No exceptions:**` bullet block (`Don't keep it as "reference"` / `Don't "adapt" it...` / `Don't look at it` / `Delete means delete`) and the trailing line *"Implement fresh from tests. Period."*

**Sections / lines to keep:**

- The Iron Law's opening — the bold rule and the directive "Write code before the test? Delete it. Start over." — stays. That is specification, not persuasion.
- All process sections (RED, Verify RED, GREEN, Verify GREEN, REFACTOR, Repeat) stay.
- The `Good Tests` table stays — it describes good vs. bad, it does not argue against rationalizations.
- `Example: Bug Fix`, `Verification Checklist`, `When Stuck`, `Debugging Integration`, `Testing Anti-Patterns`, `Final Rule` — all stay.

After this change the skill becomes substantially shorter. That is the goal.

## Non-changes (explicit)

The following must not be touched:

- The Red-Green-Refactor flowchart (graphviz block).
- The `Example: Bug Fix` section (already uses single-test runs).
- The `Debugging Integration` and `Final Rule` sections.
- The `testing-anti-patterns.md` companion file.
- Any other skill in the repo (see Follow-up Work).

`When Stuck` and `Testing Anti-Patterns` are in scope **only** for the limited surgery in Change 5. `The Iron Law` and `When to Use` are in scope **only** for the limited removal in Change 6. No other edits to those sections.

If implementation appears to require touching anything outside this list, stop and surface the conflict — do not silently expand scope.

## Acceptance Criteria

The implementation is done when:

1. `skills/test-driven-development/SKILL.md` reflects all six changes above, and no others.
2. The `Other tests still pass` bullet and the `Other tests fail? Fix now.` line are gone from "Verify GREEN".
3. A new `## Inner Loop Scope` section exists between `## Red-Green-Refactor` and `## Good Tests` and contains: the rule, the pointer to `verification-before-completion`, and one command example. It does **not** contain a "why" paragraph or tradeoff statement.
4. The verification checklist replaces `All tests pass` with the two new items.
5. The file contains zero matches for "mock", "mocks", or "mocking" (case-insensitive). Testing tactic is framed as Detroit/Chicago School with a one-sentence definition in the RED lead-in.
6. The following are deleted: `## Why Order Matters`, `## Common Rationalizations`, `## Red Flags - STOP and Start Over`. The Iron Law's `**No exceptions:**` block and "Implement fresh from tests. Period." are deleted. The "skip TDD just this once" line in `## When to Use` is deleted.
7. The file still reads as one coherent skill — no orphaned references to removed sections, no broken cross-references, no dangling pronouns or section pointers.
8. The YAML frontmatter (`name`, `description`) is unchanged.
9. Markdown remains well-formed (tables intact, code fences balanced, headings nested correctly).

## Testing

This is a skill-file edit. Verification is by reading the resulting `SKILL.md`:

- Re-read the full file end-to-end after edits. Confirm internal consistency: no section references the removed inner-loop check, the deleted persuasion sections, or the removed mock terminology.
- Confirm Markdown well-formedness.
- Confirm YAML frontmatter unchanged.
- Grep the file for `mock` (case-insensitive). Expect zero matches.
- Grep the file for `Why Order Matters`, `Common Rationalizations`, `Red Flags - STOP`. Expect zero matches.

No code tests are appropriate.

## Follow-up Work

The same persuasion-stripping principle applies to other skills in the repo. A **separate spec** will handle these in a future pass:

- **`skills/verification-before-completion/SKILL.md`** — has `## Red Flags - STOP`, `## Rationalization Prevention` table, `## Why This Matters` section.
- **`skills/using-superpowers/SKILL.md`** — has `## Red Flags` table ("These thoughts mean STOP—you're rationalizing"), the "you cannot rationalize your way out of this" line, and rationalization-style framing inside the flow.

The follow-up work is **not** part of this spec. List included so the audit is on record.

**`skills/writing-skills/SKILL.md` is explicitly OUT of scope** — both for this spec and for the future cross-skill cleanup. Decision: leave it untouched.
