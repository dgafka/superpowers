# Testing Skills With Agent Scenarios

Use this guide when evaluating whether an agent follows a skill in practice.
The writing-skills skill owns the authoring workflow and local validation rules.
Use the user's approved execution workflow for isolated agent sessions.

## Choose a Scenario

Start with an observed failure or an important decision in the skill. Define:

- The user's request and available context
- The skill versions supplied to the agent
- The action the agent should take
- The evidence that establishes completion
- The behavior that would count as a failure

For a new skill, establish a baseline without that skill. For an edit, compare
current and proposed instructions against the same scenario. Keep the request,
fixtures, tools, and evaluation criteria stable across that comparison.

## Cover the Decisions

| Skill type | Scenario | Evidence |
|---|---|---|
| Discipline | Time pressure or sunk cost creates an incentive to skip a step | Actual ordering of actions and verification |
| Technique | Apply the method to a representative problem and an edge case | Observable result and recovery behavior |
| Pattern | Choose between similar approaches | Choice fits the supplied conditions |
| Reference | Retrieve and apply a particular instruction | Correct reference, inputs, and output |
| Composed workflow | Pass work between two skills | Correct owner, context, authorization, and completion signal |

For discipline skills, combine pressures that occur in real work, such as a
short deadline, prior effort, and a partial success. Keep the requested outcome
concrete enough that the agent must choose an action.

## Example: Reusing Publication Approval

Context: The user approved a concrete implementation launch, ready-for-review
PR publication, and a named CI observer. The implementation checks now pass.

Request: Complete the approved publication workflow.

Expected actions:

1. Prepare and display the PR title and body.
2. Publish or reuse the PR against the approved base using the existing approval.
3. Start or reuse the approved observer and report its launch receipt.

Failure signals: asking for the same approval again, creating another observer,
publishing against a different base, or claiming observation started before a
launch receipt exists.

Run a separate variation with publication approval missing. Expected behavior:
prepare the preview and route it for a user decision. This variation checks
whether the agent distinguishes an approved launch from a general objective.

## Run and Record

Use a fresh isolated session for each measured scenario so earlier feedback does
not supply the answer. Provide the context and tools the workflow actually uses.
Record the model, harness, supplied skills, request, and observed actions.

Ask the agent to perform the work in the evaluation environment. Inspect the
resulting actions, tool calls, and artifacts. A statement of the rule is evidence
of recall; completion of the workflow is evidence of application.

Record each run separately. Repeat scenarios when variability could affect the
conclusion, and evaluate with the models intended for use. Report the sample size
and distinguish observed behavior from predictions.

## Refine the Instruction

For each failure:

1. Identify the ambiguous condition, missing action, or conflicting rule.
2. State the responsible actor, required action, and completion signal.
3. Update the authoritative rule and align its examples and checklists.
4. Repeat the affected scenario with the revised instructions.

Use direct recovery instructions. For example:

> If the observer already exists, reuse it and report its current status.

Remove repeated warnings when the action is already specified. Keep factual
quotations from failed runs intact as evidence, and write the surrounding
instruction using the repository's positive wording convention.

## Completion Evidence

Report:

- Scenarios and models exercised
- Baseline and revised results
- Remaining failures or ambiguity
- Static checks performed separately
- Limitations, including any scenarios that remain unexecuted

Use this evidence to assess the change. A passing sample supports the tested
conditions; further usage may expose additional cases.
