# Superpowers — Personal Fork

Personal fork of [obra/superpowers](https://github.com/obra/superpowers), slimmed for faster execution. **Not** intended to upstream — do not open PRs against the original repository from this fork.

## What's different from upstream

**Removed skills:** `using-superpowers`, `subagent-driven-development`, `dispatching-parallel-agents`, `writing-plans`, `requesting-code-review`, `receiving-code-review`, `using-git-worktrees`, `systematic-debugging`, `finishing-a-development-branch`. Plus the global session bootstrap, the `code-reviewer` agent, and the deprecated `/brainstorm`, `/write-plan`, `/execute-plan` commands.

**Workflow:** `brainstorming` develops an approved design in conversation. The reusable `orchestration-coordinator` skill coordinates user-approved implementation sub-worktrees, explicitly requested review sub-sessions, worker questions, and native GitHub stacked PRs. It is directly user-invokable and plans execution of the approved brainstorming design. Each implementation worker invokes `orchestration-sub-worktree` directly in its assigned sub-worktree. The design stays in conversation. The coordinator maintains `launch-execution.md` in the main worktree with each sub-worktree's full launch confirmation box, approval, and progress updated from worker reports; Orca owns scheduling.

**Orchestration:** the main worktree remains the coordination surface. Independent implementation sub-worktrees may run concurrently. Every implementation sub-worktree receives an `implement-<topic>` name reused for its Orca task and sub-worktree, requires a confirmation table and user approval before dispatch, and explicitly instructs its worker to invoke the isolated `test-driven-development` skill and follow RED-GREEN-REFACTOR. On explicit request, a dependent `review-<topic>` sub-session runs in a separate Codex terminal within that implementation's existing sub-worktree; approved fixes return to the original worker. Dependent implementation sub-worktrees use prerequisite branches as their Git bases. Every new sub-worktree or sub-session requires a confirmation table without Owns or Base rows. Review, observation, and explicitly requested independent verification reuse existing worktrees; routine tests and fixes stay with the implementation worker. Reserve task terminology for underlying Orca scheduling objects.

**PR completion:** Implementation workers invoke `dgafka:create-pull-request`, publish ready-for-review PRs against approved bases, report URLs to the main coordinator, and trigger the approved CI observation sub-session in the same worktree. Initial launch tables include PR publication, the PR skill in Discipline / Skill, and a separate named observer with findings routed to the original worker. The coordinator links existing PRs and retains workers for CI fixes.

**Review skill mapping:** `review-changes` supports direct use and explicitly requested Orca `review-<topic>` sub-sessions. It scans available skills non-interactively during its understanding phase, invokes only relevant research or domain guidance, and uses it to enrich the review. It does not generate proposals or ask the user to approve a skill list.

**Recognize-and-learn retrospective:** `skills/recognize-and-learn/` captures implementation friction and proposes process or skill changes on a separate branch and PR. It never merges that PR automatically.

**No `commands/` directory — everything is a skill.** User-triggered workflows live in `skills/`. `improve-workflow` and `cleanup-worktree` are manual-only on both platforms: `disable-model-invocation: true` for Claude Code plus `agents/openai.yaml` with `policy.allow_implicit_invocation: false` for Codex. `create-pull-request`, `orchestration-coordinator`, and `review-changes` remain agent-invocable for skill reuse and are also directly user-invokable. There are deliberately no `~/.codex/prompts` wrappers.

**Shared reviewer-writing rules:** `skills/reader-friendly-writing/` supplies the rule set for reviewer-facing output. It remains agent-invocable and is hidden from the `/` menu via `user-invocable: false`.

**Skill helper scripts sit beside their `SKILL.md`.** `skills/cleanup-worktree/cleanup-worktree.sh` and `skills/create-pull-request/observe-pr-tick.sh` resolve from their skill directories. `scripts/` holds repository tooling only.

## Notes for working in this repo

- At the end of implementation planning, `orchestration-coordinator` proposes separate deliverable sub-worktrees, their dependencies, execution and delivery order, and parallel work. Logic awaiting other units uses an environment-variable feature flag disabled by default, with explicit activation prerequisites and verification of both states.

- State instructions as concrete actions. Replace prohibitions with the required behavior and remove lines that add no actionable direction. Preserve workflow responsibilities, approval conditions, useful Red Flags/recovery tables, and "your human partner" phrasing.
- Call reusable workflows skills, including user-invokable skills. Reserve command for CLI operations, checklist item for session tracking, and Orca task for scheduling objects. Use run-wide guidance consistently.
- Validate skill metadata, relative references, and terminology with `python3 tests/skill-instructions/test-instructions.py`; verify behavior separately with representative agent scenarios when the execution scope permits.
- `brainstorming` ends with the approved conversational design and directs the user to `orchestration-coordinator` for execution planning; it does not dispatch implementation.
- The main coordinator session never implements code. Each approved implementation runs through `orchestration-sub-worktree` in its own Orca sub-worktree.
- The `recognize-and-learn` skill routes approved changes through `orchestration-coordinator` to a dedicated implementation sub-worktree and separate PR in this repo.
- Don't restore removed skills without a clear reason — the goal of the fork is fewer moving parts, not feature parity.
- Don't reintroduce `commands/`. New user-triggered workflows go in `skills/` with both manual-only declarations.
- Keep skill bodies platform-neutral. `@path` includes, `$ARGUMENTS`, and `${CLAUDE_PLUGIN_ROOT}` are Claude-Code-only and silently do nothing elsewhere. Prefer skill names, prose describing user-supplied guidance, and paths resolved from the skill's own directory. `tests/manual-only-skills/test-manual-only-skills.sh` and `tests/skill-instructions/test-instructions.py` check these conventions.
