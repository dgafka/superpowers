# Launch Confirmation

Before creating a sub-worktree or starting a sub-session, fill and show this
table, then obtain explicit approval for that concrete launch. A sub-session
is a separate Codex terminal session within the named existing worktree.

| Field | Proposed launch |
|---|---|
| Sub-worktree / Sub-session | Use only the applicable label and exact launch name |
| Goal | Intended outcome; review focus for a reviewer |
| Execution | New child sub-worktree, or sub-session in an exact existing worktree; agent and model |
| Dependencies | Prerequisite names or none |
| Discipline / Skill | Worker skill and relevant execution rules |
| Verification | Acceptance checks; stable reviewed commit for a reviewer |
| Guidance | Relevant user instructions, or none |
| PR | When applicable: target, stack position, publication or comment permission, observation mode |

Use the defined table rows. Preserve scope ownership and the verified Git
base in the internal worker context. Use short cells with readable labels.
Omit the PR row when it does not apply. For reviews, state explicitly whether
external comments are authorized, based on the user's explicit permission.

Always show the model beside the agent in launch confirmation and execution
summary tables. Default to `codex / gpt-5.6-sol` or `claude code / sonnet 5`
unless the user specifies another model. Apply this to every sub-worktree and
sub-session, including research, review, observation, and verification.
Pass the displayed model explicitly when launching. If the runtime cannot resolve the
selected model, report the blocker and ask the user to choose a replacement.

For a concurrent wave, show one table per launch and identify every launch
covered by the user's confirmation. Obtain approval of the concrete table after presenting it.
An existing explicit approval of the unchanged table remains valid.

Reuse the existing approval for ordinary continuation within the approved scope. A new terminal or changed scope requires a new table.

For implementation launches, the Discipline / Skill row must include
`superpowers:create-pull-request` alongside the implementation and TDD skills.
The PR row states publication on completion and the approved target/stack position.
Present the named CI observer in its own table in the same approval message:
`superpowers:create-pull-request`, observation-only mode `ci`, a separate Codex
terminal in that implementation worktree, and findings to the original worker.
This approval also covers keeping that worker terminal available for CI fixes.
Reuse both unchanged approvals at completion for publication, observation mode,
and the approved observer launch.
