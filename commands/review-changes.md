---
name: review-changes
allowed-tools: Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh api:*), Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(git remote:*)
disable-model-invocation: false
description: >-
  Review a set of code changes — a GitHub pull request or the current
  branch's diff — by first building shared understanding of why the
  change exists, then (unless the user only wants context) running a
  structured, severity-tiered review. Use when the user asks to review
  a PR, review the current branch's changes, review changes before
  opening a PR, get context/understanding on a set of changes without
  reviewing them, or invokes /review-changes.
---

Review a set of code changes end-to-end: first build and confirm understanding
of why the change exists and what it does, then — unless the user only wants
context — run a structured review whose findings the user can act on
immediately: posting agreed points as inline PR comments (peer-review) or
applying agreed fixes locally (self-review). Everything repo-specific (PR
template, ticket format, Jira instance) is always detected or asked at
runtime — this command carries none of a project's own conventions as fixed
values.

## Process

### 1. Detect Input Source

- Argument `$ARGUMENTS` is a GitHub PR reference (a URL or `owner/repo#123`)
  → fetch it: `gh pr view <ref> --json title,body,number,url` and
  `gh pr diff <ref>`.
- No argument → diff the current branch against its detected default branch:
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
   **Context-review** runs Phase 1 only and stops there — no findings, no
   action loop. It's for when the user wants to understand a change without
   asking for a review of it.
2. "Anything specific you'd like this review to focus on or verify?" —
   optional; blank means the standard checks below. Whatever the user says
   here shapes Phase 1's context-gathering for all three modes, and Phase 2's
   checks for self-review/peer-review.

If peer-review was chosen and no PR argument was given, try `gh pr view` with
no arguments to resolve an open PR for the current branch. If none exists,
tell the user inline posting won't be available this run — the review still
runs, ending in a chat-only list (see Step 5).

This command always runs in the current session — there is no subagent
dispatch here.

### 3. Phase 1 — Understanding

Gather in parallel:
- The diff itself.
- PR title/description, if reviewing a PR.
- A ticket reference from the branch name or PR body via a generic pattern
  (e.g. `[A-Z]+-\d+`) that works across ticket-prefix conventions.
- **Jira, best-effort:** if a ticket key is found and a Jira-related MCP tool
  or CLI is available in this session, fetch that ticket's details. If it has
  a parent epic, fetch the epic's title/description too. If no ticket is
  found or no Jira tool is available, continue without it — that's expected,
  not an error.
- Session context, if this review connects to work already discussed in this
  conversation.
- The user's stated focus from Step 2.

Then:
- **Classify the change:** business change / technical change / refactor /
  mixed. State it and the reasoning as context for the user, not a checkpoint
  to approve — they can redirect if it looks wrong.
- **Check for scope slicing:** is this change a partial slice of larger
  functionality with more PRs still to come? Look for staged/part/phase
  language in the PR description or commit messages, an epic (from the Jira
  step above) with sibling tickets not yet resolved, or session context. Ask
  the user directly if it's ambiguous. This matters because a partial slice
  changes what "complete" means for Phase 2's intent-alignment check.
- **Summarize** for the user:
  - **Problem space** — the business intent behind the change: what need or
    problem this addresses, described through the relevant flow(s) (e.g. the
    current/prior flow, where applicable). This is about *why*, from a
    business angle — not a restatement of what the old code did.
  - **Solution space** — how that intent was solved: the approach taken,
    described through the resulting flow(s).
  - When a flow/state/pipeline is involved, show a Mermaid diagram of the
    prior flow (problem space) together with one of the resulting flow
    (solution space) — always paired, never the resulting flow alone. This
    pairing applies wherever a flow diagram shows up in this command's
    output, including inside Phase 2 findings.
  - The classification and reasoning.
  - If this is a partial slice: which part of the overall functionality this
    change delivers, and what's intentionally deferred.
- **Peer-review:** pause — ask "Any questions before we move to the review,
  or should we proceed to Phase 2?" Answer follow-ups, re-summarize if
  useful, proceed once the user says go.
- **Self-review:** present the summary and move straight into Phase 2 — no
  pause. The user already has the context; this summary is for confirmation,
  not a gate.
- **Context-review:** present the summary, answer any follow-up questions,
  then stop. Phase 2 never runs in this mode.

### 4. Phase 2 — Review (self-review and peer-review only)

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
  tooling — that's not this check's job.
- **Infra-swap behavior parity** — when a change replaces or swaps a core
  component (DI container, client, storage layer, etc.), trace the old code
  path against the new code path using Phase 1's context to see what
  actually needs to be preserved, and report what that tracing shows
  (preserved / a specific discrepancy / can't be determined from code
  alone). Do this by reading code — never by running the test suite; passing
  CI is already a merge prerequisite, and this check's value is the
  reasoning a test run doesn't give you.
- **Recurring-pattern check** — once a root-cause fix is identified for a
  specific risky API/primitive, grep the same module/integration for other
  usages of that primitive and flag them too.
- Leave interface-contract argument-order/arity mismatches to static
  analysis/type-checking tooling — this command doesn't re-check them.

**Scope of findings** — state this to the user up front each run: findings
focus on design, correctness, cross-cutting risk, and test adequacy for the
code actually in this diff. Style/formatting is lint/CI's to catch;
generated/vendored files sit outside the diff's real surface; risk findings
need a concrete precondition, not a theoretical one; pre-existing issues the
change didn't introduce are informational context alongside the primary
findings, not primary findings themselves. CI/dialect/environment/
version-matrix gaps aren't visible from a diff — call these out as "run the
full CI/lint matrix to catch this" rather than guessing. Every finding comes
from reading code and Phase 1's context; the test suite stays CI's to run.

**Severity and output:**
- Tag every finding **Blocking / Should-fix / Nit / FYI**, sorted by
  severity, each with a file:line citation.
- Cap Nit-level findings shown individually at 5; summarize any remainder as
  a count.
- "No blocking issues found" is a complete, valid outcome — only list
  findings that earned their place.
- Present the output as a numbered list in chat: severity, file:line,
  description.

### 5. Action Loop (self-review and peer-review only)

Present the full numbered list at once, then ask for a **single consolidated
response** dispositioning every point by number — e.g. "1, 3 approve; 2
skip; 4 improve: <replacement wording>". Accept any reasonable free-form
phrasing (grouped numbers, ranges, per-number notes). If the response leaves
any number's disposition unclear, ask one follow-up naming just the
unresolved numbers — don't re-present the whole list.

Once every point has a disposition:
- **Peer-review:** for each approved point, post it immediately as an inline
  GitHub PR comment (`gh api repos/{owner}/{repo}/pulls/{pull_number}/comments`,
  with `commit_id`, `path`, and `line` matching the citation) using the
  user's replacement wording for "improve" points. Skipped points get no
  action. Submitting an overall approve/request-changes/comment verdict is
  always the user's own call — this command doesn't do it.
- **Self-review:** for each approved point among the mechanically-automatable
  checks (unsafe-default question resolved, false-positive-prone test,
  infra-parity discrepancy with a concrete fix, recurring-pattern instance),
  apply the fix directly to the local file with the Edit tool, using the
  user's replacement approach for "improve" points. Judgment-requiring
  findings (design pivots, cross-subsystem root-cause hypotheses,
  doc/product judgment calls) are presented with a stated hypothesis
  regardless of disposition — the user acts on these themselves; this
  command's role is to surface the hypothesis clearly, not to apply it.
- If peer-review was chosen but no PR could be identified (Step 2), the
  numbered list and the user's dispositions are the final output, recorded
  in chat — same as self-review's baseline.

## Notes

- The default branch, ticket prefix, Jira instance, and PR template are
  always whatever gets detected or asked at runtime for this specific repo —
  this command carries none of them as fixed values.
- Argument-order/arity mismatches and ordering-dependent test flakiness are
  left entirely to static-analysis/lint tooling, which already covers them.
- This command never executes the test suite, never auto-applies a
  judgment-requiring fix, and never submits an overall PR review verdict on
  the user's behalf.
