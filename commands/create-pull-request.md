---
name: create-pull-request
allowed-tools: Bash(gh pr create:*), Bash(gh pr list:*), Bash(gh pr view:*), Bash(gh pr checks:*), Bash(gh pr comment:*), Bash(gh run view:*), Bash(gh api:*), Bash(git log:*), Bash(git diff:*), Bash(git status:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(git push:*), Bash(git add:*), Bash(git commit:*), Bash(git remote:*)
disable-model-invocation: false
description: >-
  Create a pull request for the current branch, detecting the repo's own
  conventions and PR template rather than assuming any project's rules.
  Use when the user asks to create a PR, open a PR, push the current branch
  as a pull request, or invokes /create-pull-request.
---

Create a pull request for the current branch. Every repo-specific detail —
title style, ticket references, template sections — comes from **detection,
the repo's own PR template, or asking the user**. Never hardcode a
project's conventions (ticket prefixes, service tags, labels, mandatory
decorations, a specific language).

## Reader-Friendly Output

Before composing the body, read `commands/references/reader-friendly-writing.md`
and apply its rule set to everything a reviewer will read. Reviewers scan many
PRs a day — the body should be why-first, behavior-level, scannable, and free of
code they can already see in the diff. The specializations in Steps 4–6 below
build on that shared rule set.

## Process

### 1. Gather Context

Run these in parallel:

- `git branch --show-current` — current branch
- `git status` — uncommitted changes
- Detect the default branch: `git symbolic-ref refs/remotes/origin/HEAD`
  (strip to the branch name, e.g. `origin/main` → `main`). If that fails,
  probe for `main`, then `master`. **Never assume `main`.** Call the result
  `<base>` for every command below.
- `git log <base>..HEAD --oneline` — commits on this branch
- `git diff <base>...HEAD --stat` — changed-files summary
- `git diff <base>...HEAD` — full diff
- `git remote get-url origin` — repository identity

**Guards:**

- If the current branch **is** `<base>` (the default branch) — stop and
  tell the user they need to be on a feature branch first.
- If there are uncommitted changes — warn the user and ask whether to
  proceed without them.

### 2. Detect Conventions & Template

- Look for a PR template, in order: `.github/PULL_REQUEST_TEMPLATE.md`,
  a template at the repo root, `docs/`, and the multi-template directory
  `.github/PULL_REQUEST_TEMPLATE/`. If found, this template governs the
  body structure in Step 6 — fill every section it defines.
- Infer the **title convention** from recent merged PRs
  (`gh pr list --state merged --limit 20`) and/or `git log`: conventional
  commits (`feat:`, `fix:`, …), ticket-prefixed (`[TICKET-123]`), or plain
  descriptive titles.
- Detect a **ticket reference** from the branch name generically (a
  pattern like `[A-Z]+-\d+`).
- **Ask the user only when detection is ambiguous** — don't guess a
  convention from a single data point.
- **Ticket-prompt rule:** if recent merged PR titles show ticket-labelled
  titles are the norm for this repo, and no ticket reference can be found
  in the branch name or session context, **ask the user for the ticket
  number** (accepting "none" to proceed without one). If ticket-labelled
  titles are clearly not the norm, don't ask.

### 3. Classify the Change

Determine the PR's type and intent from the diff and session context.
Pick the single best-fitting category:

- Refactor / internal cleanup
- Bug fix
- New feature
- Flow / state / pipeline change (or a capability that enables flow
  changes)
- Userland-visible behavior / API change
- Config / docs / tooling

This classification drives which explanatory aids are used in Step 5 —
don't skip it, and don't let it be an afterthought bolted on after the
body is drafted.

### 4. Extract Motivation

- Draw the "why" from the **current session's context first** — what was
  the user working on, what problem prompted it, what approach did they
  take and why. Fall back to the diff itself when the session doesn't
  make the motivation clear.
- If the motivation is still unclear, ask the user directly:
  > What problem does this PR solve, and why is this change needed now?
- Optionally add an attribution line listing skills invoked this session
  (e.g. `_Drafted with /skill-a, /skill-b._`) — include it only when at
  least one skill was actually invoked. Omit it otherwise; don't pad it.

Apply this motivation discipline when writing the why:

- **WHY, not WHAT.** The diff already shows what changed — don't restate
  it in the motivation.
- **Role-first.** State the problem as a plain declarative sentence where
  the subject IS the thing playing the wrong role and the predicate IS
  the mismatch. If your first sentence needs a setup clause before it
  makes sense, it isn't role-first yet.
- **One idea per sentence.** Don't compress a problem, its scope, and its
  consequence into one sentence — split them, and drop the ones that
  aren't motivation (see below).
- **Exact domain terms.** Use the project's own vocabulary precisely; a
  near-synonym signals shaky understanding of the problem.
- **Scope and counts are evidence, not motivation.** "7 of 9 places have
  this problem" belongs in a comment or dev note, not the motivation.
- **Mechanism belongs in inline review comments**, not the PR body. If
  you're explaining how something evaluates internally, stop — that's
  implementation detail.
- **No code snippets in the motivation.** The reviewer can read the diff.
- **Front-load every sentence and bullet.** Put the most important word first
  — readers scan line-starts, not line-ends.
- **Objective facts, no marketese.** Drop "cleanly refactored," "nicely
  handles," and similar self-praise; state plain facts.
- **Keep it short.** 2–5 sentences or bullet points. No novels.

### 5. Select Explanatory Aids From the Classification

Match aids to the change's intent from Step 3. Add nothing that doesn't
earn its place — a refactor gets none of these; a flow change gets a
diagram; a userland-visible change gets an example.

| Change type | Mermaid (after-only) | Usage example | Motivation emphasis |
|---|---|---|---|
| Refactor / internal cleanup | no | no | the role/design mismatch being fixed |
| Bug fix | no | only if usage-affecting | the incorrect behavior and why it was wrong |
| New feature | if it introduces a flow | if userland-visible | what the feature enables |
| Flow / state / pipeline change | **yes** | if userland-visible | what the new flow achieves |
| Userland-visible behavior / API | if flow-related | **yes** | what changes for users |
| Config / docs / tooling | no | no | why the change is needed |

- **Mermaid diagrams are after-only.** Show the resulting flow, not a
  before/after pair — the diff already conveys the prior state, and a
  before diagram is noise. Produce one **only when order, parallelism, or
  multiple participants is the essence of the change** — a diagram of
  linear steps is noise, so skip it. Format:

  ````
  ```mermaid
  graph TD
      A[Step 1] --> B[Step 2]
  ```
  ````

- **A minimal usage example** — copy-pasteable, in the repository's own
  language — shows how a user *interacts* with a userland-visible / API
  change, so a reader gets a feel for it without reading the diff. Show
  usage only; never paste changed source. Name the public interface a user
  calls, but don't enumerate internal classes or methods. Include it only
  for userland-visible / API changes.

### 6. Compose the PR

**Title:**

- Goal-oriented — state what the PR achieves, not what code it changes.
  Test: if the title would still make sense with a different
  implementation underneath, it's goal-oriented; if not, rewrite it.
- Imperative mood ("Add", "Fix", "Update" — not "Added", "Fixes").
- Follow the convention detected in Step 2 (conventional-commit prefix,
  ticket prefix, or plain), including a ticket reference where the
  ticket-prompt rule applies.

**Body:**

- **If a PR template was found in Step 2** — fill every section it
  defines, honoring its inline comments and checkboxes. Never invent
  extra top-level sections and never leave one of its sections blank.
  Apply the reader-friendly rules *within* each section — even where a
  section asks "what changed," answer at the level of behavior and flows,
  in scannable bullets, not a class/method list. Place the explanatory
  aids from Step 5 in whichever existing section fits best (e.g. a
  "Description" or "Changes" section).
- **If no template was found** — use this default structure:

  ```
  ## Why

  <2-5 sentences or bullets from Step 4>

  ## What changed

  <concise bullet list>

  ### New Flow
  <mermaid diagram, only if selected in Step 5>

  ### Example
  <minimal usage example, only if selected in Step 5>

  <attribution line, only if any skills were invoked>
  ```

### 7. Preview & Confirm

Show the user the complete title and body. Ask:

> Does this PR look good? You can request changes or approve.

Do not create anything until the user approves. Apply requested changes
and re-show the preview.

### 8. Push and Create

- If the branch hasn't been pushed, push it: `git push -u origin <branch>`.
- Create the PR: `gh pr create --title "..." --body "..."`. Always create
  it ready-for-review — do not offer or use draft mode.
- Do not add labels, GIFs, or any other project-specific decoration that
  wasn't detected from this repo's own conventions or template.
- Return the PR URL to the user.

### 9. Offer to Observe the PR

After returning the PR URL, ask the user (yes/no) whether to observe the
PR — watch its CI and reviewer comments and act on them until it merges
or closes.

- If **no** — the command is done.
- If **yes** — record the **observation context**, so every later
  wake-up knows exactly what it's watching:
  - repository (owner/name from `git remote get-url origin`)
  - PR number (from the PR just created)
  - feature branch
  - `<base>` branch (detected in Step 1)
  - a **last-handled marker** for comments (initially empty), used to
    dedupe already-processed comments.

### 10. Observe the PR

Observation runs as a **background, auto-resuming loop**: one pass per
wake-up, rescheduled with `ScheduleWakeup`, so this session stays free
between passes. The loop **stops only when the PR is `MERGED` or
`CLOSED`** (or a guard below fires). Each wake-up re-reads live PR state
rather than trusting stale in-context state.

Each pass:

1. **Terminal-state check** — `gh pr view <n> --json state`. If `MERGED`
   or `CLOSED`, report the final summary (CI fixes pushed, comments
   replied to, decisions escalated) and stop — do not reschedule.

2. **CI pass** — `gh pr checks`. If any check is **failing**: pull the
   failing logs (`gh run view --log-failed`), diagnose, fix on the
   feature branch, commit, and push. The push re-triggers CI. Autonomous
   — do not ask before pushing.

3. **Comment pass** — fetch actionable comments via
   `gh pr view <n> --json comments,reviews` plus `gh api` for inline
   review-comment threads and their IDs. Include inline review comments,
   review summaries (request-changes / approve bodies), and general PR
   comments, from **both humans and bots** (linters, review bots).
   Exclude your own replies. **Dedupe** by comment ID against the stored
   last-handled marker; process only unseen comments, then advance the
   marker.

4. **Triage each new comment:**

   | Category | Examples | Action |
   |---|---|---|
   | **Auto-fixable** | styling, code improvements, refactoring, questions | Apply the fix (or, for a pure question, compose the answer); push if code changed; **reply on that thread** stating what was done. Autonomous — no confirmation. |
   | **Decision-required** | flow changes, business-rule changes, critical failures | **Do not act.** Print to console (`⚠ decision-required comment on PR #<n>: "<comment>"`) and **wait for the user's input**, then act on their instruction. |

5. **Reschedule** with an **adaptive cadence**:
   - ~3 minutes while CI is running or a fix is in flight.
   - ~15–20 minutes while idle and only watching for new comments.

**Retry guards (prevent loops):**

- ≥3 CI-fix attempts without CI going green → stop fixing CI and escalate
  to the user (print to console, wait for input).
- A fix that reintroduces the same failure it just fixed → escalate
  immediately.
- The user can interrupt the observation at any time.

## Guardrails

- Never hardcode a ticket prefix, service tag, label, mandatory
  decoration, or programming language — these vary per repo and must be
  detected, deferred to the template, or asked.
- Never assume the default branch is `main` — detect it.
- Everything specific to this repository comes from Step 1 and Step 2's
  detection, the PR template, or a direct question to the user.
