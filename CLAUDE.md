# Superpowers — Personal Fork

Personal fork of [obra/superpowers](https://github.com/obra/superpowers), slimmed for faster execution. **Not** intended to upstream — do not open PRs against the original repository from this fork.

## What's different from upstream

**Removed skills:** `subagent-driven-development`, `dispatching-parallel-agents`, `writing-plans`, `requesting-code-review`, `receiving-code-review`, `using-git-worktrees`, `systematic-debugging`, `finishing-a-development-branch`. Plus the `code-reviewer` agent and the deprecated `/brainstorm`, `/write-plan`, `/execute-plan` commands.

**Workflow:** `brainstorming` develops an approved design in conversation. The reusable `orchestrator-agent` skill coordinates user-approved implementation tasks, separate Codex sub-worktrees, worker questions, and native GitHub stacked PRs. It is directly user-invokable and also callable by `orchestration-research`, which coordinates read-only research before handing over its synthesized task DAG. Each implementation worker invokes `executing-tasks` directly in its assigned sub-worktree. No generated design or task documents mediate the workflow.

**Orchestration:** the main worktree remains the coordination surface. Independent implementation tasks may run concurrently. Every implementation task receives a short `<action>-<topic>` name reused for its Orca task and sub-worktree, and requires user confirmation before dispatch. Dependent tasks use prerequisite branches as their Git bases. `orchestration-research` adds concurrent read-only research before reusing this implementation workflow.

**Review skill mapping:** `review-changes` scans available skills non-interactively during its understanding phase, invokes only relevant research or domain guidance, and uses it to enrich the review. It does not generate proposals or ask the user to approve a skill list.

**Recognize-and-learn retrospective:** `skills/recognize-and-learn/` captures implementation friction and proposes process or skill changes on a separate branch and PR. It never merges that PR automatically.

**No `commands/` directory — everything is a skill.** User-triggered workflows live in `skills/`. `review-changes`, `create-pull-request`, `improve-workflow`, `cleanup-worktree`, and `orchestration-research` are manual-only on both platforms: `disable-model-invocation: true` for Claude Code plus `agents/openai.yaml` with `policy.allow_implicit_invocation: false` for Codex. `orchestrator-agent` remains agent-invocable so `orchestration-research` can reuse it, and is also directly user-invokable. There are deliberately no `~/.codex/prompts` wrappers.

**Shared reviewer-writing rules:** `skills/reader-friendly-writing/` supplies the rule set for reviewer-facing output. It remains agent-invocable and is hidden from the `/` menu via `user-invocable: false`.

**Skill helper scripts sit beside their `SKILL.md`.** `skills/cleanup-worktree/cleanup-worktree.sh` and `skills/create-pull-request/observe-pr-tick.sh` resolve from their skill directories. `scripts/` holds repository tooling only.

## Notes for working in this repo

- Preserve carefully tuned behavior-shaping wording in surviving skills (Red Flags tables, rationalization lists, "your human partner" phrasing).
- `brainstorming` ends with the approved conversational design and directs the user to `orchestrator-agent` or `orchestration-research`; it does not dispatch implementation.
- The main coordinator session never implements code. Each approved implementation runs through `executing-tasks` in its own Orca sub-worktree.
- The `recognize-and-learn` skill writes to a separate branch in this repo and opens a PR — it never edits skills directly on `main`.
- Don't restore removed skills without a clear reason — the goal of the fork is fewer moving parts, not feature parity.
- Don't reintroduce `commands/`. New user-triggered workflows go in `skills/` with both manual-only declarations.
- Keep skill bodies platform-neutral. `@path` includes, `$ARGUMENTS`, and `${CLAUDE_PLUGIN_ROOT}` are Claude-Code-only and silently do nothing elsewhere. Prefer skill names, prose describing user-supplied guidance, and paths resolved from the skill's own directory. `tests/manual-only-skills/test-manual-only-skills.sh` enforces this.
