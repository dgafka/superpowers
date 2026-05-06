# Superpowers — Personal Fork

Personal fork of [obra/superpowers](https://github.com/obra/superpowers), slimmed for faster execution. **Not** intended to upstream — do not open PRs against the original repository from this fork.

## What's different from upstream

**Removed skills:** `subagent-driven-development`, `dispatching-parallel-agents`, `writing-plans`, `requesting-code-review`, `receiving-code-review`, `using-git-worktrees`, `systematic-debugging`. Plus the `code-reviewer` agent and the deprecated `/brainstorm`, `/write-plan`, `/execute-plan` commands.

**Workflow change:** the pipeline is now `brainstorming → executing-plans` (no separate plan-writing step). `executing-plans` reads the spec from `docs/superpowers/specs/` directly, decomposes it into a TodoWrite checklist, identifies parallel-safe groups, and executes with per-task TDD. The intermediate plan file is gone — task decomposition happens in-session.

**No subagent dispatch.** All work runs in the current session. Code examples in skills have been translated from TypeScript to language-agnostic prose where the language was incidental to the lesson.

## Notes for working in this repo

- Preserve carefully tuned behavior-shaping wording in surviving skills (Red Flags tables, rationalization lists, "your human partner" phrasing) — these were tested by the upstream maintainers and the fork inherits them.
- When the spec under `docs/superpowers/specs/` exists, `executing-plans` consumes it directly. Don't write a separate plan file.
- Don't restore removed skills without a clear reason — the goal of the fork is fewer moving parts, not feature parity.
