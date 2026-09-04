---
name: create-pull-request
allowed-tools: Bash(gh pr create:*), Bash(gh pr list:*), Bash(gh pr view:*), Bash(gh pr checks:*), Bash(gh pr comment:*), Bash(gh run view:*), Bash(gh api:*), Bash(git log:*), Bash(git diff:*), Bash(git status:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(git push:*), Bash(git add:*), Bash(git commit:*), Bash(git remote:*), Bash(orca:*), Bash(orca-dev:*), Bash(orca-ide:*)
description: >-
  Create a pull request for the current branch, detecting the repo's own
  conventions and PR template rather than assuming any project's rules.
  Use when the user asks to create a PR, open a PR, push the current branch
  as a pull request, invokes /create-pull-request, or an approved implementation
  worker needs to publish its result or observe its PR.
---

Create a pull request for the current branch. Every repo-specific detail —
title style, ticket references, template sections — comes from **detection,
the repo's own PR template, or asking the user**. Resolve conventions for the repository being changed.

## Orchestrated Implementation and Observation Entry Points

When invoked by `orchestrator-subworktree`, use the approved launch context: repository, feature and target branches, publication permission, observer name/mode/location, coordinator Run, and original implementation task, terminal, and Dispatch. Explicit approval to publish on completion authorizes creation after the title/body passes the checks below; show the result and use that approval. If publication was not approved, route the completed preview to the coordinator for a user decision. Ordinary direct invocation still uses Step 8.

The implementation default is `ci`. The initial confirmation must identify the concrete observer launch as well as PR publication. Reuse that approval in Step 10 for the mode and unchanged launch. Preserve explicit manual/full choices when the user overrides this default.

An observer invokes `superpowers:create-pull-request` in **observation-only mode**, with mode `ci` or `full`, and starts at Step 11. Its workflow consists of observation and findings delivery. Its prompt must include the PR URL/number, repository, feature/base branches, implementation task and sub-worktree, original worker terminal/Dispatch, coordinator Run, and findings route. Missing routing context must be resolved before watching.

## Reader-Friendly Output

Before composing the body, invoke the **reader-friendly-writing** skill and apply
its shared rule set to everything a reviewer will read. Reviewers scan many PRs a day — the body should be why-first,
behavior-level, scannable, and free of code they can already see in the diff.
The specializations in Steps 4–7 below build on that shared rule set.

## Process

### 1. Gather Context

Read branch/status, default branch, and repository identity in parallel. Resolve `<base>` before running the dependent log/diff commands:

- `git branch --show-current` — current branch
- `git status` — uncommitted changes
- Detect the default branch: `git symbolic-ref refs/remotes/origin/HEAD`
  (strip to the branch name, e.g. `origin/main` → `main`). If that fails,
  probe for `main`, then `master`. Retain this
  as the detected default branch.
- For orchestrated work, use the approved target branch as `<base>` (the prerequisite branch for a dependent PR); otherwise use the detected default branch. Keep the default branch separately for the branch guard.
- `git log <base>..HEAD --oneline` — commits on this branch
- `git diff <base>...HEAD --stat` — changed-files summary
- `git diff <base>...HEAD` — full diff, used to **verify** the motivation
  drawn from session context
- `git remote get-url origin` — repository identity

**Guards:**

- If the current branch **is** the detected default branch or the selected `<base>` — stop and
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
- **Ask the user only when detection is ambiguous** — use multiple examples to establish a convention.
- **Ticket-prompt rule:** if recent merged PR titles show ticket-labelled
  titles are the norm for this repo, and no ticket reference can be found
  in the branch name or session context, **ask the user for the ticket
  number** (accepting "none" to proceed without one). For repositories using other title conventions, proceed with the detected style.

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
complete classification before drafting the body.

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
  least one skill was actually invoked. Otherwise omit the attribution.

Apply this motivation discipline when writing the why:

- **Explain why the behavior needs to change.** Use the diff to verify that explanation.
- **Outcome first, then problem.** Open with the resulting behavior. Follow
  with a plain sentence identifying the prior problem and its consequence.
- **One idea per sentence.** Separate the problem, scope, and consequence
  where each contributes to understanding.
- **Use exact domain terms.** Follow reader-friendly-writing's navigation
  and public-interface exceptions when an identifier helps the reader.
- **Place scope counts with supporting evidence.** For example, report
  "7 of 9 places" beside the check that established it.
- **Link to implementation detail** when it helps the reviewer assess a tradeoff.
- **Front-load every sentence and bullet.** Put the most important word first
  — readers scan line-starts.
- **State objective facts.** Drop "cleanly refactored," "nicely
  handles," and similar self-praise; state plain facts.
- **Keep it short.** 2–5 sentences or bullet points.

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
  rule set). Show the prior flow so the reviewer can compare the behavior directly.
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
  single constraint needing special attention — a feature-flag gate, a
  breaking change, a required deploy ordering — lead the body with one
  GitHub alert (`> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]`). It goes
  first because the riskiest item deserves the freshest attention. At most
  one per body; a second halves the first one's signal. Omit it entirely
  when no such fact exists — most PRs have none.

- **A minimal usage example** — copy-pasteable, in the repository's own
  language — shows how a user *interacts* with a userland-visible / API
  change, so a reader gets a feel for it without reading the diff. Show the public interface a user calls. Include it only
  for userland-visible / API changes.

### 6. Compose the PR

**Title:**

- Goal-oriented — state the outcome the PR achieves.
  Test: if the title would still make sense with a different
  implementation underneath, it's goal-oriented; if not, rewrite it.
- Imperative mood ("Add", "Fix", "Update").
- Follow the convention detected in Step 2 (conventional-commit prefix,
  ticket prefix, or plain), including a ticket reference where the
  ticket-prompt rule applies.

**Body:**

- **If a PR template was found in Step 2** — fill every section it
  defines, honoring its inline comments and checkboxes. **Preserve its top-level sections** and fill each with a concrete answer
  or an explanation of applicability. Inside the template's
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

  <one GitHub alert, only when a single fact needs special attention —
  omit otherwise>

  <opening sentence states the outcome and stands alone, then 2-4
  sentences or bullets of problem and context from Step 4>

  ### Resulting flow          <- heading when the visual is a diagram
  ### Before / after          <- heading when the visual is a table
  <one visual, per Step 5 and the shared rule set; omit only when
  justified>

  ### Out of scope
  <deferred work as links — `#1234` per sibling change>

  ### Example
  <minimal usage example, only if selected in Step 5>

  <attribution line, only if any skills were invoked>
  ```

State the behavior change in Why's opening sentence. Use the visual for
flow details and preserve any additional sections required by the repository template.
Include verification evidence in its test-plan section, or add a concise
verification paragraph when using the default structure.

### 7. Trim

Run the trim-pass checklist from the **reader-friendly-writing** skill against
the drafted body (invoke the skill now if it isn't already loaded).
Complete the checklist before presenting the draft.

### 8. Preview & Confirm

For orchestrated publication already authorized in the launch context, show the complete title and body and continue. Otherwise show the user the complete title and body. Ask:

> Does this PR look good? You can request changes or approve.

Create the PR after publication authorization is established. Apply requested changes
and re-show the preview.

### 9. Push and Create

- Push all verified commits: `git push -u origin <branch>`, including updates to a previously pushed branch.
- Check for an existing open PR for this exact repository and head branch; reuse it when its target and ready-for-review state match the approved context. Report mismatches through the coordinator (or to the user for direct invocation) before proceeding. Otherwise create the PR with the explicit repository and base: `gh pr create --repo <owner/repo> --base <base> --head <branch> --title "..." --body-file <prepared-body-file>`. Create it ready-for-review.
- Apply project-specific decoration when the detected conventions or template require it.
- Return the PR URL to the user. In orchestrated implementation mode, also send it immediately to the main coordinator through Orca, with the branch and commit SHA.

### 10. Choose Observation Mode

After returning the PR URL, use the approved observation mode and concrete launch when supplied. Otherwise ask how the user wants to observe it:

| Mode | Behavior |
|---|---|
| **Manual** | Stop after creating the PR. The user handles CI and comments manually. |
| **Full observe** | Watch CI and review comments. Route failures and actionable feedback to the implementation worker, which fixes issues and responds to comment threads. |
| **CI observe** | Watch CI only. Route CI failures to the implementation worker. Limit inputs to PR state and CI checks. |

PR approval alone authorizes creation only. Start observation when both the mode and concrete launch are approved; the initial implementation confirmation may supply both.

- For **manual**, stop.
- For **full** or **CI**, propose one read-only `observe-<specific-topic>` sub-session in the existing implementation worktree, tracked as an Orca task. Unless that exact launch was already approved, fill and show `../orchestrator-agent/launch-confirmation.md`, resolved from this skill directory, and obtain explicit confirmation. Include the selected mode and findings route; use the table's defined rows. The mode choice can also confirm the launch if the concrete table was already shown. Invoke the **orchestration** skill for dispatch.
- Preserve the selected mode and implementation ownership route in the task context: repository and PR number, feature and base branches, implementation task name, implementation sub-worktree, original worker terminal/Dispatch when available, and a short PR brief.
- Start the observer as a sub-session: a separate Codex terminal within that existing worktree. The observer reads PR state and routes findings; the implementation worker owns edits, commits, pushes, and author replies.

Confirm the observer Dispatch exists before reporting it as started. If launching is unavailable from the worker, route the approved launch to the coordinator in the same Run and await its receipt. Reuse an existing observer.

Once the observer starts, it owns observation passes. In orchestrated mode, it reports completion and ends its dispatched turn. The coordinator retains its terminal for the approved correction cycle and resumes it with a fresh Dispatch when needed. A direct caller outside a Dispatch waits for routed findings and reports them in its current session.

### 11. Observe and Route Findings

Only the observer watches the PR. Both automatic modes inspect PR state and CI. Full mode also inspects inline comments, general comments, and review summaries. CI mode reads PR state and checks. Keep reads bounded: query only state/check summaries and, in full mode, comments newer than the stored marker; inspect only relevant failure-log excerpts.

Use the colocated `observe-pr-tick.sh` decision helper for idle backoff and stopping guards. Resolve it from this skill's directory. A changed or unavailable fingerprint triggers an observation pass; an unchanged fingerprint advances the idle counter while retaining the existing worker route.

The observer classifies new information:

| Finding | Route |
|---|---|
| CI still pending or PR unchanged | Record status and continue the observation schedule |
| Concrete CI failure | Send the evidence to the owning implementation worker in full or CI mode |
| Actionable review request | In full mode, send it to the owning implementation worker |
| Product, behavior, scope, or architecture decision from review | In full mode, send it to the coordinating orchestrator for a user decision |
| PR merged or closed | Report the terminal state and stop |

Route actionable evidence through Orca to the implementation worker:

- If the original implementation worker has a live Dispatch, send the finding to that Dispatch. Include the PR URL, checked head SHA, failing check/run URL, relevant log excerpt, and actionable failure summary; record the active fix and route that finding once.
- If its Dispatch has settled, notify the Run coordinator. The coordinator creates a named follow-up task in the same implementation sub-worktree and reuses the exact worker terminal when available; otherwise it proposes a fresh sub-session in that sub-worktree using the shared confirmation table before launch.
- Keep only one fix task active for a PR at a time.

The implementation worker owns every correction. For behavioral changes it follows RED -> GREEN -> REFACTOR, reproducing the issue with a focused failing test before editing production code. It runs the focused tests and checks for the correction; CI supplies broader repository coverage. It commits, pushes, and reports the new commit through Orca. In full mode it also responds to the relevant review thread with what changed, or answers a comment that required no code change. The observer then resumes against the updated PR head SHA; assess the correction using results for the updated head.

Stop observation when:

- The PR merges or closes
- Three consecutive probes find no change
- Three correction attempts fail to make progress
- Roughly 20 passes or two hours elapse
- A decision is waiting on the user
- The user asks to stop

On stop, report the reason to the implementation worker and coordinating orchestrator. Leave the PR, sub-worktree, and branch available for the user's integration decision.

## Guardrails

- Resolve ticket prefixes, service tags, labels, decorations, and language
  through repository detection, its template, or a user decision.
- Detect the default branch.
- Everything specific to this repository comes from Step 1 and Step 2's
  detection, the PR template, or a direct question to the user.
