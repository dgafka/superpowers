# Superpowers

Superpowers is a software development methodology for coding agents, built from composable, task-oriented skills.

## How it works

Start with `brainstorming` to refine what you want to build, then invoke the appropriate orchestration workflow.

It develops the design in conversation and presents it in sections short enough to read and validate.

After you've signed off on the design, the orchestrator proposes named implementation sub-worktrees, identifies which can run in parallel, and presents a confirmation table before launching each with RED-GREEN-REFACTOR discipline. It emphasizes true test-first development, YAGNI (You Aren't Gonna Need It), and DRY.

The explicit dependencies and worker boundaries let agents work autonomously without drifting from the design you approved.

There's more to it, but that is the core of the task-oriented workflow.


## Sponsorship

If Superpowers has helped you do stuff that makes money and you are so inclined, I'd greatly appreciate it if you'd consider [sponsoring my opensource work](https://github.com/sponsors/obra).

Thanks! 

- Jesse


## Installation

**Note:** Installation differs by platform. 

### Claude Code Official Marketplace

Superpowers is available via the [official Claude plugin marketplace](https://claude.com/plugins/superpowers)

Install the plugin from Anthropic's official marketplace:

```bash
/plugin install dgafka@superpowers-dgafka
```

### Claude Code (Superpowers Marketplace)

The Superpowers marketplace provides Superpowers and some other related plugins for Claude Code.

In Claude Code, register the marketplace first:

```bash
/plugin marketplace add dgafka/superpowers
```

Then install the plugin from this marketplace:

```bash
/plugin install dgafka@superpowers-dgafka
```

### OpenAI Codex CLI

- Open plugin search interface

```bash
/plugins
```

Search for Superpowers

```bash
dgafka
```

Select `Install Plugin`

### OpenAI Codex App

- In the Codex app, click on Plugins in the sidebar.
- You should see `dgafka` in the Coding section.
- Click the `+` next to dgafka and follow the prompts.


### Cursor (via Plugin Marketplace)

In Cursor Agent chat, install from marketplace:

```text
/add-plugin dgafka
```

or search for "dgafka" in the plugin marketplace.

### OpenCode

Tell OpenCode:

```
Fetch and follow instructions from https://raw.githubusercontent.com/dgafka/superpowers/refs/heads/main/.opencode/INSTALL.md
```

**Detailed docs:** [docs/README.opencode.md](docs/README.opencode.md)

### GitHub Copilot CLI

```bash
copilot plugin marketplace add dgafka/superpowers
copilot plugin install dgafka@superpowers-dgafka
```

### Gemini CLI

```bash
gemini extensions install https://github.com/dgafka/superpowers
```

To update:

```bash
gemini extensions update dgafka
```

## The Basic Workflow

1. **brainstorming** - Activates before writing code. Refines rough ideas through questions, explores alternatives, and presents a conversational design for validation.

2. **orchestration-coordinator** - Ends implementation planning with a proposal for deliverable sub-worktrees, dependencies, execution order, and parallel work. Creates `launch-execution.md` in the main worktree with every launch box and updates progress from worker reports. Requires environment-variable feature flags for logic awaiting other units, plus a launch confirmation table and isolated TDD for each implementation.

3. **orchestration-sub-worktree** - Implements approved work directly in its assigned sub-worktree with TDD and final verification.

4. **review-changes** - On explicit request, runs `review-<topic>` as a confirmed sub-session within the existing implementation worktree, against local changes or a pull request.

5. **test-driven-development** - Activates during implementation. Enforces RED-GREEN-REFACTOR: write failing test, watch it fail, write minimal code, watch it pass, commit. Deletes code written before tests.

A **sub-session** is a separate Codex terminal within an existing worktree. Use it for review, CI/PR observation, and explicitly requested independent verification. Each new sub-worktree or sub-session gets a confirmation table without Owns or Base rows. Routine tests and fixes stay with the original implementation worker. Orca tasks remain the underlying scheduling objects.

Invoke the workflow that matches the work. Implementation workers receive their required skills directly in the Orca task prompt.

## What's Inside

### Skills Library

**Testing**
- **test-driven-development** - RED-GREEN-REFACTOR cycle (includes testing anti-patterns reference)

**Collaboration** 
- **brainstorming** - Socratic design refinement
- **orchestration-coordinator** - Coordinates implementation sub-worktrees, explicitly requested review sub-sessions, and stacked PRs through Orca; directly invokable after brainstorming approves the solution
- **orchestration-sub-worktree** - Implements approved work directly in its assigned sub-worktree
- **recognize-and-learn** - Post-implementation retrospective; proposes process/skill changes on a branch + PR

**Delivery** (user-triggered only — the agent never starts these on its own)
- **review-changes** - Review local changes or a PR directly, or serve an explicitly requested `review-<topic>` sub-session
- **create-pull-request** - Open a PR using the repo's own conventions and template
- **improve-workflow** - Mine a PR's review feedback for repeatable lessons
- **cleanup-worktree** - Plan and verify cleanup of a worktree's Docker environment

Trigger manual workflows with their skill name in Claude Code or `$skill-name` in Codex.

**Meta**
- **writing-skills** - Create new skills following best practices (includes testing methodology)
- **reader-friendly-writing** - Shared rule set for reviewer-facing write-ups, invoked by the Delivery skills and brainstorming

## Philosophy

- **Test-Driven Development** - Write tests first, always
- **Systematic over ad-hoc** - Process over guessing
- **Complexity reduction** - Simplicity as primary goal
- **Evidence over claims** - Verify before declaring success

Read [the original release announcement](https://blog.fsck.com/2025/10/09/superpowers/).

## Contributing

The general contribution process for Superpowers is below. Keep in mind that we don't generally accept contributions of new skills and that any updates to skills must work across all of the coding agents we support.

1. Fork the repository
2. Switch to the 'dev' branch
3. Create a branch for your work
4. Follow the `writing-skills` skill for creating and testing new and modified skills
5. Submit a PR, being sure to fill in the pull request template.

See `skills/writing-skills/SKILL.md` for the complete guide.

## Updating

Superpowers updates are somewhat coding-agent dependent, but are often automatic.

## License

MIT License - see LICENSE file for details

## Community

Superpowers is built by [Jesse Vincent](https://blog.fsck.com) and the rest of the folks at [Prime Radiant](https://primeradiant.com).

- **Discord**: [Join us](https://discord.gg/35wsABTejz) for community support, questions, and sharing what you're building with Superpowers
- **Issues**: https://github.com/obra/superpowers/issues
- **Release announcements**: [Sign up](https://primeradiant.com/superpowers/) to get notified about new versions
