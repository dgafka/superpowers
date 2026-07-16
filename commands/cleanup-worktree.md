---
description: Tear down the current git worktree's Docker stack, then remove the worktree. Agnostic — discovers the teardown mechanism (Makefile target or compose from container labels). Refuses on the main checkout.
argument-hint: "[worktree-dir]  (defaults to the current directory)"
disable-model-invocation: true
---

# Cleanup Worktree

Tear down the Docker environment belonging to a git worktree and then remove the
worktree itself. Works across projects: it discovers how the stack was brought up
rather than assuming any layout. **This is destructive** — it removes containers,
named volumes, and the worktree (with `--force`) — so always show the plan and get
the user's confirmation before executing.

The logic lives in `${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-worktree.sh`. Use it via
its two subcommands: `plan` (read-only) and `execute` (destructive, needs `--yes`).

Target directory: the argument `$ARGUMENTS` if given, otherwise the current
directory. Below, `<DIR>` means that path (omit it to use cwd).

## Step 1 — Plan (read-only)

Run the plan and show it to the user:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-worktree.sh" plan <DIR>
```

- **Exit code 2** means it refused because `<DIR>` is the **main checkout** (the
  shared stack lives there). Stop and tell the user — do not force it.
- **Exit code 3** means `<DIR>` is not inside a git repository. Stop.
- **Exit code 0** prints a plan. Relay it to the user in readable form, covering:
  - `WORKTREE_ROOT` and `MAIN_ROOT`
  - `MECHANISM`: `make` (a validated Makefile target), `compose` (label-driven
    fallback), `make-ambiguous` (several Makefile targets — you must pick one),
    or `none` (nothing to tear down; only the worktree will be removed)
  - the containers that will be removed (`CONTAINERS:`)
  - whether named volumes will be removed (`VOLUMES=yes|no`)

## Step 2 — Confirm

Ask the user to confirm before anything destructive runs. If `MECHANISM` is
`make-ambiguous`, present the candidate `MAKE_CANDIDATES` lines and ask which
`<dir>`/`<target>` to use. If a worktree has uncommitted changes and you can see
that, warn that `--force` discards them.

Do not proceed to Step 3 until the user confirms.

## Step 3 — Execute (after confirmation)

Run execute with `--yes`. Pick the invocation matching the confirmed mechanism:

- **Auto** (single Makefile target or compose fallback):
  ```bash
  bash "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-worktree.sh" execute <DIR> --yes
  ```
- **Chosen Makefile target** (e.g. resolving `make-ambiguous`):
  ```bash
  bash "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-worktree.sh" execute <DIR> --yes \
    --make-dir <DIR-of-Makefile> --make-target <target>
  ```
- **Force the compose fallback** (skip Makefiles):
  ```bash
  bash "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-worktree.sh" execute <DIR> --yes --compose
  ```
- Add `--no-volumes` to keep named volumes (compose fallback only; volumes are
  removed by default).

Execute tears down the stack, force-removes any straggler container whose
`working_dir` label is under the worktree, then removes and prunes the worktree.
On success it prints `Worktree <root> removed.` — relay that to the user.

## Notes

- The main-checkout guard is layout-agnostic: it compares `git rev-parse
  --git-dir` against `--git-common-dir`, so it protects the shared stack without
  assuming any `.claude/worktrees/` convention.
- If the Docker daemon is down, teardown is a no-op and only the worktree is
  removed; mention this to the user if it happens.
