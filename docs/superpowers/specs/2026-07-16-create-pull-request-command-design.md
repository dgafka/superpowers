# Design Spec: `/create-pull-request` command

**Date:** 2026-07-16
**Status:** Approved, ready for implementation

## Required Skills

_No specific skills required beyond defaults._

## Goal

Add a generic, portable slash command `commands/create-pull-request.md` that produces high-quality, descriptive pull requests in any repository the plugin is installed in. It keeps the descriptive quality of the Ecotone `create-pr` command and the motivation discipline of the Lendable `create-pr` skill, while stripping everything project-specific. All repo-specific behavior is **detected, deferred to the repo's PR template, or asked** — never hardcoded.

## Deliverable

A single self-contained file: `commands/create-pull-request.md`. This creates the `commands/` directory, which is currently absent from the fork. No supporting reference files — the command is self-contained and portable.

### Frontmatter

- `name: create-pull-request`
- `description`: triggers on requests to create/open a PR, push the current branch as a PR, or the explicit `/create-pull-request` invocation.
- `allowed-tools`: scoped to the git and `gh pr` commands the process needs, e.g. `Bash(gh pr create:*)`, `Bash(gh pr list:*)`, `Bash(gh pr view:*)`, `Bash(git log:*)`, `Bash(git diff:*)`, `Bash(git status:*)`, `Bash(git branch:*)`, `Bash(git rev-parse:*)`, `Bash(git symbolic-ref:*)`, `Bash(git show:*)`, `Bash(git push:*)`, `Bash(git remote:*)`.
- `disable-model-invocation: false`

## Process (linear)

### 1. Gather context
Run in parallel:
- `git branch --show-current` — current branch
- `git status` — uncommitted changes
- **Detect the default branch** via `git symbolic-ref refs/remotes/origin/HEAD` (strip to branch name); if that fails, probe for `main` then `master`. **Never assume `main`.** Use the detected branch as `<base>` everywhere below.
- `git log <base>..HEAD --oneline` — commits on the branch
- `git diff <base>...HEAD --stat` — changed-files summary
- `git diff <base>...HEAD` — full diff
- `git remote get-url origin` — repository identity

**Guards:**
- If the current branch **is** the default branch → stop and tell the user to switch to a feature branch.
- If there are uncommitted changes → warn and ask whether to proceed without them.

### 2. Detect conventions & template
- Read the PR template if present: check `.github/PULL_REQUEST_TEMPLATE.md`, the repo root, `docs/`, and the multi-template directory `.github/PULL_REQUEST_TEMPLATE/`.
- Infer the **title convention** from recent merged PRs (`gh pr list --state merged --limit 20`) and/or `git log`: conventional-commits (`feat:`, `fix:`…), ticket-prefixed (`[TICKET-123]`), or plain.
- Detect a **ticket reference** from the branch name generically (e.g. `[A-Z]+-\d+`).
- **Ask the user only when detection is ambiguous.**
- **Ticket-prompt rule:** if the inferred convention shows ticket-labelled titles are the norm (most recent merged PRs carry a ticket prefix) **and** no ticket can be found in the branch name or session context, **ask the user for the ticket number**, accepting "none" to proceed without one. If tickets are clearly not the norm, do not ask.

### 3. Classify the change (organizing step)
Determine the PR's type and intent from the diff and session context. Categories:
- Refactor / internal cleanup
- Bug fix
- New feature
- Flow / state / pipeline change (or a capability enabling flow changes)
- Userland-visible behavior / API change
- Config / docs / tooling

The classification drives which explanatory aids are used (Step 5).

### 4. Extract motivation
- Draw the "why" from the **current session context first**, then the diff.
- If the "why" is unclear, ask the user: what problem does this solve, and why now?
- Optionally append an attribution line listing skills invoked this session (`_Drafted with /skill-a, /skill-b._`), included **only when** any were invoked.

### 5. Select explanatory aids from the classification
Match aids to intent; add nothing that does not earn its place.

| Change type | After-only Mermaid | Code example | Motivation emphasis |
|---|---|---|---|
| Refactor / internal cleanup | no | no | the role/design mismatch being fixed |
| Bug fix | no | only if usage-affecting | the incorrect behavior and why it was wrong |
| New feature | if it introduces a flow | if userland-visible | what the feature enables |
| Flow / state / pipeline change | **yes** | if userland-visible | what the new flow achieves |
| Userland-visible behavior / API | if flow-related | **yes** (repo's language) | what changes for users |
| Config / docs / tooling | no | no | why the change is needed |

- **Mermaid is after-only** — show the resulting flow, not before/after; the diff already conveys the prior state. Use it only for flow/state/pipeline changes.
- **Code examples** use the repository's own language and are copy-pasteable, showing how a user interacts with the changed behavior — so readers "get a feel."

### 6. Compose
- **Title:** goal-oriented (what the PR achieves, not what code changed), imperative mood, following the repo's detected convention. Include a ticket prefix per the Step 2 ticket-prompt rule.
- **Body — template alignment:**
  - **Template exists** → fill *every* section it defines, honoring its inline comments/checkboxes; never invent or drop sections. Place the explanatory aids in the most fitting section.
  - **No template** → default structure: `## Why` (motivation) → `## What changed` (concise bullets) → optional `### New Flow` (Mermaid) / `### Example` → optional attribution line.

### 7. Preview & confirm
Show the user the full title and body and ask for approval before creating anything. Support requested changes.

### 8. Push & create
- If the branch is unpushed, push with `git push -u origin <branch>`.
- Create with `gh pr create` (always ready-for-review — **no draft prompt**).
- No hardcoded labels, GIFs, or other project-specific decorations.
- Return the PR URL to the user.

## Motivation discipline (generalized, inline in the command)
Keep it compact and generic — no company/domain specifics:
- WHY, not WHAT (the diff shows what changed).
- Role-first sentences: the subject IS the thing, the predicate IS the mismatch or problem.
- One idea per sentence.
- Exact domain terms — a near-synonym signals shaky ownership.
- Scope and counts are evidence, not motivation — omit them from the motivation.
- Mechanism belongs in inline review comments, not the PR body.
- No code snippets in the motivation.
- 2–5 sentences or bullets — no novels.

## Genericity guardrails (explicit "do not hardcode")
- No fixed ticket prefixes, service tags, labels, mandatory GIFs, or languages.
- Detect the default branch; do not assume `main`.
- Everything repo-specific comes from detection, the PR template, or asking the user.

## Verification
A command file is prose, not executable code — no unit test. Verify by:
1. Self-review against every requirement in this spec (guards, detection, classification, template alignment, guardrails).
2. A real dry-run on a feature branch: confirm it detects the template, classifies the change, selects appropriate aids, and produces a preview **before** any PR is created (no PR auto-created during verification).

## Out of scope
- Draft-mode support.
- Per-repo config files (detection + template + asking covers it).
- Auto-merge, labels, reviewers, or CI interactions beyond `gh pr create`.
