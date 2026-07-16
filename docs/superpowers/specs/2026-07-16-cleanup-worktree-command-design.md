# Design: `/cleanup-worktree` — agnostic worktree + Docker teardown command

## Required Skills

_No specific skills required beyond defaults._

## Goal

Provide an agnostic, user-invoked slash command that tears down the Docker
environment belonging to the current git worktree and then removes the worktree
itself. It is the project-independent successor to the repo-specific
`cleanup-worktree` skill added in
[Lendable/mx-cards-backend#1537](https://github.com/Lendable/mx-cards-backend/pull/1537),
which hard-codes `make down` from `services/` and keys worktree isolation off the
`.claude/worktrees/` path. This command discovers the teardown mechanism per
project instead of hard-coding it, so it works across repositories regardless of
their compose layout or Makefile conventions.

## Non-goals

- Not installed globally as a skill; it is a slash command in this fork.
- Does not manage git branches beyond removing the worktree (no branch delete,
  no push).
- Does not attempt to reproduce project-specific side effects a `make` target
  might perform beyond docker teardown (e.g. clearing caches on a remote).

## Form & placement

- A **user-invocable slash command** at `commands/cleanup-worktree.md`. This
  recreates the `commands/` directory the fork previously removed; that is
  intentional and scoped to this one command.
- Frontmatter:
  - `description` — one line describing what it does.
  - `argument-hint` — optional target directory (defaults to cwd).
  - `disable-model-invocation: true` — the command is destructive, so only the
    user triggers it via `/cleanup-worktree`; the model never auto-invokes it.
- The command body is a prompt that drives the agent through the phases below.
- It operates on the **current worktree** — the worktree containing cwd, or the
  optional path argument if one is given.

## Behaviour

### Phase 0 — Guard (read-only, agnostic)

- `WORKTREE_ROOT="$(git rev-parse --show-toplevel)"` (resolved from the target
  dir / cwd).
- Detect a *linked* worktree without assuming any path convention: compare
  `git rev-parse --git-dir` against `git rev-parse --git-common-dir`.
  - **Equal ⇒ this is the main working tree ⇒ refuse** with a clear message:
    the shared stack lives in the main checkout and must not be destroyed. This
    replaces the PR's hard-coded `.claude/worktrees/` check.
  - Not equal ⇒ a linked worktree ⇒ proceed.
- `MAIN_ROOT` = the first entry reported by `git worktree list --porcelain`
  (the main working tree), used later as the safe cwd for `git worktree remove`.
- If the worktree has uncommitted or untracked changes, warn the user
  explicitly in the plan (removal uses `--force`, which discards them).

### Phase 1 — Discover teardown mechanism (Makefile-first, read-only)

1. **Makefile first.** Find `Makefile` / `makefile` / `GNUmakefile` within the
   worktree (root plus a shallow search of subdirectories). For each candidate,
   enumerate targets and match teardown-ish names — `down`, `stop`, `clean`,
   `destroy`, `teardown`, `docker-down`, `compose-down` — preferring `down`.
   - **Validate the chosen target by dry-run:** `make -C <dir> -n <target>` and
     confirm the expansion actually contains a docker teardown
     (`docker compose … down`, `docker-compose down`, or `docker rm` / `docker
     stop`). A target that does not expand to a docker teardown is not selected.
   - Capture from the expansion whether the target removes named volumes
     (`-v` / `--volumes`).
   - If more than one candidate target/directory validates, do **not** auto-pick
     — surface the choices in the confirm step (Phase 2).
2. **Compose fallback (label-driven).** If no Makefile target validates,
   discover containers whose `com.docker.compose.project.working_dir` label is
   under `WORKTREE_ROOT` (`docker ps -a` + `docker inspect`). Group them by their
   recorded `com.docker.compose.project` and
   `com.docker.compose.project.config_files`, and plan
   `docker compose -p <proj> -f <files> down -v` per group. Using the labels the
   running containers already carry keeps the fallback reliable even when the
   compose files are buried in subdirectories (the mx-cards case).
3. **Independent target list.** Regardless of mechanism, list **all** containers
   (running and stopped) whose working_dir label is under `WORKTREE_ROOT`, so the
   plan shows exactly what will be affected.

### Phase 2 — Present plan, then confirm

Print a plan the user can verify before anything destructive happens:

- `WORKTREE_ROOT` and `MAIN_ROOT`.
- The detected mechanism: either the make target + its directory + the expanded
  command, or the per-project `docker compose … down` commands.
- The containers that will be removed.
- Whether named volumes will be removed.
- That the git worktree will be removed with `--force` (and a note about
  uncommitted changes if any were detected).

**Wait for the user's confirmation.** If the mechanism was ambiguous (multiple
make targets), ask which to use as part of this step.

### Phase 3 — Execute (only after confirmation)

1. Run the teardown: the make target from its directory, or the planned
   `docker compose … down -v` commands.
2. **Backstop:** force-remove any straggler container whose working_dir label is
   still under `WORKTREE_ROOT` (none expected after a clean teardown):
   ```bash
   docker ps -aq | while read -r id; do
     wd=$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' "$id" 2>/dev/null)
     case "$wd" in "$WORKTREE_ROOT"/*) docker rm -f "$id" >/dev/null ;; esac
   done
   ```
3. Remove the worktree from the safe cwd:
   ```bash
   cd "$MAIN_ROOT"
   git worktree remove --force "$WORKTREE_ROOT"
   [ -d "$WORKTREE_ROOT" ] && rm -rf "$WORKTREE_ROOT"
   git worktree prune
   ```
4. Print `Worktree <WORKTREE_ROOT> removed.`

### Edge cases

- **Docker daemon not running / unreachable:** warn, skip docker teardown, and
  offer to proceed with worktree removal only.
- **No containers and no validated make target:** nothing to tear down; after
  confirmation, proceed straight to worktree removal.
- **Ambiguous make targets:** list them in the plan and ask which to use.
- **Target dir not inside a git repo:** error out with a clear message.

## Testing

A scripted smoke test in a scratch temporary repository:

1. Create a real git repo, commit, add a linked worktree.
2. Assert the command **refuses** when run from the main checkout (git-dir ==
   git-common-dir).
3. With a dummy `docker compose` stack whose working_dir is under the worktree,
   assert correct mechanism discovery (Makefile target dry-run validation, and
   the label-driven compose fallback) and correct container targeting.
4. After teardown, assert the worktree is removed and the targeted containers are
   gone.

Docker-daemon-dependent steps are guarded so the test degrades gracefully (skips
those assertions) when Docker is unavailable, while the git/worktree-guard and
discovery-logic assertions still run.
