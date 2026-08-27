---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming Ideas Into Designs

Turn ideas into approved conversational designs through collaborative dialogue.

<HARD-GATE>
Do NOT invoke an implementation skill, write code, scaffold a project, or take any implementation action until you have presented a design and the user has approved it. This applies to every project regardless of perceived simplicity.
</HARD-GATE>

## Checklist

Create a task for each item and complete them in order:

1. **Explore project context** — inspect relevant files, docs, recent commits, and environment/test conventions.
2. **Offer visual companion** — only when upcoming decisions are materially visual.
3. **Ask clarifying questions** — one decision at a time; understand purpose, constraints, and success criteria.
4. **Propose 2-3 approaches** — explain trade-offs and lead with a recommendation.
5. **Present the design** — validate sections incrementally, scaled to complexity.
6. **Summarize the approved design** — keep the complete implementation context in conversation.
7. **Hand off deliberately** — for implementation-oriented work, tell the user to invoke `orchestration-research` with any optional run-wide guidance.

## Understanding the Idea

- Start with the current project state and follow its existing patterns.
- If the request contains multiple independent subsystems, decompose it before refining details.
- Ask one question at a time. Each answer should shape the next question.
- Prefer glance-and-pick options with the recommended option first when the platform supports them.
- Use open text for names, values, and choices that do not fit meaningful options.
- Focus on purpose, boundaries, risks, success criteria, and how the environment is set up and verified.

## Exploring Approaches

Propose 2-3 genuinely different approaches with their trade-offs. Recommend one and explain why. Apply YAGNI: remove features and abstractions that do not serve the stated goal.

## Presenting the Design

Invoke the **reader-friendly-writing** skill and apply it to the design presentation.

Scale each section to its complexity and ask whether it looks right before moving on. Cover what is relevant:

- Why the change is needed and what behavior changes
- Boundaries and responsibilities
- Components and interfaces
- Data or control flow
- Dependency and concurrency opportunities
- Error handling and recovery
- Testing and acceptance signals

Describe behavior in the main narrative. Keep code identifiers to the technical grounding needed to make implementation unambiguous.

## Design for Isolation

Break work into units with one clear purpose, explicit dependencies, and observable outcomes. For every unit, answer:

- What does it do?
- What does it depend on?
- How can another worker use or verify it without reading its internals?

Identify units that may proceed concurrently and those whose behavior or branch base depends on earlier work. Avoid unrelated refactoring.

## Completion

After the user approves all design sections, provide a compact final design summary in conversation. Include the goal, chosen approach, boundaries, dependency shape, risks, and acceptance criteria.

Do not write a design document or dispatch implementation. For work that needs research or implementation, direct the user to invoke the manual-only `orchestration-research` skill. That skill owns research delegation, task approvals, Orca sub-worktrees, implementation coordination, and stacked pull requests.

## Visual Companion

When upcoming questions involve layouts, diagrams, or visual comparisons, offer the browser companion once in its own message:

> Some of what we're working on might be easier to explain if I can show it to you in a web browser. I can put together mockups, diagrams, comparisons, and other visuals as we go. This feature is still new and can be token-intensive. Want to try it? (Requires opening a local URL)

If accepted, read `skills/brainstorming/visual-companion.md`. Use the browser only when seeing the choice is easier than reading it; keep conceptual and scope questions in the terminal.

## Key Principles

- **One question at a time** — each answer shapes the next.
- **Glance-and-pick over prose** — make decisions easy to scan.
- **YAGNI ruthlessly** — remove unrequested work.
- **Explore alternatives** — do not lock onto the first plausible design.
- **Incremental validation** — get approval section by section.
- **Conversation is the design record** — preserve the approved context for orchestration.
