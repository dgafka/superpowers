# Reader-Friendly Writing for Reviewer-Facing Output

Shared rule set for any write-up a reviewer reads — the PR body produced by
`/create-pull-request` and the Phase 1 understanding summary produced by
`/review-changes`. Apply every rule below to that narrative. Each command adds
its own specializations on top; where a command's own instruction conflicts
with a rule here, the command wins.

## Core premise

Reviewers read many changes a day. **They scan; they don't read.** Eye-tracking
studies find most readers scan and read only a fraction of the words on a
screen. Every rule here exists to lower reading effort so the review feels
effortless — restful, fast to skim, easy to act on. Concise + scannable +
objective prose measures dramatically higher usability than default prose.

## Order — lead with why

- **Why before what.** Open with the problem, context, or goal (inverted
  pyramid), then the change. The diff shows *what* changed; prose exists to
  supply the *why* the diff cannot.
- **Self-contained lead line.** The first line states what the change achieves,
  in imperative mood, and makes sense on its own — a reader who reads only that
  line should know what the change does.

## Content — behavior, not code

- **Describe behavior and flows, not classes and methods.** Say what the system
  now does differently (inputs, outputs, user-visible behavior, edge cases),
  never "added method X to class Y."
- **Never restate the diff.** Line-by-line narration of the changed code is pure
  noise — the reviewer will read the diff.
- **No code in the narrative.** No diff, implementation, or mechanism code, and
  no class/method names. The one exception: a **minimal usage example** for a
  userland-visible / API change, showing how a reader *uses* the new behavior —
  never changed source.
- **Objective facts, no marketese.** Drop promotional and hedging language
  ("cleanly refactored," "nicely handles"). State plain facts.
- **Link out instead of inlining background.** Reference the ticket, design doc,
  or benchmark rather than pasting it. Keep enough inline that the write-up
  stands on its own if a link rots.

## Scannability — shape it for a skimmer

- **Cut words hard.** Prefer the shortest phrasing that keeps the meaning.
- **One idea per bullet or paragraph.** Never compress a problem, its scope, and
  its consequence into one sentence — split them.
- **Bullets for anything enumerable.** Steps, affected areas, test cases — lists
  are the single most scannable structure.
- **Front-load the key word.** Readers scan the start of each line and the left
  margin; put the most important word first.
- **Literal headings.** Descriptive signposts ("Migration steps," "Risk /
  rollback"), never clever or vague ones.
- **Bold sparingly.** Highlight only the few load-bearing terms a reviewer must
  not miss (a breaking change, a flag, an affected service). Over-bolding erases
  the signal.

## Visuals — a diagram only when it earns its place

- Use a diagram **only when order, parallelism, or multiple participants is the
  essence of the change** (auth flows, state machines, service interactions) —
  it communicates faster than prose there. Skip it for linear steps or a simple
  list; a diagram of linear logic is noise.
- Prefer diffable text-based diagrams (Mermaid) so the diagram is itself
  reviewable. Whether to show the resulting flow alone or a before/after pair is
  the calling command's choice — see that command.

## Point the reader

- Tell the reviewer **where to look** — the most important area first — and what
  kind of feedback is wanted. Flag known shortcomings honestly.

## Anti-patterns (each raises reader load)

- Pasting code that duplicates the diff.
- Class/method-level narration instead of behavior.
- Vague summaries ("Fix bug," "Phase 1," "Moving code A→B").
- Walls of text / long paragraphs.
- Clever or vague headings.
- Marketese / self-praise.
- A diagram for simple or linear logic.
- Over-bolding.

## Sources

- Google eng-practices — CL descriptions:
  https://google.github.io/eng-practices/review/developer/cl-descriptions.html
- Google eng-practices — Small CLs:
  https://google.github.io/eng-practices/review/developer/small-cls.html
- Nielsen Norman Group — How Users Read on the Web:
  https://www.nngroup.com/articles/how-users-read-on-the-web/
- Nielsen Norman Group — F-Shaped Pattern of Reading:
  https://www.nngroup.com/articles/f-shaped-pattern-reading-web-content/
- GitHub Docs — Helping others review your changes:
  https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/getting-started/helping-others-review-your-changes
- Pragmatic Engineer — Pull request / diff best practices:
  https://blog.pragmaticengineer.com/pull-request-or-diff-best-practices/
