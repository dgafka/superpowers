# Superpowers — Personal Fork

Personal fork of [obra/superpowers](https://github.com/obra/superpowers), slimmed for faster execution. **Not** intended to upstream — do not open PRs against the original repository from this fork.

## What's different from upstream

**Removed skills:** `subagent-driven-development`, `dispatching-parallel-agents`, `writing-plans`, `requesting-code-review`, `receiving-code-review`, `using-git-worktrees`, `systematic-debugging`, `finishing-a-development-branch`. Plus the `code-reviewer` agent and the deprecated `/brainstorm`, `/write-plan`, `/execute-plan` commands.

**Workflow change:** the pipeline is now `brainstorming → executing-specs` (no separate plan-writing step). The `executing-specs` skill is a thin orchestration layer that runs in the parent session (typically opus): it loads the spec from `docs/superpowers/specs/`, sanity-checks it, and dispatches the implementation to the dedicated `executing-specs` agent (sonnet, 1M context) defined in `agents/executing-specs.md`. The agent owns task decomposition, parallel-safe grouping, per-task TDD, final test verification, and reporting back. The intermediate plan file is gone — task decomposition happens inside the subagent. Integration decisions (merge, PR, keep, discard) are surfaced to the user by the parent session after the agent reports back; there is no automated finishing skill.

**Targeted subagent dispatch.** The only subagent in this fork is `executing-specs` — used to move TDD execution off opus and onto sonnet (1M context) for cost and context-window reasons. Brainstorming, spec authoring, and all other skill work still run in the current session. Code examples in skills have been translated from TypeScript to language-agnostic prose where the language was incidental to the lesson.

## Notes for working in this repo

- Preserve carefully tuned behavior-shaping wording in surviving skills (Red Flags tables, rationalization lists, "your human partner" phrasing) — these were tested by the upstream maintainers and the fork inherits them.
- When the spec under `docs/superpowers/specs/` exists, the `executing-specs` skill loads it and hands off to the `executing-specs` agent. Don't write a separate plan file, and don't decompose tasks in the parent session.
- Don't restore removed skills without a clear reason — the goal of the fork is fewer moving parts, not feature parity.
