# Launch Execution Template

Record each new sub-worktree before dispatch. Dispatch dependency-ready,
conflict-free launches directly from the main worktree. Record sub-sessions in
their existing worktree's execution history and dispatch them directly. A
sub-session is a separate Codex terminal session within that worktree.

## Create and Maintain the Execution Record

When preparing the first launches, the coordinator creates
`launch-execution.md` at the root of the main coordinator worktree. Record the
objective and Orca Run identifier, then add one section per named implementation
sub-worktree containing its complete execution box using the template below.
Record observers, reviewers, and verification sessions as execution-history
entries containing their name, purpose, agent and model, scope, reviewed commit
when applicable, comment permission, routing context, and dispatch receipt.
Show the execution plan in conversation and link the record in progress updates.

For each box, track execution beneath it:

- Current status and last update time
- Implementation step checklist matching the numbered Description steps
- Worker and Orca task identifiers, branch, and execution location once known
- Latest progress, verification evidence and checked commit, PR URL, CI and
  review results, blockers, and next action
- Timestamped updates with the reporting worker or observer and its evidence
- Self-review result against the approved business requirements; when it does
  not align, the exact mismatch, coordinator revision, and re-review result
- Dispatch timestamp and receipt for the named launch

The coordinator owns this file. Update the matching section after each launch,
worker progress report, question or blocker, verification result, PR publication,
observer or reviewer finding, fix, and completion report. Mark steps complete
from reported evidence and keep implementation completion, CI, review, and
integration status separate. Record pending or failed checks explicitly.

When launch scope changes, append the revised box and preserve the previous
version. Route changes to the approved objective or acceptance criteria to the
user for a scope decision. Resume an existing record for the same Run; for a
new Run, preserve the previous contents in an archive before creating the new
record. On resumption, reconcile the record with current Orca state and worker
reports. Orca remains the scheduling source of truth; this file presents the
assignments and their execution history to your human partner.

## Execution Box Template

| Field | Execution context |
|---|---|
| Sub-worktree | Exact implementation sub-worktree name |
| Goal | Intended deliverable outcome |
| Description | Complete ordered implementation steps for this sub-worktree |
| Execution | New child sub-worktree; agent and model |
| Dependencies | Prerequisite names or none |
| Discipline / Skill | Worker skill and relevant execution rules |
| Verification | Acceptance checks |
| Guidance | Relevant user instructions, or none |
| PR | When applicable: target, stack position, publication authorization, observation mode and findings route |

Use the defined table rows. Preserve scope ownership and the verified Git
base in the internal worker context. Use short cells with readable labels.
Keep Description concrete and complete: identify the affected components or
interfaces, behavior changes, integration or migration work, and feature flag
work when applicable. Number the steps within the cell, using line breaks for
readability. Match the delivery proposal's Description column and copy these
steps into the worker prompt. Include verification and publication work in
their dedicated rows so the box describes the full assignment. Omit the PR row
when it does not apply. Record review comment authorization in the reviewer
session entry using the user's explicit permission.

Show the model beside the agent in execution boxes and summaries. Default to
`codex / gpt-6.1-sol` unless the user specifies another agent or model. Preserve
explicit choices from run-wide or assignment-specific guidance. Apply this to
every sub-worktree and sub-session, including research,
review, observation, and verification. Pass the displayed model explicitly when
launching. If the runtime cannot resolve the selected model, report the blocker
and ask the user to choose a replacement.

Record each launch before dispatch. For concurrent ready sub-worktrees, create
one box per named implementation and dispatch each without waiting for a launch
decision. Record every sub-session's name, purpose, worker route, and start result
in the existing worktree's execution history.

For implementation launches, the Discipline / Skill row includes
`dgafka:create-pull-request` alongside the implementation and TDD skills. The
PR row states the target and stack position, publication authorization, and the
named observer, mode, existing worktree, and findings route. The observer uses
`dgafka:create-pull-request` in observation-only mode `ci` in a separate Codex
terminal in that implementation worktree, with findings sent to the original
worker. If publication is not authorized, the worker routes the completed PR
preview to the coordinator for a user decision. After publication, dispatch the
observer directly in the implementation worktree and keep the worker available
for CI fixes.
