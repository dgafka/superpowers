# Design Spec: `/review-changes` command

**Date:** 2026-07-17
**Status:** Approved, ready for implementation

## Required Skills

_No specific skills required beyond defaults._

## Goal

Add a generic, portable slash command `commands/review-changes.md` that reviews a set of code changes — either a GitHub pull request or the current branch's diff — through a two-phase process: first building and confirming understanding of *why* the change exists and *what* it does at a high level, then running a structured, severity-tiered review whose findings the user can act on immediately (posting agreed-upon points as inline PR comments, or applying agreed-upon fixes locally). Like `create-pull-request.md`, everything repo-specific (PR template, ticket format, Jira instance) is detected or asked, never hardcoded. The command's review focus and voice are informed by two research tracks: how mature review processes (human and AI) structure themselves, and the reviewer's own observed review-comment history on a real codebase — both distilled into portable, generic principles rather than project-specific rules.

## Deliverable

A single self-contained file: `commands/review-changes.md`. No supporting reference files — self-contained and portable, following the same pattern as `create-pull-request.md`.

### Frontmatter

- `name: review-changes`
- `description`: triggers on requests to review a PR, review the current branch's changes, review changes before opening a PR, or the explicit `/review-changes` invocation.
- `allowed-tools`: `Bash(gh pr view:*)`, `Bash(gh pr diff:*)`, `Bash(gh api:*)`, `Bash(git diff:*)`, `Bash(git log:*)`, `Bash(git status:*)`, `Bash(git branch:*)`, `Bash(git rev-parse:*)`, `Bash(git symbolic-ref:*)`, `Bash(git remote:*)`. (`Edit`/`Read` are core tools, not declared here; if a Jira-related MCP tool is available in-session, use it dynamically — never hardcode a specific MCP tool name, since installations vary.)
- `disable-model-invocation: false`

## Process

### 1. Input source detection

- Argument is a GitHub PR reference (URL or `owner/repo#123`) → fetch via `gh pr view`/`gh pr diff` for that PR.
- No argument → diff the current branch against its detected default branch, reusing `create-pull-request.md`'s detection: `git symbolic-ref refs/remotes/origin/HEAD` (strip to branch name), probing `main` then `master` if that fails. **Never assume `main`.**
- **Guard:** if diffing the current branch and it *is* the default branch, stop and tell the user there's nothing to diff against.

### 2. Mode & focus (explicit, upfront, both apply regardless of input source)

- Ask explicitly: **self-review** or **peer-review**? (Not inferred from input source — a PR link can be self-reviewed, e.g. to apply local fixes before merge; a local branch diff can be peer-reviewed, e.g. reviewing a colleague's checked-out branch.)
- Immediately after, ask: "Anything specific you'd like this review to focus on or verify?" — optional, blank means standard checks only. The answer feeds Phase 1's context-gathering and Phase 2's checks, not just a final filter.
- If peer-review is chosen and no PR argument was given, try to auto-detect an open PR for the current branch (`gh pr view` with no arguments resolves the PR tied to the current branch). If none exists, tell the user inline posting won't be available for this run and proceed chat-only (Phase 2's action loop still runs, just without the posting mechanism).
- No subagent option — this command always runs in the current session.

### 3. Phase 1 — Understanding (always runs, both modes)

Gather context in parallel:
- The diff itself (`gh pr diff` or `git diff <base>...HEAD`).
- PR title/description if reviewing a PR (`gh pr view`).
- A ticket reference detected from the branch name or PR body via a generic pattern (e.g. `[A-Z]+-\d+`) — never a hardcoded project prefix.
- **Best-effort Jira fetch:** if a ticket key is found *and* a Jira-related MCP tool or CLI is available in the session, fetch that ticket's details. If the ticket has a parent epic, also fetch the epic's title/description for higher-level context. Skip silently (no error, no blocking) if no ticket is found or no Jira tool is available — never hardcode an instance URL or project key.
- Current session context, if this review relates to work already discussed in the conversation.
- The user's stated focus areas from Step 2.

Then:
- **Classify the change:** business change / technical change / refactor / mixed. State the classification and why — don't gate on it, the user can redirect if it looks wrong.
- **Detect scope slicing:** determine whether this change is a partial slice of larger functionality with more PRs still to come, using signals like staged/part/phase language in the PR description or commit messages, an epic (fetched per the Jira step above) with sibling tickets not yet resolved, or explicit session context. If ambiguous, ask the user directly. This matters because it changes what "complete" means for the intent-alignment check in Phase 2 — a partial slice should be judged against its own stated scope, not the full epic.
- **Summarize** the change for the user:
  - **Problem space** — the business intent behind the change: what need or problem is being addressed, described through the relevant flow(s) (e.g. the current/prior flow where applicable). This is about *why*, from a business perspective — not merely "what the old code did."
  - **Solution space** — how that business intent was solved: the approach chosen to address it, described through the relevant resulting flow(s). Include a Mermaid diagram of both the *prior* flow (problem space) and the *resulting* flow (solution space) together whenever a flow/state/pipeline is involved. (Deliberately both, unlike `create-pull-request.md`'s after-only convention — this phase's goal is comprehension, not PR-body brevity. This old+new pairing applies everywhere a flow diagram appears in this command's output, including inside Phase 2 findings that reference a flow change.)
  - The change classification and reasoning.
  - **If this is a partial slice:** state explicitly which part of the overall functionality this change aims to deliver, and what's intentionally deferred to later PRs.
- **Peer-review:** pause and ask "Any questions before we move to the review, or should we proceed to Phase 2?" Answer follow-ups, re-summarize if needed, proceed once the user says go.
- **Self-review:** present the same summary, then proceed straight into Phase 2 without pausing — the user already has the context; the summary is for confirmation, not a gate.

### 4. Phase 2 — Review

Structure the review in this order, weighted by the Phase 1 classification:

1. **Design/architecture** — is this the right approach, does it fit existing patterns, is it more complex than needed. Checked first — a wrong design makes line-level findings moot.
2. **Correctness**, including an explicit **intent-alignment check**: does the diff actually do what Phase 1's gathered context (PR description, ticket, epic) claims it does, and does it cover the stated acceptance criteria — not just "is the code locally correct." When Phase 1 detected this change as a partial slice, judge intent-alignment against the stated slice scope, not the full epic — don't flag deferred-to-later-PR work as missing. Weighted heavily for business changes (the diff alone can't answer "does this satisfy the ticket"); for refactors, this check instead asks whether scope stayed within what was described (flag if a refactor silently expanded into a behavior change).
3. **Cross-cutting risk**, sized to classification: business change → downstream/consumer impact, backward compatibility with existing/in-flight data when a rule changes; technical change → concurrency/failure-mode scenarios (traced concretely, not abstractly), migration/schema-change safety, cross-service blast radius, code reuse over duplication; refactor → behavior-preservation.
4. **Tests** — is the new/changed logic actually covered, by the right kind of test.
5. **Style/naming/docs** — last, and only where not already enforced by lint/CI; includes domain terminology precision (names that don't match what they represent).

**Reviewer voice** (generalized from observed review-comment history, stated as portable principles, not project-specific rules):
- Favor concrete, evidence-grounded failure scenarios over abstract risk statements.
- Question necessity before design (YAGNI) on new classes, methods, events, or test scenarios.
- Ask terse clarifying questions rather than asserting when something is ambiguous.
- Check backward compatibility with real existing/persisted data whenever a rename, schema change, or logic change touches state that may already exist.
- Keep tone direct and concrete — not hedge-y, generic AI-report prose.
- Explicitly separate "worth discussing" from "blocking" — comfortable surfacing a real concern while still tagging it non-blocking.

**Concrete checks library** (mechanically-defined, feeding directly into severity and self-review fix-eligibility):
- **Unsafe permissive defaults on mode-relevant flags** — a new boolean parameter whose name implies a mode switch (`rebuild`, `dryRun`, `force`, `live`) shipping with a default that reads as the silent/normal case. Surface as a question to the user ("should this be required instead?") — this is a judgment call, not an auto-fix.
- **Missing placement validation for new positional attributes/decorators** — a new attribute/annotation whose effect depends on where it's placed, with no compile-time/config-time guard against misplacement.
- **False-positive-prone tests** — tests that could pass even if the mechanism under test were broken, for an unrelated reason. Scope is deliberately narrower than the full category: cover missing-negative-assertion (happy-path-only tests with no check for the negative/absence case) and wrong-synchronicity-assumption (unnecessary polling/waiting for something that's actually synchronous, or a missing wait for something actually async) shapes. **Ordering-dependent assertions are explicitly excluded** — that's a static-analysis/lint concern (e.g. PHPStan-class tooling), not this command's job to re-check.
- **Infra-swap behavior parity** — when a change replaces or swaps a core component (DI container, client, storage layer, etc.), verify preservation of behavior by **tracing the old code path against the new code path using Phase 1's context** to know what actually needs to be preserved. Report what the logic tracing shows (preserved / a specific discrepancy found / can't be determined from code alone). **Never verify by executing the test suite** — passing CI is already a merge prerequisite and re-running tests is not this command's job.
- **Recurring-pattern grep** — once a root-cause fix is identified for a specific risky API/primitive, search the same module/integration for other usages of that same primitive and flag them too.
- **Interface-contract argument-order/arity mismatches are explicitly excluded** — that class of bug belongs to static analysis/type-checking tooling, not a re-implemented manual check here.

**Explicit non-goals**, stated to the user up front each run:
- Style/formatting already enforced by lint/CI.
- Generated or vendored files.
- Theoretical risks needing unlikely preconditions.
- Pre-existing issues the change didn't introduce (mentioned as informational at most, never as a primary finding).
- CI/dialect/environment/version-matrix gaps — not diff-reviewable; note that running the full CI/lint matrix before opening the PR is the only reliable catch for this category.
- Test execution of any kind — findings are always grounded in reading code + Phase 1 context, never in running the test suite.

**Severity & output:**
- Every finding tagged **Blocking / Should-fix / Nit / FYI**, sorted by severity, with a file:line citation.
- Cap Nit-level findings shown individually (e.g. 5); summarize the rest as a count.
- "No blocking issues found" is a valid, complete outcome — don't manufacture findings to pad the list.
- Output is a numbered list in chat: severity, file:line, description.

### 5. Action loop

Present the full numbered list at once and ask the user for a **single consolidated response** that dispositions every point by number — e.g. "1, 3 approve; 2 skip; 4 improve: <replacement wording>". Don't walk the list one point at a time waiting for a reply after each. Accept any reasonable free-form phrasing of that response (grouped numbers, ranges, per-number notes); if the response leaves any point's disposition ambiguous, ask a single follow-up listing just the unresolved numbers rather than re-presenting the whole list.

Once every point has a disposition, execute them:
- **Peer-review:** for each approved point, post it as an inline GitHub PR comment via `gh api repos/{owner}/{repo}/pulls/{pull_number}/comments` at the cited file:line (using the user's replacement wording for "improve" points). Skipped points get no action. **Never submit an overall approve/request-changes/comment verdict** — that judgment call belongs to the user.
- **Self-review:** for each approved point among the mechanically-automatable checks (unsafe-default question resolved, false-positive-prone test, infra-parity discrepancy with a concrete fix, recurring-pattern instance), apply the fix directly in the current session (Edit tool) to the local file (using the user's replacement approach for "improve" points). Judgment-requiring findings (design pivots, cross-subsystem root-cause hypotheses, doc/product judgment calls) are presented with a stated hypothesis and never auto-fixed regardless of disposition — approving one of these means the user will act on it themselves, not that the command applies it.
- If peer-review was chosen but no PR could be identified (Step 2's auto-detect found nothing), the numbered list and the user's dispositions are recorded in chat only — no posting mechanism is offered, same as self-review's baseline.

## Guardrails

- Never hardcode a Jira instance URL, project key, ticket prefix, or PR template structure — detect, use the PR template if found (reuse `create-pull-request.md`'s detection order: `.github/PULL_REQUEST_TEMPLATE.md`, repo root, `docs/`, `.github/PULL_REQUEST_TEMPLATE/`), or ask.
- Never assume the default branch is `main` — detect it.
- Never execute the test suite as part of verification.
- Never submit an overall PR review verdict on the user's behalf.
- Never auto-apply a judgment-requiring fix in self-review — flag with a hypothesis and stop.
- Never re-check argument-order/arity mismatches or ordering-dependent test flakiness — both belong to static-analysis/lint tooling.

## Verification

A command file is prose, not executable code — no unit test. Verify by:
1. Self-review against every requirement in this spec (mode question, focus prompt, Phase 1 context-gathering and diagram pairing, classification, Phase 2's phased checks and checks library, severity taxonomy, action loop per mode, guardrails).
2. A real dry-run in both modes: peer-review against an actual open PR (confirm it detects context, produces the old+new diagram pairing, classifies correctly, and produces a preview of inline comments **before** posting anything — no comments actually posted during verification unless explicitly confirmed) and self-review against the current branch (confirm findings split correctly into fix-eligible vs. flag-only, and no local file is edited during verification unless explicitly confirmed).

## Out of scope

- Subagent dispatch for this command (always runs in the current session).
- Dynamic, per-repo recalibration of the reviewer's voice/focus (static principles only, per this spec).
- Executing the test suite for verification purposes.
- Auto-applying judgment-requiring fixes.
- Submitting an overall PR review verdict (approve/request-changes) on GitHub.
