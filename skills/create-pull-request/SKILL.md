---
name: create-pull-request
allowed-tools: Bash(gh pr create:*), Bash(gh pr list:*), Bash(gh pr view:*), Bash(gh pr checks:*), Bash(gh pr comment:*), Bash(gh run view:*), Bash(gh api:*), Bash(git log:*), Bash(git diff:*), Bash(git status:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(git push:*), Bash(git add:*), Bash(git commit:*), Bash(git remote:*)
disable-model-invocation: true
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

Before composing the body, invoke the **reader-friendly-writing** skill and apply
its shared rule set to everything a reviewer will read. Reviewers scan many PRs a day — the body should be why-first,
behavior-level, scannable, and free of code they can already see in the diff.
The specializations in Steps 4–7 below build on that shared rule set.

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
- `git diff <base>...HEAD` — full diff, used to **verify** the motivation
  drawn from session context, not as the source to narrate from
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
  take and why. Draft from that session context; consult the diff only to
  check the draft is accurate. Narrating from the diff produces diff
  restatement — that is the failure this ordering prevents. If the session
  genuinely doesn't carry the motivation, ask the user rather than
  reverse-engineering it from changed lines.
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
- **Exact domain terms, not code identifiers.** Use the project's own
  vocabulary precisely ("payout settlement", "funding source") — but never
  a class, event, or command name. A near-synonym signals shaky
  understanding; a code identifier signals you're narrating the diff. If a
  term only exists in code, it is not a domain term.
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

Match aids to the change's intent from Step 3. A visual is the default
(see the shared rule set) — this table says *which* visual, and when an
example is warranted.

| Change type | Visual | Usage example | Motivation emphasis |
|---|---|---|---|
| Refactor / internal cleanup | `graph LR` if structural, else before/after table | no | the role/design mismatch being fixed |
| Bug fix | before/after table | only if usage-affecting | the incorrect behavior and why it was wrong |
| New feature | type per the shared menu | if userland-visible | what the feature enables |
| Flow / state / pipeline change | `stateDiagram-v2` or `graph TD` | if userland-visible | what the new flow achieves |
| Userland-visible behavior / API | before/after table, or `sequenceDiagram` if multi-party | **yes** | what changes for users |
| Config / docs / tooling | skip if no structural element | no | why the change is needed |

- **Diagrams are paired — prior flow, then resulting flow** (per the shared
  rule set). Don't drop the prior flow on the grounds that the diff conveys
  it: a diff shows changed lines, not the shape of the flow they formed.
  Omit the prior diagram only when the change replaces nothing. Keep both
  small — the pair must stay within the one-visual budget, so if pairing
  pushes past ~10–15 nodes total, narrow the diagrams to the part that
  actually changed rather than dropping one. Format:

  ````
  **Before**

  ```mermaid
  stateDiagram-v2
      [*] --> Awaiting
      Awaiting --> Settled
  ```

  **After**

  ```mermaid
  stateDiagram-v2
      [*] --> Awaiting
      Awaiting --> Reconciled
      Reconciled --> Settled
  ```
  ````

- **One alert, only for a must-not-miss fact.** When the change carries a
  single constraint a reviewer must not miss — a feature-flag gate, a
  breaking change, a required deploy ordering — lead the body with one
  GitHub alert (`> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]`). It goes
  first because the riskiest item deserves the freshest attention. At most
  one per body; a second halves the first one's signal. Omit it entirely
  when no such fact exists — most PRs have none.

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
  defines, honoring its inline comments and checkboxes. **Keep its
  top-level sections exactly as defined** — never add, remove, or rename
  a `##` heading, and never leave one blank. Inside the template's
  primary prose section (whatever it calls the why — "Motivation",
  "Description", "Summary"), use the same ordered shape as the default
  structure below: `### Why`, then the visual (`### Resulting flow` or
  `### Before / after`), then `### Out of scope`, then `### Example` if
  Step 5 selected one. Omit a subheading when it is genuinely empty.
  Heading *levels* differ by one between the two paths — here everything
  is `###` beneath the template's own `##`; in the no-template structure
  below, Why is itself `##`. The **order and the names** are identical
  either way, which is what a daily reader navigates by. An alert, if Step
  5 selected one, leads that primary prose section.
- **If no template was found** — use this default structure:

  ```
  ## Why

  <one GitHub alert, only when a single fact must not be missed —
  omit otherwise>

  <opening sentence states the outcome and stands alone, then 2-4
  sentences or bullets of problem and context from Step 4>

  ### Resulting flow          <- heading when the visual is a diagram
  ### Before / after          <- heading when the visual is a table
  <one visual, per Step 5 and the shared rule set; omit only when
  justified>

  ### Out of scope
  <deferred work as links — `#1234` per sibling change, not prose>

  ### Example
  <minimal usage example, only if selected in Step 5>

  <attribution line, only if any skills were invoked>
  ```

**There is deliberately no "What changed" section.** An uncapped
what-section fills with code identifiers, which is the failure this
structure removes. The behavior delta belongs in Why's opening sentence,
stated as an outcome; the visual carries the rest.

### 7. Trim

Run the trim-pass checklist from the **reader-friendly-writing** skill against
the drafted body (invoke the skill now if it isn't already loaded).
Fix every failing item **before** showing the user anything — this step is
not optional and not a judgment call about whether the body "seems fine".

### 8. Preview & Confirm

Show the user the complete title and body. Ask:

> Does this PR look good? You can request changes or approve.

Do not create anything until the user approves. Apply requested changes
and re-show the preview.

### 9. Push and Create

- If the branch hasn't been pushed, push it: `git push -u origin <branch>`.
- Create the PR: `gh pr create --title "..." --body "..."`. Always create
  it ready-for-review — do not offer or use draft mode.
- Do not add labels, GIFs, or any other project-specific decoration that
  wasn't detected from this repo's own conventions or template.
- Return the PR URL to the user.

### 10. Offer to Observe the PR

After returning the PR URL, ask the user (yes/no) whether to observe the
PR — watch its CI and reviewer comments and act on them until it merges,
closes, or goes quiet.

- If **no** — the command is done.
- If **yes** — record the **observation context**, so every later
  wake-up knows exactly what it's watching:
  - repository (owner/name from `git remote get-url origin`)
  - PR number (from the PR just created)
  - feature branch
  - `<base>` branch (detected in Step 1)
  - a **PR brief** — at most ~10 lines: what this PR changes and why,
    plus anything detected in Steps 1–2 that a fresh executor would
    otherwise have to rediscover (test/lint commands, review-bot
    conventions, repo quirks). This is the "summary of context" handed
    to every pass agent.
  - a **last-handled marker** for comments — the highest comment ID
    already processed, initially `0` so the pass agent's `select(.id >
    <marker>)` filter works unchanged on the first pass.
  - the **last fingerprint** (initially empty) — the short string from
    the probe in Step 11, used to detect "nothing moved" without
    dispatching anything.
  - the **idle-pass counter** (initially `0`) — consecutive passes that
    found nothing to do.
  - the **CI-fix attempt count** (initially `0`) — pushes made to fix CI
    that haven't yet produced a green run.
  - the **pass count** and **observation start time**, for the absolute
    ceiling below.

  This context is the loop's entire memory. Keep it small and carry it
  forward across wake-ups; everything bulky lives in the pass agents.

### 11. Observe the PR

Observation runs as a **background, auto-resuming loop**: one pass per
wake-up, rescheduled with `ScheduleWakeup`, so this session stays free
between passes. The loop stops when the PR is `MERGED` or `CLOSED`, when
**three consecutive passes find nothing to do**, or when a retry guard
below fires. Each wake-up re-reads live PR state rather than trusting
stale in-context state.

**Every pass runs in a dispatched subagent, not in this session.** CI
logs, diffs, and fix attempts are bulky and would swamp the main context
window, so this session only ever holds the small observation context and
a short report per pass. Dispatch with `Agent`, `subagent_type:
general-purpose`, `model: sonnet` — sonnet 5 is the executor for
observation work.

**Per wake-up, this session does exactly four things:**

1. **Probe — cheap, and never skipped.** One reduced-output read that
   tells you whether anything moved. Reduce *before* the data reaches
   context, never after:

   ```
   gh pr view <n> --repo <repo> --json state,statusCheckRollup \
     --jq '[.state] + [.statusCheckRollup[]? | "\(.name):\(.conclusion // .status)"] | join("|")'
   gh api --paginate repos/<repo>/pulls/<n>/comments --jq '.[].id' | awk 'END{print NR":"$0}'
   gh api --paginate repos/<repo>/issues/<n>/comments  --jq '.[].id' | awk 'END{print NR":"$0}'
   ```

   Concatenate the three lines — that's the fingerprint. Adapt the
   filters if a repo needs it; the requirement is that the output stays
   a short string, not that these exact expressions are used.

   Feed the fingerprint and the stored counters to
   `observe-pr-tick.sh` (Step 4) and obey its `action`. In short:
   a `MERGED`/`CLOSED` PR stops with a final summary; an unchanged
   fingerprint is an idle pass that **must not cost an agent boot**; a
   changed or uncomputable fingerprint dispatches, because failing to
   compute should fail toward doing work rather than toward idling on
   data you don't have.

2. **Dispatch one pass agent** (background), handing it the PR brief,
   repo, PR number, feature branch, `<base>`, the last-handled comment
   marker, the CI-fix attempt count, and the pass instructions below.
   Never re-derive the brief — pass the stored one verbatim. Do not read
   CI logs, diffs, or comment bodies yourself.

   - **Never two agents in flight.** If a pass agent from an earlier
     wake-up is still running, skip this wake-up entirely and reschedule
     — two agents on one PR means duplicate pushes and duplicate replies.
   - **Keep the prompt prefix byte-identical** across dispatches: brief
     and instructions first, worded the same every time, with the
     varying state (marker, counts) appended last. A stable prefix is a
     cache hit; a reshuffled one is a full re-read.

3. **Process the returned report** — apply it to the observation context
   (advance the marker, update the CI-fix attempt count, increment the
   pass count), enforce the retry guards below, and relay a one-or-two-
   line status to the user. The agent's own report is not shown to the
   user, so surface anything they need — especially decision-required
   comments, verbatim. The fingerprint is stored from the probe, not from
   the report: if the agent pushed or replied, the next probe will
   legitimately differ, and that next pass is not idle.

4. **Reschedule or stop.** The agent's completion notification is the
   primary wake signal, so do not schedule a short wakeup to poll it;
   set a long fallback (~1200s) while it runs so a hung pass can't kill
   the loop. There is no fast CI cadence: a pass agent watches CI to
   completion itself (see below), so the loop never polls a running
   pipeline.

   Otherwise the next `ScheduleWakeup` delay is **driven by the idle-pass
   counter** — quiet PRs get checked progressively less often:

   | Idle counter | Next check in |
   |---|---|
   | `0` (something moved last pass) | 10 minutes |
   | `1` | 20 minutes |
   | `2` | 30 minutes |
   | `3` | — stop, do not reschedule |

   Any change resets the counter to `0`, and the delay goes back to 10
   minutes with it — the backoff always restarts from the beginning, it
   never resumes where it left off. A fully quiet PR is therefore
   observed for 10 + 20 + 30 = ~60 minutes before the loop stops.

   **Do not compute this by hand — run the decision script.** It owns the
   idle rule, the backoff, and every guard below, so the constraint holds
   identically on every wake-up.

   The script `observe-pr-tick.sh` sits in this skill's own directory. Resolve
   its absolute path before the first call — in Claude Code that is
   `${CLAUDE_SKILL_DIR}/observe-pr-tick.sh`; on other platforms it is the
   directory holding this file. Written below as `<SKILL_DIR>/`:

   ```
   <SKILL_DIR>/observe-pr-tick.sh --state <state> \
     --fingerprint "<this pass's probe>" --last-fingerprint "<stored probe>" \
     --idle-count <n> --pass-count <n> --elapsed-minutes <n> [--blocked]
   ```

   It prints `action` (`stop` | `dispatch` | `wait`), `reason`,
   `idle_count` to store, and `delay_seconds` to pass to
   `ScheduleWakeup`. Obey `action` literally: `wait` means reschedule
   without dispatching an agent, `stop` means do not reschedule at all.

   **Stop rescheduling entirely when the loop is blocked on the user** —
   a decision-required comment or an escalated guard. Their reply is the
   resume signal. Waking up to rediscover the same blocked state is pure
   burn, and overnight it is a lot of it.

**Pass agent instructions** (include these in the dispatch prompt):

1. **CI pass** — `gh pr checks`. If checks are still running, wait them
   out in-process with `gh pr checks --watch` under a bounded timeout
   (~10 minutes), rather than returning and making the parent poll. If
   the budget expires, report the checks as still pending and return.

   If any check is **failing**: read the logs *bounded*, never whole.
   Grep for failure markers first and expand only around the hits —
   `gh run view --log-failed | grep -nEi 'error|failed|assert' | head -40`,
   then pull context around the interesting line numbers. A CI log is
   routinely tens of thousands of lines; dumping one into context is the
   single most expensive mistake available to you.

   Diagnose, fix on the feature branch, commit, and push. The push
   re-triggers CI. Autonomous — do not ask before pushing.

   Verify a fix by running the **specific failing test**, not the full
   suite. CI confirms the rest; that's what the next pass is for.

2. **Comment pass** — fetch actionable comments with the marker pushed
   *into the query*, so already-handled comments never materialize in
   your context at all:

   ```
   gh api --paginate repos/<repo>/pulls/<n>/comments \
     --jq '.[] | select(.id > <marker>) | {id, path, line, user: .user.login, body}'
   ```

   Do the same for `repos/<repo>/issues/<n>/comments` (general PR
   comments) and `gh pr view <n> --json reviews` (review summaries —
   request-changes / approve bodies). Include **both humans and bots**
   (linters, review bots). Exclude your own replies. Never fetch every
   comment and dedupe afterward — on a long PR that re-reads the entire
   review history each pass to discover nothing new.

3. **Triage each new comment:**

   | Category | Examples | Action |
   |---|---|---|
   | **Auto-fixable** | styling, code improvements, refactoring, questions | Apply the fix (or, for a pure question, compose the answer); push if code changed; **reply on that thread** stating what was done. Autonomous — no confirmation. |
   | **Decision-required** | flow changes, business-rule changes, critical failures | **Do not act, and do not reply.** Return it verbatim in the report for the parent to escalate. |

4. **Report back in this exact shape, and nothing more** — no logs, no
   diffs, no transcripts. The parent's context is the thing being
   protected:
   - `pr_state`: current state from `gh pr view`.
   - `checks`: one line per check — `<name>: <conclusion>`.
   - `new_marker`: highest comment ID handled this pass (or the marker
     unchanged).
   - `actions_taken`: one line each, or `none`.
   - `ci_fix_attempts`: the count you were given, plus any push you made
     this pass.
   - `decision_required`: each such comment verbatim with its thread URL,
     or `none`.

**Idle constraint — hard, enforced by this session on every pass.** It is
decided by the probe and `observe-pr-tick.sh`, never by a subagent, so
nothing in a pass report can talk the loop into continuing:

- Fingerprint unchanged → idle pass, counter increments (10 → 20 → 30
  minute backoff).
- Fingerprint changed, or unavailable → counter resets to `0`.
- Counter reaches **3** (idle, idle, idle) → **stop.** Report the final
  summary plus `PR #<n> unchanged for 3 consecutive checks — stopping
  observation. Ask me to observe again if you want it resumed.` Do
  **not** dispatch another pass and do **not** reschedule.

Store the returned counter and the fingerprint before rescheduling. Never
skip the probe to keep a loop alive, and never reset the counter just
because the PR is still open — an unchanged PR is exactly the case this
constraint exists to stop.

**Retry guards (prevent loops):**

- 3 consecutive idle passes → stop observing entirely (above).
- ≥3 CI-fix attempts without CI going green → stop dispatching CI fixes
  and escalate to the user. Pass the running count into each dispatch so
  a fresh agent can't reset it.
- A fix that reintroduces the same failure it just fixed → escalate
  immediately.
- **Absolute ceiling** — stop after ~20 passes or ~2 hours of
  observation, whichever comes first, and tell the user the loop ended on
  the ceiling with the PR still open. This backstops the case the idle
  rule cannot catch: a PR that keeps changing (a chatty bot, a flapping
  check) so the fingerprint never repeats and no pass is ever idle.
- Escalating for any reason means **stop rescheduling** and wait for the
  user, per Step 4.
- The user can interrupt the observation at any time.

## Guardrails

- Never hardcode a ticket prefix, service tag, label, mandatory
  decoration, or programming language — these vary per repo and must be
  detected, deferred to the template, or asked.
- Never assume the default branch is `main` — detect it.
- Everything specific to this repository comes from Step 1 and Step 2's
  detection, the PR template, or a direct question to the user.
