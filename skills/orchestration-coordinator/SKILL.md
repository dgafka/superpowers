---
name: orchestration-coordinator
description: Coordinate Orca implementation across one or more Codex sub-worktrees when the user asks to execute an approved design through Orca or coordinate implementation workers
argument-hint: "[objective, sub-worktree dependencies, and optional run-wide guidance]"
---

# Orchestration Coordinator

## Overview

Coordinate an implementation objective from the main worktree. Implementation workers own code changes in their assigned sub-worktrees. Accept a clear objective, approved design, or existing task DAG. When needed, decompose a clear request into implementation sub-worktrees in session state.

**REQUIRED SUB-SKILL:** Load and apply dgafka:brainstorming on every invocation, before execution planning, to work out the solution with your human partner. When the conversation already contains an approved design, use that context and its existing approvals; work through unresolved solution decisions using brainstorming. Resume this coordinator after brainstorming returns the approved design.

Use the approved conversational design to plan execution. Inspect the repository to resolve execution details. When an unresolved question requires comparing solution approaches or changing the design, return that question to `brainstorming` and resume execution planning from the approved outcome.

**REQUIRED SUB-SKILL:** Use orchestration for the live, version-matched Orca task, Dispatch, dependency, ask/reply, and worker lifecycle commands.

**REQUIRED SUB-SKILL:** Use orca-cli for Orca worktree and terminal operations not covered by orchestration.

## Sub-worktree Context

Use **sub-worktree** for an implementation checkout and **sub-session** for a separate Codex terminal session within an existing worktree. Reserve **task** for Orca scheduling objects and their API fields.

Treat guidance supplied with the invocation as run-wide context. Preserve it across every task. Add task-specific guidance that narrows one assignment while preserving run-wide guidance and approved user decisions.

Give every implementation unit a short stable `implement-<topic>` name, such as `implement-payment-reschedule`. Reuse the exact name for the Orca task and its implementation sub-worktree. Use it in status and waiting messages; keep it out of PR titles.

Build the implementation DAG in Orca. Make ownership, dependencies, acceptance criteria, and verification commands explicit. Start all dependency-ready, conflict-free tasks concurrently.

## Complete Planning with a Delivery Proposal

At the end of implementation planning, before dispatch, present the
sub-worktree split in conversation. Refine an approved design or existing execution DAG
into separate deliverable units. Each unit must produce an observable outcome
that can be reviewed, verified, and delivered with its declared prerequisites.
Choose boundaries by deliverable outcome rather than by file or technical layer
alone.

Present a compact table with each `implement-<topic>` name, deliverable outcome,
a Description column, acceptance checks, prerequisites, execution wave, and
feature flag when needed. In Description, state the concrete implementation
steps assigned to that sub-worktree: affected components or interfaces, behavior
changes, and relevant integration or migration work. Carry these steps into
the execution box and worker prompt below.
Explain the execution and delivery order, which units can proceed in parallel,
and which must wait for a prerequisite's stable branch or integration. Resolve
shared-file conflicts and multiple-prerequisite Git bases before proposing a
concurrent wave. A single cohesive deliverable may use one sub-worktree.

### Incomplete Behavior Behind an Environment Variable

When a deliverable changes logic that is not ready until other units arrive,
require an environment-variable feature flag, disabled by default. With the
variable unset or disabled, preserve existing behavior and keep the incomplete
path inactive. Keep each intermediate delivery buildable and deployable with
its declared prerequisites; a runtime flag still requires compile-time and
migration dependencies to be satisfied.

In the proposal, specify the variable name and enabling value, disabled behavior,
remaining prerequisite units, and the unit responsible for verifying readiness
to enable it. Carry this contract into every affected worker assignment. Require
verification of disabled behavior and the enabled path; when prerequisites are
delivered, verify the integrated enabled path before reporting the flag ready
for activation. State activation conditions in the PR and completion report.

For example, pricing logic and checkout integration may be separate deliveries.
Deliver the pricing change with `ENABLE_NEW_PRICING=false` by default, preserving
current pricing. The checkout integration unit verifies both modes with the
completed pricing unit before reporting `ENABLE_NEW_PRICING=true` ready to enable.

Use the proposal to populate the execution boxes below. Keep the delivery
proposal in conversation, record the execution boxes and progress in
`launch-execution.md`, and keep the approved dependencies in Orca.

## Execution Record and Dispatch

Before dispatching new sub-worktrees, read [launch-execution-template.md](launch-execution-template.md), resolved from this skill directory. Use it to prepare one execution box per sub-worktree. Fill in every applicable field, including Description with the complete ordered implementation steps. Follow its model defaults and pass the displayed model explicitly at dispatch. Keep ownership boundaries and the verified Git base in the worker context. Sessions started in an existing sub-worktree use that worktree's execution context.

Follow that template's execution-record instructions to create or update
`launch-execution.md` in the main worktree before dispatch. Include every
sub-worktree's full box and maintain its progress as worker and sub-session
updates arrive. Link the file when presenting execution summaries so your
human partner can inspect the current record.

Dispatch each dependency-ready, conflict-free sub-worktree from the main worktree
after recording its execution box. Match the worker prompt to that box. If the
template cannot be loaded, resolve its location before dispatch. Record sessions
started in an existing sub-worktree against that worktree's execution history
and dispatch them directly. Create a new sub-worktree when a separate
implementation checkout is needed.

### Coordinator Self-review of Execution Boxes

The coordinator prepares the execution box and performs a
requirements-aware self-review before dispatch.
Compare the draft with the approved business requirements, conversational
design, run-wide guidance, delivery proposal, dependencies, acceptance checks,
feature-flag contract, and PR and observation commitments.

Resolve each mismatch by revising the scope, ordered steps, acceptance
checks, dependencies, or feature-flag contract. Route changes to approved
requirements to your human partner for a scope decision. Re-review each revision
before dispatch. Record each self-review result, correction, and revised box
in `launch-execution.md`.

When the box aligns, dispatch the worker. After dispatch, the worker validates the assignment
against the recorded box and reports any mismatch through Orca's blocking `ask/reply` flow. The coordinator
resolves the mismatch within approved scope or obtains the user's scope decision
before the worker resumes affected work.

Include `dgafka:create-pull-request` in the Discipline / Skill row and record
publication authorization separately in the PR row. When publication is not
authorized, the worker routes the completed PR preview to the coordinator for
a user decision. Name the `observe-<topic>` Codex sub-session in the implementation
worktree's execution context, using `dgafka:create-pull-request` in observation-only
mode `ci`, with findings routed to the original implementation worker. Dispatch
that observer directly after publication and retain the worker terminal for CI
fixes. Preserve an explicit user choice of manual/full observation.

Apply the model defaults in [launch-execution-template.md](launch-execution-template.md)
to both new sub-worktrees and new sub-sessions in existing worktrees, and pass
the selected model explicitly at launch.
Dispatch dependency-ready sub-worktrees and sub-sessions directly. Report each
name, purpose, and findings route in the execution record.

Create each implementation as a separate Orca child sub-worktree from the main coordinator worktree. Independent tasks use sibling sub-worktrees based on the agreed trunk. A dependent task uses its prerequisite's stable branch as its Git base. When a task depends on multiple sibling branches, ask how to linearize or integrate them before choosing a base.

Every implementation task prompt must include these instructions:

- Invoke `orchestration-sub-worktree` for the worker workflow.
- **REQUIRED SUB-SKILL:** Use dgafka:test-driven-development for every behavior change.
- Follow RED -> GREEN -> REFACTOR for each behavior-change increment: write one focused test, watch it fail for the expected reason, write the minimum implementation, watch it pass, then refactor while green. For standalone behavior-preserving refactoring, establish passing coverage and keep it green.
- **REQUIRED SUB-SKILL:** Use dgafka:create-pull-request after verification; create or reuse the ready-for-review PR against the approved target branch when publication is authorized, report its URL to the main coordinator, and trigger the configured CI observer in the same worktree.
- Report completion after verifying the final commit is pushed and matches the ready-for-review PR head. Report publication failures as blockers; a no-change unit reports that no PR is applicable.
- Include the publication authorization, observer mode and findings route, and original worker/Dispatch route in the prompt.
- Include the deliverable outcome, execution and delivery prerequisites, and any environment-variable feature flag contract from the delivery proposal.
- Copy the recorded execution box's Description into the prompt as ordered implementation steps, preserving every assigned step and its scope.
- Report progress against those numbered steps, plus blockers and verification evidence, through Orca so the coordinator can maintain `launch-execution.md`.
- Run only the focused inner-loop and task-relevant tests; broader repository coverage belongs to CI.

The coordinator remains in the main worktree.

## Questions and Decisions

Workers ask the coordinator through Orca's blocking `ask/reply` flow. Answer when approved context determines one unambiguous result. Ask the user when the answer changes behavior, scope, dependencies, acceptance criteria, or stack structure. Keep unrelated ready tasks moving while a decision is blocked.

## Requested Review Sub-sessions

Create `review-<topic>` only when the user explicitly requests a separate review
of the matching completed `implement-<topic>` sub-worktree. Track the review
sub-session as an Orca task depending on that implementation task.

Run the review sub-session in a separate Codex terminal within the implementation
sub-worktree against a stable commit. Pause
implementation edits during review; if the checkout changes, report that and
re-establish the reviewed commit before continuing. Its Orca task prompt must invoke `review-changes` in Orchestrated Review Mode and include:

- The matching implementation task, branch, base, and reviewed commit SHA
- The approved objective, decisions, scope, and acceptance criteria
- A local-diff target or a specific pull request
- Review focus, with the standard review checks as the default
- Whether inline PR comments are explicitly authorized

Local reviews and report-only PR reviews return findings through Orca without
external comments. A PR review may post inline comments only when the user's
request explicitly authorized them. The original implementation worker owns fixes.

Present the findings to the user and route approved fixes to the exact
`implement-<topic>` worker in its existing sub-worktree. After fixes, reuse the
exact `review-<topic>` sub-session to verify the same scope and commit delta. Keep
the implementation worker available through this review-and-fix cycle, and keep
unrelated dependency-ready tasks moving while review or fixes are in progress.

## Pull Requests

Orca dependencies are the execution source of truth. GitHub stacks express review and merge order.

Implementation workers own PR creation through `dgafka:create-pull-request`. The coordinator receives each PR URL and observer launch receipt, and reuses those ready-for-review PRs.

Accept implementation completion after the worker verifies that the final
commit is pushed, the ready-for-review PR head matches that commit, and the PR
targets the approved base. Report missing or failed publication as a blocker.
Accept `worker_done` and release dependencies after these publication checks and
the required observer launch receipt, honoring an explicit manual override.
For an approved no-change outcome, accept the worker's report that there is no
deliverable PR.

For each completed dependency chain:

1. Verify every branch is pushed to the approved repository and the history is linear.
2. Verify each existing PR targets its approved base: the agreed trunk for independent work, or the prerequisite branch for dependent work.
3. Link the existing ready-for-review PRs with GitHub's native stack workflow when supported. Inspect current `gh stack` help or official documentation first, and select an operation that links the existing ready-for-review PRs.
4. Confirm the configured CI observer is running in each implementation worktree. If the worker cannot dispatch it, launch that sub-session in the same Run and return its receipt. Preserve explicit manual/full overrides.
5. Treat independent dependency chains as separate stacks.

Report PR publication and CI results separately, including pending CI or observation blockers. Keep the original worker available for the correction cycle: record retention with Orca `worker-retain` after its Dispatch settles, then create a fresh fix task in the same worktree and reuse that exact terminal when findings arrive. Keep only one fix active per PR. Dispatch a replacement terminal in the same sub-worktree using its recorded scope and routing context, and record the replacement in the execution history. Release the retained worker after observation stops and outstanding fixes settle.

## Other Sub-sessions

Use sub-sessions in an existing worktree for CI/PR observation and explicitly requested independent verification. Dispatch each directly in that existing worktree and record its execution context. Observation follows `create-pull-request`; verification receives explicit task-relevant checks and returns evidence to the implementation worker.

Keep routine tests and follow-up fixes with the original implementation worker. Sub-sessions share files and services: coordinate tests that write generated files or use shared services, and serialize conflicting activity. A new independent implementation still requires a sub-worktree.

Reuse the existing worktree context when continuing a sub-session within its scope, such as re-review after fixes or another observation pass. Report a changed objective or acceptance criteria to the user for a scope decision.

## Coordination Discipline

- Update `launch-execution.md` from each worker or sub-session report using the execution-record instructions in `launch-execution-template.md`; preserve recorded boxes and add progress beneath them.
- Use Orca dependencies and `task-list --ready` rather than mental scheduling.
- Report exact sub-worktree or sub-session names and whether each is running, ready, blocked, or awaited.
- Treat timeouts as checkpoints while workers remain live.
- After accepted completion, reuse the exact worker for an immediate follow-up, retain it through the observation cycle, or release it through Orca once observation and outstanding fixes have ended.
- Reuse the exact reviewer for re-review after approved fixes.
- Obtain user authorization for stack merges, worktree deletion, and branch removal before performing those actions.
