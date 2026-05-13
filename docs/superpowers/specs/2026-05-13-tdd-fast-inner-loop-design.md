# TDD Fast Inner Loop

## Required Skills

> Before starting implementation, invoke each skill in **Required Skills** via the Skill tool.

- **superpowers:writing-skills** — the entire spec is an edit to a skill file (`skills/test-driven-development/SKILL.md`); this skill governs how to edit skill files correctly while preserving tuned wording.
- **superpowers:verification-before-completion** — acceptance requires re-reading the resulting `SKILL.md` end-to-end to confirm internal consistency, well-formed Markdown, unchanged frontmatter, and no orphan references — exactly the evidence-before-assertion check this skill enforces.

## Problem

The current `test-driven-development` skill instructs that, after each GREEN step, the implementer must verify the new test passes **and** that other tests still pass. In practice this drives implementers to run the full suite (or a wide subset) after every red-green-refactor cycle. On real projects the suite takes long enough that this dominates the iteration cost, slowing feedback far more than the regression-catching value justifies at this granularity.

We want the red-green-refactor inner loop to be as tight as possible: write a focused test, run only that test, write minimal code, run only that test, refactor, run only that test. Suite-wide regression detection moves entirely to the existing `verification-before-completion` skill, which already runs before commit/PR.

## Decision

Edit `skills/test-driven-development/SKILL.md` in place. The inner loop runs only the test the implementer just wrote — never the file, never the suite. Suite-wide checks are explicitly deferred to `verification-before-completion`.

The tradeoff is accepted explicitly: regressions in code outside the new test's scope will not surface until completion-time. The cycle speed gain is the priority.

## Scope

- **In scope:** edits to `skills/test-driven-development/SKILL.md` only.
- **Out of scope:** edits to `verification-before-completion`, `executing-specs`, or any other skill. No cross-skill changes in this pass.
- **Out of scope:** new files, new sections beyond those listed below, or restructuring of existing material that isn't directly relevant.

## Changes to `skills/test-driven-development/SKILL.md`

The edits below are targeted. Each one identifies the current text and the replacement intent. The implementer must preserve the existing voice, table format, and section headings of the file — this skill's behavior-shaping wording is deliberately tuned and must not be paraphrased away.

### Change 1 — Tighten "Verify RED"

The current "Verify RED" section shows running a single test file (`vendor/bin/phpunit tests/Path/SomeTest.php`). Tighten further: the run must target the single new test method, not the whole file.

- Update the example command to use a single-test filter (e.g., `vendor/bin/phpunit --filter testMethodName tests/Path/SomeTest.php`).
- Add one sentence above the command making the scope explicit: *"Run only the test you just wrote. Not the file, not the suite — just this test method."*
- Leave the existing "Confirm:" bullet list and surrounding rationale untouched.

### Change 2 — Surgical edit to "Verify GREEN"

This is the core change.

- In the **Confirm:** bullet list under "Verify GREEN", **remove** the bullet `- Other tests still pass`.
- Keep the remaining bullets: `Test passes` and `Output pristine (no errors, warnings)`.
- Update the example command in this section to the same single-test filter form used in Verify RED.
- Add one sentence above the command matching Verify RED: *"Run only the test you just wrote. Not the file, not the suite."*
- The "**Other tests fail?** Fix now." line at the bottom of the section must also be removed — it presupposes the deleted check.

### Change 3 — New "Inner Loop Scope" section

Insert a new section titled `## Inner Loop Scope` immediately after the `## Red-Green-Refactor` section (before `## Good Tests`).

Content requirements:

- State the rule plainly: during RED → GREEN → REFACTOR for a single cycle, run **only** the test you're driving. No other tests. No suite.
- Explain the why in one short paragraph: the inner loop runs many times per task; sub-second feedback compounds. Broader runs at this granularity dominate cost without proportional value.
- Name the tradeoff explicitly in one sentence: regressions outside the new test's scope will not surface until completion-time. That is the deal.
- Point to where the suite **is** run: `verification-before-completion` owns full-suite verification before commit / PR.
- Show one concrete command example (PHPUnit single-test filter, matching the existing skill's tooling). Follow it with a one-line note that the same pattern applies to other runners — `pytest -k`, `jest -t`, `go test -run`, etc. Do not enumerate exhaustively.

Keep the section short. The skill is already long; this section should be a half-screen at most.

### Change 4 — Add a row to "Common Rationalizations"

Append one row to the existing `## Common Rationalizations` table:

| "But what if I broke something else?" | Defer. Full suite runs once via `verification-before-completion`. Inner loop stays tight. |

Do not alter the surrounding rows.

### Change 5 — Add a row to "Red Flags - STOP and Start Over"

The existing "Red Flags" list is bulleted, not tabular. Append one bullet matching the existing style:

- "Let me just run the suite to be safe" (during the inner loop)

Place it near the bottom of the existing list, just before the final summary line. Do not reorder existing bullets.

### Change 6 — Disambiguate "Verification Checklist"

The current checklist contains `- [ ] All tests pass`. Replace it with two more specific items that match the new model:

- `- [ ] Your new test passes (inner loop)`
- `- [ ] Full suite verified separately via verification-before-completion`

Leave every other checklist item untouched.

### Change 7 — Reframe testing tactic as Detroit/Chicago School

Remove every mention of "mock", "mocks", and "mocking" from `SKILL.md`, and reframe the preferred testing tactic positively as **Detroit/Chicago School** (real collaborators, state-based assertions). This is a labeling change, not a stance change — the existing stance ("no mocks unless unavoidable") is the Detroit/Chicago position. We're naming it correctly and removing the negative framing.

Quick definition the implementer should use (one sentence, not a section):

> Detroit/Chicago School TDD: drive code through real collaborators, assert on observable state or return values, not on interactions between units.

Specific edits, all inside `skills/test-driven-development/SKILL.md`:

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

Do **not** edit the `testing-anti-patterns.md` companion file. Internal references to it stay valid because the file still exists and still covers test-double pitfalls — only the entry point in `SKILL.md` is being reframed.

## Non-changes (explicit)

The following are **not** part of this spec and must not be touched:

- The Iron Law section.
- The Red-Green-Refactor flowchart (graphviz).
- The "Why Order Matters" section.
- The "Example: Bug Fix" section (already uses single-test runs, no change needed).
- The "Debugging Integration" and "Final Rule" sections.
- The `testing-anti-patterns.md` companion file.
- Any other skill in the repo.

(Note: `When Stuck` and `Testing Anti-Patterns` sections are **in scope** under Change 7 for the limited surgery described there. No other edits to those sections are permitted.)

If during implementation an edit appears to require touching one of these, stop and surface the conflict — do not silently expand scope.

## Acceptance Criteria

The implementation is done when:

1. `skills/test-driven-development/SKILL.md` reflects all seven changes above, and no others.
2. The `Other tests still pass` bullet and the `Other tests fail? Fix now.` line are gone from "Verify GREEN".
3. A new `## Inner Loop Scope` section exists, placed between `## Red-Green-Refactor` and `## Good Tests`, and contains: the rule, the why, the tradeoff sentence, the pointer to `verification-before-completion`, and one concrete command example.
4. The two new entries (one rationalization row, one red-flag bullet) exist in their respective lists, with no reordering of existing entries.
5. The verification checklist replaces `All tests pass` with the two new items.
6. The file still reads as one coherent skill in the existing voice — no orphaned references to "other tests" or "full suite" inside the inner-loop sections.
7. No reference to "mock", "mocks", or "mocking" remains anywhere in `SKILL.md`. The preferred testing tactic is framed as Detroit/Chicago School, with a one-sentence definition in the RED section lead-in.

## Testing

This is a skill-file edit. Verification is by reading the resulting `SKILL.md`:

- Re-read the full file end-to-end after edits. Confirm internal consistency: no section references the removed "other tests still pass" check, and no section contradicts the new "Inner Loop Scope" rule.
- Confirm the file still parses as well-formed Markdown (tables intact, code fences balanced, headings nested correctly).
- Confirm the YAML frontmatter (`name`, `description`) is unchanged.
- Grep the file for `mock` (case-insensitive). Expect zero matches under Change 7.

No code tests are appropriate for this change.
