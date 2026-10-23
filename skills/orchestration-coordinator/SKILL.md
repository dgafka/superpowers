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

## Prepare plan.md Before Execution

Before dispatching any implementation, write `plan.md` at the root of the main
worktree from the approved conversational design. Each checklist point is one
separately deliverable unit owned by one `implement-<topic>` sub-worktree and
represented by one Orca task. Choose boundaries by observable outcome that can
be reviewed, verified, and merged independently with its declared prerequisites.

Group independent, conflict-free units into the same numbered wave. Place units
that depend on those outcomes in later waves. Resolve shared-file conflicts by
adjusting scope or separating waves. Even a single unit uses one wave.

For each unit include its outcome, owned scope, concrete ordered implementation
steps, prerequisites, acceptance checks, and any feature-flag contract. Keep
PR publication authorization, the agreed target branch, and run-wide guidance
with the plan so worker assignments preserve the approved decisions.

Use this compact structure, expanding each unit only as needed:

```markdown
# Execution plan

Objective: <approved outcome>
Target branch: <agreed integration branch>
PR publication: <existing authorization or decision still needed>
Run-wide guidance: <applicable instructions>

## Wave 1

- [ ] implement-<topic>: <separately deliverable outcome>
  - Scope and steps: <components, behavior, integration work>
  - Prerequisites: <none or earlier merged units>
  - Acceptance: <observable checks and verification commands>
  - Feature flag: <contract when applicable>

## Wave 2

- [ ] implement-<dependent-topic>: <next deliverable outcome>
  - Scope and steps: <implementation steps>
  - Prerequisites: <Wave 1 unit names>
  - Acceptance: <checks>
```

Present and link the completed plan before starting execution. Self-review it
against approved requirements, scope, dependencies, and acceptance checks;
resolve mismatches before dispatch. Use existing authorization to execute.
Route changes to approved requirements to your human partner for a decision.

Keep `plan.md` limited to the execution plan and merge completion. Keep live
progress, worker identifiers, dispatch receipts, questions, CI findings, and
routing details in Orca and conversation.

### Incomplete Behavior Behind an Environment Variable

When a deliverable changes logic that is not ready until other units arrive,
require an environment-variable feature flag, disabled by default. With the
variable unset or disabled, preserve existing behavior and keep the incomplete
path inactive. Keep each intermediate delivery buildable and deployable with
its declared prerequisites; a runtime flag still requires compile-time and
migration dependencies to be satisfied.

In the plan, specify the variable name and enabling value, disabled behavior,
remaining prerequisite units, and the unit responsible for verifying readiness
to enable it. Carry this contract into every affected worker assignment. Require
verification of disabled behavior and the enabled path; when prerequisites are
delivered, verify the integrated enabled path before reporting the flag ready
for activation. State activation conditions in the PR and completion report.

For example, pricing logic and checkout integration may be separate deliveries.
Deliver the pricing change with `ENABLE_NEW_PRICING=false` by default, preserving
current pricing. The checkout integration unit verifies both modes with the
completed pricing unit before reporting `ENABLE_NEW_PRICING=true` ready to enable.

## Dispatch the Current Wave

Create each unit in the current wave as a separate Orca child sub-worktree from
the main coordinator worktree. Base each checkout on the updated agreed target
branch containing the preceding waves' merges. Verify prerequisite changes are
present before dispatch. Dispatch all conflict-free units in the current wave
concurrently, using Orca for scheduling within that wave.

Copy each unit's plan scope, ordered steps, and acceptance checks into its worker
prompt. After dispatch, the worker validates the assignment against that plan
unit and reports mismatches through Orca's blocking `ask/reply` flow. Resolve
mismatches within approved scope or obtain the user's scope decision.

Default to `codex / gpt-6.1-sol` for every implementation and sub-session,
including review, observation, and verification. Preserve user model overrides
and pass the selected model explicitly at launch. If unavailable, report the
blocker and ask the user to choose a replacement. Other skills launching an
observer independently use the same default.

Include PR publication authorization in the worker prompt. When publication is
not authorized, the worker routes the completed PR preview to the coordinator
for a user decision. Configure an `observe-<topic>` sub-session in the same
implementation worktree using `dgafka:create-pull-request` in observation-only
mode `ci`, with findings routed to the original worker. Preserve explicit
manual/full overrides and retain the worker for CI fixes.

### Advance After Merge

Mark a unit checked in `plan.md` only after verifying its PR is merged into the
agreed target branch; add the merged PR link beside it. A published PR, passing
CI, or `worker_done` establishes worker progress, not merge completion.

Start the next wave only after every unit in the current wave is merged.
Enforce this gate even when Orca reports a later task as dependency-ready.
A blocked or closed-unmerged PR keeps the wave open. For an approved no-change
outcome, ask your human partner to remove or revise that unit in the plan;
represent it according to that decision rather than marking it merged.
Merge only with user authorization already present or newly obtained.

When resuming, reconcile plan checkboxes with actual PR merge state and Orca
assignments before dispatching. Reuse existing workers for active units and
continue the earliest unfinished wave. Revise remaining plan units when an
approved scope change affects them, before dispatching that work.

Every implementation task prompt must include these instructions:

- Invoke `orchestration-sub-worktree` for the worker workflow.
- **REQUIRED SUB-SKILL:** Use dgafka:test-driven-development for every behavior change.
- Follow RED -> GREEN -> REFACTOR for each behavior-change increment: write one focused test, watch it fail for the expected reason, write the minimum implementation, watch it pass, then refactor while green. For standalone behavior-preserving refactoring, establish passing coverage and keep it green.
- **REQUIRED SUB-SKILL:** Use dgafka:create-pull-request after verification; create or reuse the ready-for-review PR against the approved target branch when publication is authorized, report its URL to the main coordinator, and trigger the configured CI observer in the same worktree.
- Report completion after verifying the final commit is pushed and matches the ready-for-review PR head. Report publication failures as blockers; a no-change unit reports that no PR is applicable.
- Include the publication authorization, observer mode and findings route, and original worker/Dispatch route in the prompt.
- Include the deliverable outcome, execution and delivery prerequisites, and any environment-variable feature flag contract from the plan.
- Copy the plan unit's ordered implementation steps into the prompt, preserving every assigned step and its scope.
- Report meaningful progress, blockers, and verification evidence through Orca.
- Run only the focused inner-loop and task-relevant tests; broader repository coverage belongs to CI.

The coordinator remains in the main worktree.

## Questions and Decisions

Workers ask the coordinator through Orca's blocking `ask/reply` flow. Answer when approved context determines one unambiguous result. Ask the user when the answer changes behavior, scope, dependencies, acceptance criteria, or wave order. Keep unrelated ready tasks in the current wave moving while a decision is blocked.

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
unrelated current-wave tasks moving while review or fixes are in progress.

## Pull Requests

`plan.md` defines wave and merge order. Orca schedules eligible work within the current wave.

Implementation workers own PR creation through `dgafka:create-pull-request`. The coordinator receives each PR URL and observer launch receipt, and reuses those ready-for-review PRs.

Accept implementation completion after the worker verifies that the final
commit is pushed, the ready-for-review PR head matches that commit, and the PR
targets the approved base. Report missing or failed publication as a blocker.
Accept `worker_done` after these publication checks and
the required observer launch receipt, honoring an explicit manual override.
For an approved no-change outcome, accept the worker's report that there is no
deliverable PR.

Verify each existing PR targets the agreed integration branch. Confirm its
configured CI observer is running; if the worker cannot dispatch it, launch
that sub-session in the same Run and return its receipt. Preserve explicit
manual/full overrides. Verify merge state before checking off the plan unit.

Report PR publication and CI results separately, including pending CI or observation blockers. Keep the original worker available for the correction cycle: record retention with Orca `worker-retain` after its Dispatch settles, then create a fresh fix task in the same worktree and reuse that exact terminal when findings arrive. Keep only one fix active per PR. Dispatch a replacement terminal in the same sub-worktree using its recorded scope and routing context, and report the replacement through Orca. Release the retained worker after observation stops and outstanding fixes settle.

## Other Sub-sessions

Use sub-sessions in an existing worktree for CI/PR observation and explicitly requested independent verification. Dispatch each directly in that existing worktree and include its scope and routing in the Orca prompt. Observation follows `create-pull-request`; verification receives explicit task-relevant checks and returns evidence to the implementation worker.

Keep routine tests and follow-up fixes with the original implementation worker. Sub-sessions share files and services: coordinate tests that write generated files or use shared services, and serialize conflicting activity. A new independent implementation still requires a sub-worktree.

Reuse the existing worktree context when continuing a sub-session within its scope, such as re-review after fixes or another observation pass. Report a changed objective or acceptance criteria to the user for a scope decision.

## Coordination Discipline

- Update `plan.md` when a merge is verified or an approved plan change is needed.
- Use Orca dependencies and `task-list --ready` within the current wave; apply the merge gate before releasing the next wave.
- Report exact sub-worktree or sub-session names and whether each is running, ready, blocked, or awaited.
- Treat timeouts as checkpoints while workers remain live.
- After accepted completion, reuse the exact worker for an immediate follow-up, retain it through the observation cycle, or release it through Orca once observation and outstanding fixes have ended.
- Reuse the exact reviewer for re-review after approved fixes.
- Obtain user authorization for PR merges, worktree deletion, and branch removal before performing those actions.
