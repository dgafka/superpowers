# Launch Confirmation

Before creating a sub-worktree or starting a sub-session, fill and show this
table, then obtain explicit approval for that concrete launch. A sub-session
is a separate Codex terminal session within the named existing worktree.

| Field | Proposed launch |
|---|---|
| Sub-worktree / Sub-session | Use only the applicable label and exact launch name |
| Goal | Intended outcome; review focus for a reviewer |
| Execution | New child sub-worktree, or sub-session in an exact existing worktree; agent |
| Dependencies | Prerequisite names or none |
| Discipline / Skill | Worker skill and relevant execution rules |
| Verification | Acceptance checks; stable reviewed commit for a reviewer |
| Guidance | Relevant user instructions, or none |
| PR | When applicable: target, stack position, publication or comment permission, observation mode |

Do not add Owns or Base rows. Preserve scope ownership and the verified Git
base in the internal worker context. Use short cells with readable labels.
Omit the PR row when it does not apply. For reviews, state explicitly whether
external comments are authorized; a review request alone does not authorize them.

For a concurrent wave, show one table per launch and identify every launch
covered by the user's confirmation. Do not treat a general objective, research
request, or observation-mode choice made before the table as launch approval.
An existing explicit approval of the unchanged table remains valid.

For an existing sub-session, ordinary continuation within approved scope needs
no new confirmation. A new terminal or changed scope requires a new table.

For implementation launches, the Discipline / Skill row must include
`superpowers:create-pull-request` alongside the implementation and TDD skills.
The PR row states publication on completion and the approved target/stack position.
Present the named CI observer in its own table in the same approval message:
`superpowers:create-pull-request`, observation-only mode `ci`, a separate Codex
terminal in that implementation worktree, and findings to the original worker.
This approval also covers keeping that worker terminal available for CI fixes.
Reuse both unchanged approvals at completion; do not ask again for publication,
observation mode, or the already approved observer launch.
