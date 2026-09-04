---
name: review-changes
allowed-tools: Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh api:*), Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(git remote:*), Edit, Bash
argument-hint: "[pr-url or owner/repo#123]  (defaults to the current branch)"
description: >-
  Review a set of code changes — a GitHub pull request or the current
  branch's diff — by first building shared understanding of why the
  change exists, then (unless the user only wants context) running a
  structured, severity-tiered review. Use when the user asks to review
  a PR, review the current branch's changes, review changes before
  opening a PR, get context/understanding on a set of changes without
  reviewing them, requests a review sub-session in an existing worktree, or invokes /review-changes.
---

Review a set of code changes end-to-end: first build and confirm understanding
of why the change exists and what it does, then — unless the user only wants
context — run a structured review whose findings the user can act on
immediately: posting agreed points as inline PR comments (peer-review) or
applying agreed fixes locally (self-review). Each finding that asserts a
behavioral defect includes a proposed test and its predicted failure. Approved
self-review fixes turn these proposals into verified regression coverage.
Resolve repo-specific details (PR template, ticket format, Jira instance)
through detection or a user decision.

When an approved `review-<topic>` sub-session, tracked as an Orca task, invokes this skill, the
Orchestrated Review Mode below overrides the interactive mode selection and
action loop. Manual invocations keep the existing workflow unchanged.

**REQUIRED SUB-SKILL:** Use orchestration for task questions, findings delivery,
and worker lifecycle when running inside an Orca review task.

## Reader-Friendly Output

Before writing the Phase 1 summary, invoke the **reader-friendly-writing** skill
and apply its shared rule set. The summary is a write-up a
reviewer reads to understand the change — it should be why-first,
behavior-level, scannable, and free of code the reader can already see in the
diff. This shapes Phase 1 only — including the shared rule set's highlighting
budget and its trim pass; Phase 2 findings keep their code citations and their
failing test cases (see below).

## Orchestrated Review Mode

Use this mode only when the task prompt identifies an explicitly requested
`review-<topic>` Orca task and its matching completed `implement-<topic>` task.
The task prompt must provide the review target, base branch or PR reference,
approved implementation context, focus, and whether inline PR comments are
authorized.

- Run as a sub-session: a separate Codex terminal within the implementation
  sub-worktree. The launching coordinator must
  first show `../orchestrator-agent/launch-confirmation.md` (resolved from this
  skill directory), filled for this sub-session, and obtain confirmation. Reuse that approval inside the reviewer.
- Review the supplied stable commit while implementation edits are paused. If
  the checkout changes, report it and re-establish the target with the coordinator
  before continuing.
- Use peer-review semantics for both local and PR targets. Skip Step 2's mode
  and focus questions and the Phase 1 peer-review pause because the task prompt
  already supplies those decisions.
- Keep the review read-only. Present proposed failing tests as evidence in
  the findings, and return fixes to the original implementation worker.
- For a local target or report-only PR target, return the complete severity-
  ranked findings through Orca without posting externally.
- For a PR target with explicit comment authorization in the task prompt, post
  findings as inline comments. Use the explicit comment permission from the task prompt. The user owns
  the overall PR review verdict.
- Report the reviewed commit SHA, target, findings, and remaining uncertainty to
  the orchestrator. The original implementation worker owns every fix.
- Send `worker_done` exactly once through the active Orca Dispatch, then end the
  turn. The orchestrator may reuse this exact reviewer sub-session after fixes.

## Process

### 1. Detect Input Source

- The user supplied a GitHub PR reference with the request — a URL or
  `owner/repo#123` → fetch it: `gh pr view <ref> --json title,body,number,url`
  and `gh pr diff <ref>`.
- No reference supplied → diff the current branch against its detected default branch:
  `git symbolic-ref refs/remotes/origin/HEAD` (strip to branch name); if that
  fails, probe for `main`, then `master`. Call the result `<base>` and use it
  for every command below: `git diff <base>...HEAD` and
  `git log <base>..HEAD --oneline`.
- **Guard:** if diffing the current branch and it *is* `<base>`, stop and tell
  the user there's nothing to diff against.

### 2. Ask Mode and Focus

Ask, in order:

1. "Should this be a **self-review**, a **peer-review**, or a
   **context-review**?" — asked regardless of input source (a PR link can be
   self-reviewed to apply local fixes; a local branch diff can be
   peer-reviewed, e.g. reviewing a colleague's checked-out branch).
   **Context-review** runs Phase 1 only and stops there. It's for when the user wants to understand a change without
   asking for a review of it.
2. "Anything specific you'd like this review to focus on or verify?" —
   optional; blank means the standard checks below. Whatever the user says
   here shapes Phase 1's context-gathering for all three modes, and Phase 2's
   checks for self-review/peer-review.

If peer-review was chosen and no PR argument was given, try `gh pr view` with
no arguments to resolve an open PR for the current branch. If none exists,
tell the user inline posting won't be available this run — the review still
runs, ending in a chat-only list (see Step 5).

Manual invocation always runs in the current session. In orchestrated mode,
`orchestrator-agent` owns the separate reviewer session; reuse the approved reviewer placement.

### 3. Phase 1 — Understanding

Before gathering change context, perform non-interactive skill mapping:

- Scan the available skill names and descriptions against the change's domain,
  affected artifacts, and likely review risks.
- Conservatively invoke only skills whose specialized knowledge can improve
  research, interpretation, or review of this specific change.
- Use the selected skills while gathering context and evaluating the diff.
  Apply their domain guidance within this review workflow.
- Select research and review guidance autonomously, then continue gathering
  context in this session.

Gather in parallel:
- The diff itself.
- PR title/description, if reviewing a PR.
- A ticket reference from the branch name or PR body via a generic pattern
  (e.g. `[A-Z]+-\d+`) that works across ticket-prefix conventions.
- **Jira, best-effort:** if a ticket key is found and a Jira-related MCP tool
  or CLI is available in this session, fetch that ticket's details. If it has
  a parent epic, fetch the epic's title/description too. If no ticket is
  found or no Jira tool is available, continue using the available change context.
- Session context, if this review connects to work already discussed in this
  conversation.
- The user's stated focus from Step 2.

Then:
- **Classify the change:** business change / technical change / refactor /
  mixed. State the classification and reasoning, then continue; incorporate any user correction.
- **Check for scope slicing:** is this change a partial slice of larger
  functionality with more PRs still to come? Look for staged/part/phase
  language in the PR description or commit messages, an epic (from the Jira
  step above) with sibling tickets not yet resolved, or session context. Ask
  the user directly if it's ambiguous. This matters because a partial slice
  changes what "complete" means for Phase 2's intent-alignment check.
- **Summarize** for the user in this fixed shape, every time:

  ```
  <one-line TL;DR of what the change achieves>

  ### Problem space
  <the business intent: what need or problem this addresses, described through the relevant flow(s) and their business purpose.>

  ### Solution space
  <how that intent was solved: the approach taken, described through the
  resulting flow(s). Put the resulting diagram here and the prior diagram under Problem space.>

  ### Scope
  <the classification and reasoning; if this is a partial slice, which part
  it delivers and what is intentionally deferred>
  ```

  Keep it scannable — bullets, one idea each, front-loaded. Describe
  behavior and flows. Name the single entry point when it helps the reader
  navigate to the relevant code.
- When a flow/state/pipeline is involved, show a Mermaid diagram of the
  prior flow (problem space) together with one of the resulting flow
  (solution space) — paired, per the shared rule set. Two specializations
  here: the pairing is **unconditional in this phase** (a change with no
  prior flow still gets a diagram of the surrounding flow it plugs into, so
  the reader sees where it lands), and it applies wherever a flow diagram
  appears in this skill's output, **including inside Phase 2 findings**.
  Put the prior flow under the Problem space heading and the resulting flow
  under Solution space; together they are the **one visual** of the budget.
- A **minimal usage example** is allowed only for a userland-visible / API
  change — showing how a user interacts with the public interface.
- **Trim before presenting.** Run the trim-pass checklist from the
  **reader-friendly-writing** skill against the drafted summary and fix every
  failing item first (invoke the skill now if it isn't already loaded). Keep any verification evidence in a concise paragraph after the summary.
- **Peer-review (manual mode only):** pause — ask "Any questions before we move to the review,
  or should we proceed to Phase 2?" Answer follow-ups, re-summarize if
  useful, proceed once the user says go.
- **Self-review:** present the summary and proceed to Phase 2.
- **Context-review:** present the summary, answer any follow-up questions,
  then stop. The understanding summary completes this mode.

### 4. Phase 2 — Review (self-review, peer-review, and orchestrated review)

Work through these, in order, weighted by the Phase 1 classification:

1. **Design/architecture** — is this the right approach, does it fit
   existing patterns, is it more complex than it needs to be. First, because
   a wrong design makes line-level findings moot.
2. **Correctness**, including an **intent-alignment check**: does the diff do
   what Phase 1's context (PR description, ticket, epic) says it should,
   covering the stated acceptance criteria — not just "is the code locally
   correct." If this is a partial slice, judge against that slice's own
   scope: work deferred to a later PR is expected, not missing. Weight this
   heavily for business changes (the diff alone can't say whether it
   satisfies the ticket); for refactors, check instead whether scope stayed
   within what was described — flag a refactor that silently grew into a
   behavior change.
3. **Cross-cutting risk**, sized to the classification:
   - Business change → downstream/consumer impact, backward compatibility
     with existing/in-flight data when a rule changes.
   - Technical change → concurrency/failure-mode scenarios traced concretely
     (not abstractly), migration/schema-change safety, cross-service blast
     radius, code reuse over duplication.
   - Refactor → behavior-preservation.
4. **Tests** — is the new/changed logic actually covered, by the right kind
   of test.
5. **Style/naming/docs** — last, and only where lint/CI doesn't already
   enforce it; includes domain terminology precision (names that don't match
   what they represent).

**Reviewer voice** — apply these throughout:
- Favor concrete, evidence-grounded failure scenarios over abstract risk
  statements.
- Question necessity before design (YAGNI) on new classes, methods, events,
  or test scenarios.
- Ask terse clarifying questions rather than asserting when something is
  ambiguous.
- Check backward compatibility with real existing/persisted data whenever a
  rename, schema change, or logic change touches state that may already
  exist.
- Keep tone direct, concrete, and specific to the code at hand.
- Separate "worth discussing" from "blocking" explicitly — a real concern can
  be surfaced and still tagged non-blocking.

**Checks library** — apply where relevant:
- **Unsafe permissive defaults on mode-relevant flags** — a new boolean
  parameter whose name implies a mode switch (`rebuild`, `dryRun`, `force`,
  `live`) shipping with a default that reads as the silent/normal case.
  Surface as a question ("should this be required instead?") — a judgment
  call, not an auto-fix.
- **Missing placement validation for new positional attributes/decorators** —
  a new attribute/annotation whose effect depends on where it's placed, with
  no compile-time/config-time guard against misplacement.
- **False-positive-prone tests** — specifically missing-negative-assertion
  (happy-path-only tests with no check for the negative/absence case) and
  wrong-synchronicity-assumption (unnecessary polling/waiting for something
  actually synchronous, or a missing wait for something actually async)
  shapes. Leave ordering-dependent assertions to static-analysis/lint
  tooling.
- **Infra-swap behavior parity** — when a change replaces or swaps a core
  component (DI container, client, storage layer, etc.), trace the old code
  path against the new code path using Phase 1's context to see what
  actually needs to be preserved, and report what that tracing shows
  (preserved / a specific discrepancy / can't be determined from code
  alone). Trace this by reading code and explain the evidence; CI provides the
  broader suite results.
- **Recurring-pattern check** — once a root-cause fix is identified for a
  specific risky API/primitive, grep the same module/integration for other
  usages of that primitive and flag them too.
- Leave interface-contract argument-order/arity mismatches to static
  analysis/type-checking tooling.

**Scope of findings** — state this to the user up front each run: findings
focus on design, correctness, cross-cutting risk, and test adequacy for the
code actually in this diff. Style/formatting is lint/CI's to catch;
generated/vendored files sit outside the diff's real surface; risk findings
need a concrete precondition, not a theoretical one; pre-existing issues the
change didn't introduce are informational context alongside the primary
findings, not primary findings themselves. CI/dialect/environment/
version-matrix gaps aren't visible from a diff — call these out as "run the
full CI/lint matrix to catch this" rather than guessing. Derive findings from code and Phase 1 context. Label proposed tests as
unexecuted predictions until Step 5 verifies them. Step 5 runs focused tests
for approved self-review fixes; CI owns broader suite coverage.

**Proposed failing test per behavioral finding** — the evidence that makes a finding
falsifiable, and the thing the user needs in order to judge whether the finding
is real:

- Every finding that asserts a **behavioral defect** carries a proposed test
  case with a predicted failure against the code in this diff. All severities, both self-review and
  peer-review.
- **Match the repo's own test style.** Before writing any example, read an
  existing test covering the touched area and take its framework, naming
  convention, assertion style, and fixture/builder helpers from it. The example
  should read like it was already part of that suite, not like generic
  pseudo-code.
- Each test case states three things: the **concrete input or state** that
  triggers the problem, the **assertion that should hold**, and one line of what
  the predicted result based on code inspection (e.g. "predicted failure: returns the same date").
- **Present proposed tests in chat during Phase 2.** The user uses them to
  assess the findings. Approved self-review tests are written and run in Step 5.
- For design pivots, naming decisions, and necessity/YAGNI questions, state
  the reasoning directly.
- Code is allowed inside a finding's test case. The prose and usage-example rules from
  **reader-friendly-writing** govern the Phase 1 understanding summary; Phase 2 findings keep their citations and their
  test cases.

**Severity and output:**
- Tag every finding **Blocking / Should-fix / Nit / FYI**, sorted by
  severity, each with a file:line citation.
- Cap Nit-level findings shown individually at 5; summarize any remainder as
  a count.
- "No blocking issues found" is a complete, valid outcome — only list
  findings that earned their place.
- Present the output as a numbered list in chat: severity, file:line,
  description, then the failing test case where the finding has one.

### 5. Action Loop (manual self-review and peer-review only)

For orchestrated review, complete Orchestrated Review Mode: deliver findings through Orca, post inline comments only when the task
prompt explicitly authorizes them, and leave all fixes to the original
implementation worker. After `worker_done`, stop; the remaining instructions in
this section apply only to manual review.

Present the full numbered list at once, then ask for a **single consolidated
response** dispositioning every point by number — e.g. "1, 3 approve; 2
skip; 4 improve: <replacement wording>". Accept any reasonable free-form
phrasing (grouped numbers, ranges, per-number notes). If the response leaves
any number's disposition unclear, ask one follow-up naming just the
unresolved numbers.

Once every point has a disposition:
- **Peer-review:** for each approved point, post it immediately as an inline
  GitHub PR comment (`gh api repos/{owner}/{repo}/pulls/{pull_number}/comments`,
  with `commit_id`, `path`, and `line` matching the citation) using the
  user's replacement wording for "improve" points. Include the point's failing
  test case in the comment body as a fenced code block labelled as a prediction, so the author can paste
  it straight into the suite. Keep peer-review findings in chat or the authorized inline comments.
  The user owns the overall PR review verdict.
- **Self-review — prove the finding first.** For each approved point that has a
  failing test case, write that test into the test file covering the code in
  question (the repo's own layout decides where; create the file if none
  exists), then **run that one test** and report its actual output. Branch on
  the result:
  - **Fails as predicted** → the finding is confirmed. Then apply the fix for
    the mechanically-automatable checks (unsafe-default question resolved,
    false-positive-prone test, infra-parity discrepancy with a concrete fix,
    recurring-pattern instance) directly with the Edit tool, using the user's
    replacement approach for "improve" points, and re-run the same test to
    confirm it goes green.
  - **Passes unexpectedly** → say so plainly: the finding was wrong. Remove the
    test again and apply no fix.
  - **Judgment-requiring fix** (design pivots, cross-subsystem root-cause
    hypotheses, doc/product judgment calls) → leave the test on disk failing and
    surface the hypothesis for the user to act on. This skill states the
    hypothesis for the user's decision.

  Judgment-requiring findings are presented with a stated hypothesis regardless
  of disposition. An approved point with no expressible test skips straight to
  the fix/hypothesis handling above — there is nothing to write or run.
- If peer-review was chosen but no PR could be identified (Step 2), the
  numbered list and the user's dispositions are the final output, recorded
  in chat — same as self-review's baseline.

## Notes

- Resolve the default branch, ticket prefix, Jira instance, and PR template
  for the repository being reviewed.
- Argument-order/arity mismatches and ordering-dependent test flakiness are
  left entirely to static-analysis/lint tooling, which already covers them.
- In Step 5, run the focused test to reproduce the finding and again to
  verify an approved fix. CI owns broader coverage. The `Bash` grant supports
  each repository's test runner.
- Return judgment-requiring fixes and the overall PR verdict to the user.
