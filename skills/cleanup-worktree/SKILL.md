---
name: cleanup-worktree
description: Use when explicitly asked to clean up the Docker environment belonging to a git worktree.
argument-hint: "[worktree-dir]  (defaults to the current directory)"
disable-model-invocation: true
---

# Cleanup Worktree

Tear down the Docker environment belonging to a git worktree. Discover the
teardown mechanism from Makefile targets or Compose container labels.
Container and named-volume cleanup is destructive: show the concrete plan and
get the user's confirmation before executing.

The helper `cleanup-worktree.sh` sits beside this skill. Resolve its absolute
path from the directory containing this file; substitute that directory for
`<SKILL_DIR>` below.

Use it via its two subcommands: `plan` (read-only) and `execute` (destructive,
needs `--yes`).

Target directory: the path the user supplied with the request if there was one,
otherwise the current directory. Below, `<DIR>` means that path (omit it to use
cwd).

## Step 1 — Plan (read-only)

Run the plan and show it to the user:

```bash
bash "<SKILL_DIR>/cleanup-worktree.sh" plan <DIR>
```

- **Exit code 2** means it refused because `<DIR>` is the **main checkout** (the
  shared stack lives there). Report the refusal and end the cleanup attempt.
- **Exit code 3** means `<DIR>` is not inside a git repository. Stop.
- **Other nonzero exits** mean planning failed. Report the actual error and stop.
  Treat Docker permission errors and an unavailable daemon as unresolved discovery.
  Obtain Docker access through the platform permission flow, then rerun the plan.
- **Exit code 0** prints a plan. Relay it to the user in readable form, covering:
  - `WORKTREE_ROOT` and `MAIN_ROOT`
  - `MECHANISM`: `make` (a validated Makefile target), `compose` (label-driven
    fallback), `make-ambiguous` (several Makefile targets — you must pick one),
    or `none` (no Makefile or Compose teardown found; listed containers still
    receive direct cleanup)
  - the containers that will be removed (`CONTAINERS:`)
  - Compose projects and their recorded configuration files (`COMPOSE_PROJECTS:`)
  - named-volume policy (`VOLUMES=yes|no|undetermined`); `undetermined` means
    a Makefile target must be selected first

## Step 2 — Confirm

Ask the user to confirm before anything destructive runs. If `MECHANISM` is
`make-ambiguous`, present the candidate `MAKE_CANDIDATES` lines and ask which
`<dir>`/`<target>` to use, or offer the Compose fallback when projects were
discovered. State the selected mechanism and its volume policy before execution.
For Makefile targets, the candidate’s `volumes`/`novolumes` field supplies that
policy; Compose removes named volumes by default.

Proceed to Step 3 after the user confirms the displayed plan.

## Step 3 — Execute (after confirmation)

Run execute with `--yes`. Pick the invocation matching the confirmed mechanism:

- **Auto** (single Makefile target or compose fallback):
  ```bash
  bash "<SKILL_DIR>/cleanup-worktree.sh" execute <DIR> --yes
  ```
- **Chosen Makefile target** (e.g. resolving `make-ambiguous`):
  ```bash
  bash "<SKILL_DIR>/cleanup-worktree.sh" execute <DIR> --yes \
    --make-dir <DIR-of-Makefile> --make-target <target>
  ```
- **Force the compose fallback** (skip Makefiles):
  ```bash
  bash "<SKILL_DIR>/cleanup-worktree.sh" execute <DIR> --yes --compose
  ```
- Add `--no-volumes` to keep named volumes (compose fallback only; volumes are
  removed by default).

Execute tears down the stack, removes remaining containers whose Compose
`working_dir` label is under the target, and queries Docker again. Success requires
zero related containers, including stopped containers.

On success, relay `Docker cleanup complete for <root>.` On any nonzero exit,
report the actual error and any surviving container IDs. Partial cleanup can
already have occurred; resolve the error and rerun the plan before retrying.
Report success after teardown and the final Docker query both succeed.

## Notes

- The main-checkout guard compares Git's per-worktree and shared metadata paths
  to protect the shared stack without assuming a directory convention.
- Discover container ownership from Compose working-directory labels. Automatic
  discovery covers containers carrying those labels.
