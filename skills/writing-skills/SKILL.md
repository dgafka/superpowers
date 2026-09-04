---
name: writing-skills
description: Create and refine reusable agent instructions. Use when creating skills, editing existing skills, or verifying skills before deployment.
---

# Writing Skills

## Overview

Apply RED-GREEN-REFACTOR to process documentation: establish an observed failure,
write the instruction that addresses it, and verify the resulting behavior.

**REQUIRED BACKGROUND:** Understand superpowers:test-driven-development before
using this skill. Adapt its cycle to instruction testing as described below.

Personal skills live in the platform's skill directory, such as
`~/.claude/skills` for Claude Code or `~/.agents/skills` for Codex.

## Choose the Right Home

| Content | Destination |
|---|---|
| Reusable technique, workflow, or reference | Agent skill |
| Project-specific convention | Project instructions, such as AGENTS.md or CLAUDE.md |
| Mechanically enforceable requirement | Validation script or CI check |
| One-off finding | Current conversation or the relevant change description |
| Existing authoritative guidance | Link with a condition for reading it |

## Write Instructions as Actions

For each rule, state the **condition**, **responsible actor**, **required action**,
and **observable completion signal**. Include the recovery action when a step
can fail. Scale the detail to the decision: exact steps for fragile operations,
clear outcomes and boundaries for work that needs judgment.

Example:

> When CI reports a failure, the observer sends the checked commit, failing check
> URL, and relevant log excerpt to the implementation worker. The worker applies
> the correction and reports the new commit. The observer checks that commit.

Express approval conditions positively: “Publish after the approved checks
pass.” Express ownership positively: “Return findings to the implementation
worker for fixes.” Remove a negative sentence when it adds no actionable rule
beyond the surrounding text.

Keep one authoritative instruction for each rule. Put its exceptions beside it,
and make checklists and examples agree with that rule. When composing skills,
state which skill owns each decision and which explicitly scoped specialization
applies. User instructions determine the authorized scope and take precedence
over skill defaults.

## Use Consistent Terms

- **Skill:** a reusable instruction package, including user-invokable workflows.
- **Command:** an executable CLI operation.
- **Checklist item:** a step tracked in the current session.
- **Orca task:** an Orca scheduling object.
- **Sub-worktree:** an implementation checkout.
- **Sub-session:** a separate agent terminal in an existing worktree.
- **Run-wide guidance:** user context preserved across assignments.

Use the same term for the same concept throughout related skills. Use “agent”
for platform-neutral instructions and product names for platform-specific facts.
Keep exact tool identifiers and CLI flags intact. Preserve quotations and sample
inputs as evidence; review the instructions around them for actionable wording.

## Structure and Metadata

A skill directory contains `SKILL.md` and supporting files as needed. Keep
helper scripts beside their skill in this repository.

```text
skill-name/
  SKILL.md
  reference.md
  helper.py
```

Use YAML frontmatter with these required fields:

- `name`: 1–64 characters, lowercase letters, digits, and single internal
  hyphens; match the directory name.
- `description`: 1–1024 characters, stating the skill's purpose and precise
  triggering conditions. Put step-by-step procedures in the body.

```yaml
---
name: review-changes
description: Review code changes for actionable defects. Use when reviewing a pull request or the current branch diff.
---
```

This description policy follows the [Agent Skills specification](https://agentskills.io/specification).
Use recognizable domain terms and specific triggers so the agent can select the
skill. Include a short routing condition when a neighboring skill owns a similar
request.

For user-triggered workflows in this repository, set the invocation metadata
specified by the project instructions. Manual-only skills use both
`disable-model-invocation: true` and `agents/openai.yaml` with
`policy.allow_implicit_invocation: false`. Reusable skills retain their approved
agent-invocable status.

A useful body order is: purpose and entry conditions, required context,
workflow, recovery paths, and completion evidence. Use sections that help the
actual workflow; keep a quick-reference table when it makes decisions easier.

## Keep Context Focused

Skill names and descriptions are available for discovery; selected skill bodies
and supporting references load when needed. Keep essential decisions in
`SKILL.md`, and move long examples and specialist references to linked files.
Aim for a body under 500 lines. Length is a review signal; complete and
unambiguous instructions remain the goal.

Use one concrete example per distinct decision. Use numbered steps for sequences,
tables for mappings, and small flowcharts for non-obvious decisions or loops.
Choose a relevant language and make code examples runnable.

Reference another skill by name with a clear instruction:

> **REQUIRED SUB-SKILL:** Use superpowers:test-driven-development.

Reference supporting files with ordinary relative Markdown links and specify
when to read them. Resolve paths from the directory containing the skill.
For flowchart style, read [graphviz-conventions.dot](graphviz-conventions.dot).
Use `render-graphs.js` beside this skill to render diagrams to SVG.

## Verify the Change

### RED: Establish the Failure

Choose evidence appropriate to the change:

- For metadata, paths, and terminology constraints, run a focused validator
  against the current files and record the specific failure.
- For workflow behavior, run representative scenarios in an isolated agent
  session with the current instructions, or without the skill for a new skill.
  Record the observed actions and the expected outcome.
- For wording conflicts, identify the incompatible rules and the concrete
  scenario that forces a choice between them. Use that scenario for the
  subsequent behavior evaluation.

Use the available execution workflow and the user's authorization for agent
sessions. During direct execution, perform local checks and report any behavior
scenario that remains unevaluated.

### GREEN: Address the Observed Failure

Write the smallest instruction change that supplies the missing action or
resolves the conflict. Update its examples, checklists, and callers together.
Run the same validator or scenario with the updated instructions and compare
against the recorded baseline.

### REFACTOR: Check Composition

Read the changed skill together with its callers and required references.
Check actor ownership, terminology, approval conditions, recovery, and completion.
Remove duplicate rules and reconcile exceptions. Re-run affected checks after
changes.

For agent behavior testing, read
[testing-skills-with-subagents.md](testing-skills-with-subagents.md). Use normal,
ambiguous, and pressured scenarios, and evaluate on the models intended for use.
Keep predicted outcomes separate from observed results.

## Common Rationalizations for Skipping Verification

| Excuse | Required action |
|---|---|
| “The skill is obviously clear.” | Test a scenario that exercises its decision points. |
| “It's just a reference.” | Check retrieval, paths, and a representative application. |
| “This is only a wording change.” | Check the changed rule against its callers, examples, and checklist. |
| “The static checks pass.” | Report static results separately from model behavior evidence. |
| “There is no time for an evaluation.” | Complete available checks and state the remaining uncertainty. |

## Red Flags and Recovery

- Conflicting actions for the same condition: choose one rule and update its callers.
- Multiple names for one concept: use the shared term throughout.
- A prohibition without a useful action: remove it.
- A changed approval condition: verify it against the user's approved scope.
- A claimed model outcome without an observed run: label it as an expectation.

## Completion Checklist

Track these as checklist items in session state:

- [ ] Metadata and supporting references validate.
- [ ] Each changed rule has a clear condition and action.
- [ ] Callers, examples, and checklists agree.
- [ ] Skill terminology is consistent across the affected workflow.
- [ ] Focused checks have recorded results.
- [ ] Behavior evaluations have observed results or a stated limitation.
- [ ] Changes stay within the user's approved scope.

Report the changes and verification evidence. When publication is authorized,
use superpowers:create-pull-request against the approved fork and base branch.
The user owns integration.

## Authoring References

- [Agent Skills specification](https://agentskills.io/specification): metadata and package format.
- [OpenAI skill documentation](https://learn.chatgpt.com/docs/build-skills): discovery and progressive disclosure.
- [OpenAI prompting guidance](https://developers.openai.com/api/docs/guides/prompt-engineering): instruction structure and evaluation.
- [Anthropic authoring guidance](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices): terminology, examples, conditional workflows, and evaluation.

Read vendor guidance for the authoring question at hand. The local conventions
above define this repository's terminology, placement, and publication workflow.
