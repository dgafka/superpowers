# Launch Confirmation

Before creating a sub-worktree or starting a sub-session, fill and show this
table, then obtain explicit approval for that concrete launch. A sub-session
is a separate Codex terminal session within the named existing worktree.

## Create and Maintain the Execution Record

When preparing the first launch boxes, the coordinator creates
`launch-execution.md` at the root of the main coordinator worktree. Record the
objective and Orca Run identifier, then add one section per named implementation
sub-worktree containing its complete launch confirmation box using the template
below. Add that worktree's observer and any later review or verification boxes
as subsections. Show the same boxes in conversation for approval before launch.

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

Immediately before dispatching any sub-worktree, show its current complete box
and obtain a fresh explicit confirmation to proceed with that exact named
launch. A planning approval does not authorize a later dispatch, even when the
box is unchanged. Record this dispatch-time approval in `launch-execution.md`.

For concurrent ready launches, show one table per launch and identify every
launch covered by the confirmation. Obtain a distinct explicit approval for each
concrete table after presenting it.

After dispatch, reuse the existing approval for ordinary continuation within the
approved scope. It never authorizes dispatching another sub-worktree. A new
terminal or changed scope requires a new table.

For implementation launches, the Discipline / Skill row must include
`dgafka:create-pull-request` alongside the implementation and TDD skills.
The PR row states publication on completion and the approved target/stack position.
Present the named CI observer in its own table in the same approval message:
`dgafka:create-pull-request`, observation-only mode `ci`, a separate Codex
terminal in that implementation worktree, and findings to the original worker.
This approval also covers keeping that worker terminal available for CI fixes.
Reuse both unchanged approvals at completion for publication, observation mode,
and the approved observer launch.
