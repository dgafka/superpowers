---
name: orchestration-coordinator
description: Use when the user explicitly requests Orca-coordinated implementation across one or more Codex implementation sub-worktrees, or recognize-and-learn hands over an approved implementation direction
argument-hint: "[objective, sub-worktree dependencies, and optional run-wide guidance]"
---

# Orchestration Coordinator

## Overview

Coordinate an implementation objective from the main worktree. Implementation workers own code changes in their assigned sub-worktrees. Accept a clear objective, approved design, or existing task DAG. When needed, decompose a clear request into implementation sub-worktrees in session state.

**REQUIRED SUB-SKILL:** Load and apply superpowers:brainstorming on every invocation, before execution planning, to work out the solution with your human partner. When the conversation already contains an approved design, use that context and its existing approvals; work through unresolved solution decisions using brainstorming. Resume this coordinator after brainstorming returns the approved design.

Use the approved conversational design to plan execution. Inspect the repository to resolve execution details. When an unresolved question requires comparing solution approaches or changing the design, return that question to `brainstorming` and resume execution planning from the approved outcome.

**REQUIRED SUB-SKILL:** Use orchestration for the live, version-matched Orca task, Dispatch, dependency, ask/reply, and worker lifecycle commands.

**REQUIRED SUB-SKILL:** Use orca-cli for Orca worktree and terminal operations not covered by orchestration.

## Sub-worktree Context

Use **sub-worktree** for an implementation checkout and **sub-session** for a separate Codex terminal session within an existing worktree. Reserve **task** for Orca scheduling objects and their API fields.

Treat guidance supplied with the invocation as run-wide context. Preserve it across every task. Add task-specific guidance that narrows one assignment while preserving run-wide guidance and approved user decisions.

Give every implementation unit a short stable `implement-<topic>` name, such as `implement-payment-reschedule`. Reuse the exact name for the Orca task and its implementation sub-worktree. Use it in status and waiting messages; keep it out of PR titles.

Build the implementation DAG in Orca. Make ownership, dependencies, acceptance criteria, and verification commands explicit. Start all approved, dependency-ready, conflict-free tasks concurrently.

## Complete Planning with a Delivery Proposal

At the end of implementation planning, before launch confirmations, propose the
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

Use the proposal to populate the launch confirmations below. Keep the delivery
plan in conversation and the approved dependencies in Orca.

## Approval and Dispatch

Before preparing launches, read [launch-confirmation.md](launch-confirmation.md), resolved from this skill directory. Use its contents to render the sub-worktree execution box: one fully populated confirmation table for each proposed launch, visible in conversation before creating the sub-worktree or triggering its worker. Fill in every applicable field, including Description with the complete ordered implementation steps for that worktree. Follow its model defaults and pass the displayed model explicitly at dispatch. Keep ownership boundaries and the verified Git base in the worker context.

Before each launch, verify that its execution box has been shown, explicitly approved, and matches the worker prompt. A delivery overview or design approval is followed by this concrete launch confirmation. If the template cannot be loaded, resolve its location before preparing or dispatching launches. If a box is missing or its scope has changed, show the complete box and obtain approval before proceeding. Reuse an unchanged box and its approval already present in the conversation.

Include `superpowers:create-pull-request` in the Discipline / Skill row and ready-for-review publication in the PR row. Also present a separate table for the named `observe-<topic>` Codex sub-session in that implementation worktree, using `superpowers:create-pull-request` in observation-only mode `ci`, with findings routed to the original implementation worker. Approval covers publication after verification and retention of that worker terminal for CI fixes. Preserve an explicit user choice of manual/full observation.

Ask the user to confirm the presented sub-worktree and observer launch. One message may present a concurrent wave, with one table per launch; every launch must be individually identifiable and explicitly approved. Dispatch only approved launches. Reuse approval of an unchanged table at dispatch.

Create each implementation as a separate Orca child sub-worktree from the main coordinator worktree. Independent tasks use sibling sub-worktrees based on the agreed trunk. A dependent task uses its prerequisite's stable branch as its Git base. When a task depends on multiple sibling branches, ask how to linearize or integrate them before choosing a base.

Every implementation task prompt must include these instructions:

- Invoke `orchestration-sub-worktree` for the worker workflow.
- **REQUIRED SUB-SKILL:** Use superpowers:test-driven-development for every behavior change.
- Follow RED -> GREEN -> REFACTOR for each increment: write one focused test, watch it fail for the expected reason, write the minimum implementation, watch it pass, then refactor while green.
- **REQUIRED SUB-SKILL:** Use superpowers:create-pull-request after verification; create or reuse the ready-for-review PR against the approved target branch, report its URL to the main coordinator, and trigger the approved CI observer in the same worktree.
- Include the publication authorization, concrete observer approval, and original worker/Dispatch route in the prompt.
- Include the deliverable outcome, execution and delivery prerequisites, and any environment-variable feature flag contract from the delivery proposal.
- Copy the approved execution box's Description into the prompt as ordered implementation steps, preserving every assigned step and its scope.
- Run only the focused inner-loop and task-relevant tests; broader repository coverage belongs to CI.

The coordinator remains in the main worktree.

## Questions and Decisions

Workers ask the coordinator through Orca's blocking `ask/reply` flow. Answer when approved context determines one unambiguous result. Ask the user when the answer changes behavior, scope, dependencies, acceptance criteria, or stack structure. Keep unrelated ready tasks moving while a decision is blocked.

## Requested Review Sub-sessions

Create `review-<topic>` only when the user explicitly requests a separate review
of the matching completed `implement-<topic>` sub-worktree. Track the review
sub-session as an Orca task depending on that implementation task.

Before launching the review sub-session, present the same confirmation table,
using Sub-session as the name row and identifying the existing worktree, review
commit, review focus, and external-comment permission. Obtain confirmation.

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

Implementation workers own PR creation through `superpowers:create-pull-request`. The coordinator receives each PR URL and observer launch receipt, and reuses those ready-for-review PRs.

For each completed dependency chain:

1. Verify every branch is pushed to the approved repository and the history is linear.
2. Verify each existing PR targets its approved base: the agreed trunk for independent work, or the prerequisite branch for dependent work.
3. Link the existing ready-for-review PRs with GitHub's native stack workflow when supported. Inspect current `gh stack` help or official documentation first, and select an operation that links the existing ready-for-review PRs.
4. Confirm the approved CI observer is running in each implementation worktree. If the worker cannot dispatch it, launch that exact approved sub-session in the same Run and return its receipt. Preserve explicit manual/full overrides.
5. Treat independent dependency chains as separate stacks.

Report PR publication and CI results separately, including pending CI or observation blockers. Keep the original worker available for the approved correction cycle: record retention with Orca `worker-retain` after its Dispatch settles, then create a fresh fix task in the same worktree and reuse that exact terminal when findings arrive. Keep only one fix active per PR. A replacement terminal requires a new confirmation table. Release the retained worker after observation stops and outstanding fixes settle.

## Other Sub-sessions

Use sub-sessions in an existing worktree for CI/PR observation and explicitly requested independent verification. Show the shared confirmation table and obtain approval before launching each. Observation follows `create-pull-request`; verification receives explicit task-relevant checks and returns evidence to the implementation worker.

Keep routine tests and follow-up fixes with the original implementation worker. Sub-sessions share files and services: coordinate tests that write generated files or use shared services, and serialize conflicting activity. A new independent implementation still requires a sub-worktree.

Reuse the existing approval when continuing a sub-session within its approved scope, such as re-review after fixes or another observation pass. A new terminal or changed scope requires a new table and confirmation.

## Coordination Discipline

- Use Orca dependencies and `task-list --ready` rather than mental scheduling.
- Report exact sub-worktree or sub-session names and whether each is running, ready, blocked, or awaited.
- Treat timeouts as checkpoints while workers remain live.
- After accepted completion, reuse the exact worker for an immediate follow-up, retain it through the approved observation cycle, or release it through Orca once observation and outstanding fixes have ended.
- Reuse the exact reviewer for re-review after approved fixes.
- Obtain user authorization for stack merges, worktree deletion, and branch removal before performing those actions.
