# Design: executing-specs offers worktree cleanup at wrap-up

## Required Skills

_No specific skills required beyond defaults._

## Goal

Extend the `executing-specs` skill's wrap-up (Step 5) so that, in addition to
asking about integration and offering the `recognize-and-learn` retrospective, it
also offers to clean up the git worktree — but only when the work was actually
done in one. The offer points the user at the `/cleanup-worktree` command (which
tears down the worktree's Docker stack and removes the worktree in one step).

## Non-goals

- No change to any step other than Step 5 (plus small consistency edits to the
  Remember and Integration sections).
- The skill does not run the cleanup itself. `/cleanup-worktree` is
  user-invocable only (`disable-model-invocation`), so the skill recommends it.
- No behaviour when the work was not done in a linked worktree.

## Change

Edit `skills/executing-specs/SKILL.md`.

### Step 5 — add a final, conditional wrap-up item

After the existing integration question and the `recognize-and-learn` offer, add
a third item, ordered **last**:

> - **If the current checkout is a linked worktree**, offer to clean it up: recommend
>   the user run `/cleanup-worktree`, which tears down the worktree's Docker stack
>   and removes the worktree in one step. Two caveats to state in the offer:
>   - It is **user-invocable only** — recommend it, do not run it yourself.
>   - Do it **after integration** — removal is destructive (`--force` discards
>     anything uncommitted), so the work must be merged / PR'd / preserved first.
>
>   Detect a linked worktree agnostically: the current checkout is linked when
>   `git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`. If they
>   match (the main checkout) or the directory is not a git repo, skip this item
>   silently.

Ordering within Step 5: integration question → `recognize-and-learn` offer →
worktree-cleanup offer.

### Remember section — one-line reminder

Add a bullet:

> - If the work was done in a linked worktree, offer `/cleanup-worktree` at the end
>   (after integration) — recommend it, don't run it.

### Integration section — cross-reference

Under **Follow-up (optional)**, add:

> - **/cleanup-worktree** — offered at wrap-up when the work was done in a linked
>   worktree; tears down its Docker stack and removes the worktree.

## Testing

This is a documentation/behaviour-guidance edit to a skill file — there is no
executable unit to test. Verification is a read-through confirming:

1. The Step 5 offer is present, conditional on a linked worktree, and ordered last.
2. Both caveats (user-invocable only; after integration) are stated.
3. The detection rule (`git-dir` ≠ `git-common-dir`) is specified.
4. The Remember and Integration cross-references are consistent with Step 5.
5. No other step changed.
