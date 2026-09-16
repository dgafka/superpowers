# Launch Confirmation

Before creating a new sub-worktree, fill and show this table, then obtain
explicit approval for that concrete sub-worktree launch. Sessions started in an
existing sub-worktree are dispatched directly without this table or launch
approval. A sub-session is a separate Codex terminal session within the named
existing worktree.

## Create and Maintain the Execution Record

When preparing the first launch boxes, the coordinator creates
`launch-execution.md` at the root of the main coordinator worktree. Record the
objective and Orca Run identifier, then add one section per named implementation
sub-worktree containing its complete launch confirmation box using the template
below. Add that worktree's observer and any later review or verification boxes
as subsections. Show new sub-worktree boxes in conversation for approval before
creation. Record sessions in existing sub-worktrees beneath the matching
worktree's execution history without creating a new approval box.

For each box, record approval as pending until your human partner explicitly
approves it. Keep the approved box intact and track execution beneath it:

- Current status and last update time
- Implementation step checklist matching the numbered Description steps
- Worker and Orca task identifiers, branch, and execution location once known
- Latest progress, verification evidence and checked commit, PR URL, CI and
  review results, blockers, and next action
- Timestamped updates with the reporting worker or observer and its evidence
- Self-review result against the approved business requirements; when it does
  not align, the exact correction request, worker revision, and re-review result
- The dispatch-time approval timestamp and the exact named launch it authorizes

The coordinator owns this file. Update the matching section after each launch,
worker progress report, question or blocker, verification result, PR publication,
observer or reviewer finding, fix, and completion report. Mark steps complete
from reported evidence and keep implementation completion, CI, review, and
integration status separate. Record pending or failed checks explicitly.

When launch scope changes, append the revised box and its approval state while
preserving the previous approved version. Resume an existing record for the same
Run; for a new Run, preserve the previous contents in an archive before creating
the new record. On resumption, reconcile the record with current Orca state and
worker reports. Orca remains the scheduling source of truth; this file presents
the approved assignments and their execution history to your human partner.

## Launch Box Template

| Field | Proposed launch |
|---|---|
| Sub-worktree / Sub-session | Use only the applicable label and exact launch name |
| Goal | Intended outcome; review focus for a reviewer |
| Description | Complete ordered implementation steps for this sub-worktree; scoped activities for a sub-session |
| Execution | New child sub-worktree, or sub-session in an exact existing worktree; agent and model |
| Dependencies | Prerequisite names or none |
| Discipline / Skill | Worker skill and relevant execution rules |
| Verification | Acceptance checks; stable reviewed commit for a reviewer |
| Guidance | Relevant user instructions, or none |
| PR | When applicable: target, stack position, publication or comment permission, observation mode |

Use the defined table rows. Preserve scope ownership and the verified Git
base in the internal worker context. Use short cells with readable labels.
Keep Description concrete and complete: identify the affected components or
interfaces, behavior changes, integration or migration work, and feature flag
work when applicable. Number the steps within the cell, using line breaks for
readability. Match the delivery proposal's Description column and copy these
approved steps into the worker prompt. Include verification and publication
work in their dedicated rows so the box describes the full assignment.
Omit the PR row when it does not apply. For reviews, state explicitly whether
external comments are authorized, based on the user's explicit permission.

Always show the model beside the agent in launch confirmation and execution
summary tables. Default to `codex / gpt-5.6-sol` or `claude code / sonnet 5`
unless the user specifies another model. Apply this to every sub-worktree and
sub-session, including research, review, observation, and verification.
Pass the displayed model explicitly when launching. If the runtime cannot resolve the
selected model, report the blocker and ask the user to choose a replacement.

Immediately before creating any new sub-worktree, show its current complete box
and obtain a fresh explicit confirmation to proceed with that exact named
launch. A planning approval does not authorize a later creation, even when the
box is unchanged. Record this dispatch-time approval in `launch-execution.md`.
Dispatch sessions in existing sub-worktrees directly and record their session
name, purpose, worker route, and start result in the existing execution
history.

For concurrent ready new sub-worktree launches, show one table per launch and
identify every launch covered by the confirmation. Obtain a distinct explicit
approval for each concrete table after presenting it.

After dispatch, continue sessions in existing sub-worktrees within their
approved worktree context. A changed objective or acceptance criteria is
reported to the user for a scope decision; it does not require a launch box
unless a new sub-worktree is needed.

For implementation launches, the Discipline / Skill row must include
`dgafka:create-pull-request` alongside the implementation and TDD skills.
The PR row states publication on completion and the approved target/stack position,
plus the named observer, mode, existing worktree, and findings route. The
observer uses `dgafka:create-pull-request` in observation-only mode `ci` in a
separate Codex terminal in that implementation worktree, with findings sent to
the original worker. The new-sub-worktree approval also covers publication and
keeping that worker terminal available for CI fixes.
At completion, reuse the approved publication and observation mode; dispatch the
observer directly in the existing implementation worktree.
