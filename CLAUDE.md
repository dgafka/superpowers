# Superpowers — Personal Fork

Personal fork of [obra/superpowers](https://github.com/obra/superpowers), slimmed for faster execution. **Not** intended to upstream — do not open PRs against the original repository from this fork.

## What's different from upstream

**Removed skills:** `subagent-driven-development`, `dispatching-parallel-agents`, `writing-plans`, `requesting-code-review`, `receiving-code-review`, `using-git-worktrees`, `systematic-debugging`, `finishing-a-development-branch`. Plus the `code-reviewer` agent and the deprecated `/brainstorm`, `/write-plan`, `/execute-plan` commands.

**Workflow change:** the pipeline is now `brainstorming → executing-specs → recognize-and-learn (optional)` (no separate plan-writing step). The `executing-specs` skill is an orchestration layer that runs in the parent session: it loads the spec from `docs/superpowers/specs/`, sanity-checks it, asks the user how to execute, then either runs the implementation in-session OR dispatches the dedicated `executing-specs` agent (defined in `agents/executing-specs.md`). The agent owns task decomposition, parallel-safe grouping, per-task TDD, final test verification, and reporting back. The intermediate plan file is gone — task decomposition happens inside the executor (subagent or in-session). Integration decisions (merge, PR, keep, discard) are surfaced to the user by the parent session after the implementation finishes; there is no automated finishing skill.

**Execution-mode prompt.** Before implementation, `executing-specs` asks the user to choose: continue in this session, dispatch the subagent at sonnet 1M, dispatch the subagent at opus, or hold for manual changes first. No default is marked — the right answer depends on the spec. Sonnet 1M is the cost/context default; opus is for harder reasoning; in-session execution avoids the subagent boundary but burns the parent's context.

**Spec skill mapping.** During brainstorming, after the spec passes self-review and before the user reviews it, a `general-purpose` subagent is dispatched to scan the available skills list against the spec and prepend a `## Required Skills` block to the spec. The implementer loads those skills before starting work.

**Recognize-and-learn retrospective.** A standalone post-implementation skill (`skills/recognize-and-learn/`). The `executing-specs` skill offers it as a follow-up after the implementation returns. It scans the conversation for user corrections (a first-class learning signal), captures friction (multi-attempt steps, unclear instructions, missing skills), and proposes process/skill changes on a separate branch + PR in this fork. The PR follows the repo's `.github/PULL_REQUEST_TEMPLATE.md` and is never merged automatically.

**Targeted subagent dispatch.** Two dispatch points in this fork: (1) `executing-specs` subagent — optional offload of TDD execution onto sonnet 1M (cost/context) or opus (reasoning), user's choice at Step 3; the parent can also run the implementation in-session; (2) brainstorming's spec-skill-mapping step — a one-shot `general-purpose` agent that edits the spec to add required skills. Brainstorming itself, spec authoring, the execution-mode question, result relay, and recognize-and-learn all still run in the current session. Code examples in skills have been translated from TypeScript to language-agnostic prose where the language was incidental to the lesson.

## Notes for working in this repo

- Preserve carefully tuned behavior-shaping wording in surviving skills (Red Flags tables, rationalization lists, "your human partner" phrasing) — these were tested by the upstream maintainers and the fork inherits them.
- When the spec under `docs/superpowers/specs/` exists, the `executing-specs` skill loads it and asks the user how to execute. Don't write a separate plan file. When dispatching to the subagent, don't decompose tasks in the parent session; when running in-session, the parent follows the same canonical TDD process the subagent would.
- The execution-mode question (in-session / sonnet 1M / opus / hold) is required. Do not pick a default for the user; surface the trade-off and let them choose.
- The `recognize-and-learn` skill writes to a separate branch in this repo and opens a PR — it never edits skills directly on `main`.
- Don't restore removed skills without a clear reason — the goal of the fork is fewer moving parts, not feature parity.
