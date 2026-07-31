# Reader-Friendly Writing for Reviewer-Facing Output

Shared rule set for any write-up a reviewer reads — the PR body produced by
`/create-pull-request`, the Phase 1 understanding summary produced by
`/review-changes`, and the reviewer zone of a design spec produced by the
`brainstorming` skill. Apply every rule below to that narrative. Each caller
adds its own specializations on top; where a caller's own instruction conflicts
with a rule here, the caller wins.

## North star — make the "why" cheap to understand

A reviewer's real bottleneck is not reading speed — it is **understanding why
the change exists**. The largest study of code review found that *understanding
the change* is the central challenge of reviewing, ahead of finding defects. So
the goal of every write-up is cheap understanding of the *why* and the
*behavioral delta*; the diff already supplies the *what*.

Scannability is the **means**, not the end. Reviewers read many changes a day
and scan to *find* the material that matters — then they read that material
carefully. Optimize so the important part is found fast **and** reads clearly.

## Order — bottom line first, riskiest first

- **Lead with BLUF (bottom line up front).** The first sentence states the
  outcome — what changes for the user or system — in imperative mood, and
  stands on its own. Then the why. Then detail. A reader who reads only the
  first line should know what the change does.
- **Why before what.** After the bottom line, give the problem, context, and
  trigger before the mechanics (inverted pyramid).
- **Order the body by scrutiny needed, not by chronology or file order.** Put
  the part that needs the most careful review first; trivial or mechanical
  changes last. Reviewer attention decays over a session — spend the freshest
  attention on the riskiest part.

## Content — behavior, not code

- **Describe behavior and flows, not classes and methods.** Say what the system
  now does differently (inputs, outputs, user-visible behavior, edge cases).
- **Don't enumerate classes/methods — but naming the *one* entry point is fine.**
  Pointing the reader at the single file or function to start reading is
  navigation, not diff-restatement. Listing every changed symbol is noise.
- **Domain vocabulary, not code identifiers.** Use the project's own terms
  precisely ("payout settlement", "funding source") — but never a class, event,
  command, or file name in the narrative. If a term exists only in code, it is
  not a domain term.
- **Never restate the diff.** Line-by-line narration of changed code is noise —
  the reviewer will read the diff.
- **No code in the narrative**, with one exception: a **minimal usage example**
  for a userland-visible / API change, showing how a reader *uses* the new
  behavior — never changed source.
- **Objective facts, no marketese.** Drop "cleanly refactored," "nicely
  handles," and similar self-praise. State plain facts.
- **Link out instead of inlining background.** Reference the ticket, design doc,
  or benchmark rather than pasting it. Keep enough inline that the write-up
  stands on its own if a link rots.
- **Reference sibling changes as links, not prose.** `#1234` and
  `owner/repo#1234` auto-expand to the title and current state, so a
  deferred-work list stays accurate as those changes land. A paragraph
  describing three follow-ups becomes three lines.
- **Point at code, don't paste it.** A commit permalink with a line range
  (`.../blob/<sha>/path/to/file#L10-L24`) renders as an embedded snippet, stays
  anchored to a commit, and costs no body length.

## Scannability — shape it for a skimmer, then a reader

- **Front-load the information-carrying word.** Scanners reliably see only the
  first ~2 words of a bullet or heading. Put the meaning there.
- **Keep sentences short.** Aim for ≤20 words on average; split anything past
  ~40. One idea per sentence.
- **One idea per paragraph, ≤3–4 lines.** No walls of text.
- **Bullets for enumerable items — but chunk them.** Group related bullets under
  a labelled heading and keep any one ungrouped list to ~5–7 items. Working
  memory holds only a handful of chunks; a long flat list is as fatiguing as
  prose.
- **Literal headings.** Descriptive signposts ("Migration steps," "Risk /
  rollback"), never clever or vague ones.
- **Bold sparingly.** Highlight only the few load-bearing terms a reviewer must
  not miss (a breaking change, a flag, an affected service). Over-bolding erases
  the signal.
- **Run a "so what?" pass.** Cut any sentence that neither aids understanding of
  *why* nor directs the reviewer's attention. Noise sentences add fatigue for
  zero decision value.

## Progressive disclosure — essentials up top, detail on demand

- Keep the default view to the essentials. Move logs, long examples, migration
  notes, and alternatives-considered behind collapsible `<details>` /
  `<summary>` blocks so the reviewer expands them only when relevant.

## Predictable structure — same shape every time

- Use the same section order on every write-up so a daily reader can navigate on
  autopilot. Consistency is itself a load-reducer; the exact section list is the
  calling command's choice.

## Visuals — include one by default

- **Default to a visual.** Include one unless the change is a **single linear
  step**, or is pure text/config with **no structural element** at all. This is
  the reverse of "earn its place" — the burden is on omitting a visual, not on
  including one.
- **A visual that replaces a paragraph is a net reduction.** Prefer the visual
  to the prose it displaces; that is the point of using it.
- **Match the type to the change:**

  | The change is about | Use |
  |---|---|
  | States and transitions | `stateDiagram-v2` |
  | Multiple participants exchanging messages | `sequenceDiagram` |
  | Dependencies between packages or services | `graph LR` |
  | An ordered pipeline or flow | `graph TD` |
  | A behavior swap with no ordering | before/after table |

- **Diagram or table, never both.** They carry the same delta; two visuals of
  one change is duplication, and the budget below allows one visual.
- **Before/after tables: at most ~4 rows, and every row states a behavior.** A
  table whose rows are symbol renames is an inventory in a nicer wrapper — the
  exact failure this replaced.
- **Keep diagrams small:** ≤10–15 nodes, one idea per diagram; if it needs more
  than ~20, split it or drop it. An oversized diagram costs more attention than
  the prose it replaced.
- **Prefer diffable text-based diagrams (Mermaid)** so the diagram is itself
  reviewable. Whether to show the resulting flow alone or a before/after pair is
  the calling command's choice — see that command.
- **Before/after screenshots** (with alt text) for any UI or user-visible output
  change — the diff can't show the result.

## Highlighting — one shared attention budget

GitHub renders five alert types as coloured callouts. Use one for the single
fact a reviewer must not miss — a flag gate, a breaking change, a required
deploy ordering:

````
> [!IMPORTANT]
> Inert until the feature flag is enabled. Nothing dispatches this yet.
````

`[!NOTE]` / `[!TIP]` / `[!IMPORTANT]` / `[!WARNING]` / `[!CAUTION]` are the five
available.

**Alerts, bold, tables, diagrams and `<details>` all draw on one attention
budget.** Per write-up, at most:

- **1 alert** — a second one halves the first one's signal
- **1 visual** — diagram *or* table, not both
- **3 bolded terms**

Over budget? **Cut the weakest device, don't reflow it.** A write-up using every
available device highlights nothing.

## Point the reader

- Tell the reviewer **where to look** — the most important area first — and flag
  known shortcomings honestly.

## Trim pass — run before showing anyone

A rule that isn't a step doesn't run. Callers invoke this as an explicit step,
and fix every failure before the reader sees the draft.

- [ ] Does the first sentence state the outcome, and stand alone?
- [ ] Zero code identifiers in the narrative — no class, event, command, or file
      names?
- [ ] Is a visual present, or is its absence justified by single-linear-step /
      no-structure?
- [ ] Does every sentence aid the *why* or direct attention? Cut the rest.
- [ ] Is verification evidence out of the narrative, confined to a test-plan
      section where the template has one?
- [ ] Within the highlighting budget — ≤1 alert, ≤1 visual, ≤3 bolded terms?
- [ ] Is long detail behind `<details>` rather than inline?

## Anti-patterns (each raises reader load)

- Burying the bottom line below context or setup.
- Pasting code that duplicates the diff.
- Enumerating changed classes/methods instead of describing behavior.
- Vague summaries ("Fix bug," "Phase 1," "Moving code A→B").
- Walls of text — or walls of ungrouped bullets.
- Clever or vague headings.
- Marketese / self-praise.
- No visual where states, participants, or ordering are the essence.
- An oversized diagram, or both a diagram and a table for one change.
- A before/after table whose rows are symbol names rather than behaviors.
- Over-bolding.
- Inconsistent structure across write-ups, forcing the reader to re-learn the
  shape every time.
- Two or more highlighting devices competing for the same attention.

## Sources

- Microsoft — Modern Code Review (Bacchelli & Bird, ICSE 2013), on
  understanding as the core review challenge:
  https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/ICSE202013-codereview.pdf
- Google eng-practices — CL descriptions:
  https://google.github.io/eng-practices/review/developer/cl-descriptions.html
- Google eng-practices — What to look for in a review:
  https://google.github.io/eng-practices/review/reviewer/looking-for.html
- BLUF (bottom line up front):
  https://en.wikipedia.org/wiki/BLUF_(communication)
- Nielsen Norman Group — How Users Read on the Web:
  https://www.nngroup.com/articles/how-users-read-on-the-web/
- Nielsen Norman Group — First 2 Words: A Signal for Scanning:
  https://www.nngroup.com/articles/first-2-words-a-signal-for-scanning/
- Nielsen Norman Group — F-Shaped Pattern of Reading:
  https://www.nngroup.com/articles/f-shaped-pattern-reading-web-content-discovered/
- Readability Guidelines — sentence length:
  http://readabilityguidelines.wikidot.com/sentence-length
- Laws of UX — Miller's Law (working-memory chunking):
  https://lawsofux.com/millers-law/
- Primer — Progressive disclosure:
  https://primer.github.io/design/ui-patterns/progressive-disclosure/
- Mermaid Chart — flowchart complexity / sizing:
  https://docs.mermaidchart.com/blog/posts/flow-charts-are-on2-complex-so-dont-go-over-100-connections
- GitHub Docs — Helping others review your changes:
  https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/getting-started/helping-others-review-your-changes
- Pragmatic Engineer — Pull request / diff best practices:
  https://blog.pragmaticengineer.com/pull-request-or-diff-best-practices/
- GitHub Docs — Basic writing and formatting syntax (alerts):
  https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#alerts
- GitHub Docs — Creating a permanent link to a code snippet:
  https://docs.github.com/en/repositories/working-with-files/using-files/getting-permanent-links-to-files
- GitHub Docs — Autolinked references and URLs:
  https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/autolinked-references-and-urls
