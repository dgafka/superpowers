---
name: recognize-and-learn
description: Use after an implementation cycle finishes to recognize friction — multi-attempt steps, unclear instructions, user corrections, things that weren't obvious — and learn from them by proposing process/skill improvements on a separate branch + PR
---

# Recognize and Learn

## Overview

A post-implementation retrospective skill. Identify what made the implementation process harder and propose concrete improvements.

Run this immediately after an implementation cycle so the friction is still fresh. Output is a proposed set of changes to skills / process docs, landed on a separate branch with its own PR.

**Announce at start:** "I'm using the recognize-and-learn skill — let's capture what slowed us down and propose process improvements."

## When to Use

- Immediately after an orchestrated implementation cycle finishes and the user has decided on integration
- After any non-trivial implementation cycle where you (or the user) noticed friction
- When the user explicitly asks for a retrospective on a recent task

**Skip when:** the task was trivial, or the user has already explicitly said the process was smooth.

## The Process

### Step 1: Establish Implementation Context

Before asking the user anything, gather what you can on your own:

- Recent commits on the current branch (`git log --oneline -n 30`)
- The approved task context and Orca completion reports, when available
- Any course-corrections, blockers, or escalations visible in conversation history
- **User-correction signals** — scan the conversation for moments where the user said something was wrong, should be done differently, or pushed back on your approach. Examples to look for verbatim:
  - "no, not like that" / "stop doing X" / "don't do Y"
  - "actually, do it this way instead"
  - "that's wrong" / "you missed X"
  - Repeated rewording of the same request (signals you misread it the first time)
  - Any place where the user supplied a fact, command, or path that you should have known or discovered yourself

Treat every correction as a **first-class learning signal**. They are the most reliable evidence of process gaps: the user already saw the friction, named it, and paid the cost of correcting it. List each correction with its specific context.

You will use this context to ask sharper questions and to draft specific proposals. Ground proposals in that evidence.

### Step 2: Ask the User for Friction Points

Ask **one open question** that invites a free-form answer, but seed it with concrete prompts so the user has something to react to:

> "Looking back at this implementation cycle, what made things harder than they should have been? Specifically:
> - Anything that required multiple attempts or course-corrections
> - Anything that wasn't obvious until you tried it
> - Steps that felt redundant, unclear, or out of order
> - Places where you had to manually intervene to keep things on track
> - Skills or tools that were missing, wrong, or hard to find
>
> I also noticed these moments where you redirected me — let me know which (if any) point to something worth fixing:
> [list each user-correction signal from Step 1, verbatim or near-verbatim, with one-line context]"

Wait for the answer. If the user replies tersely, ask **one** follow-up to drill into the most load-bearing pain point.

### Step 3: Summarize Findings for Review

Group the findings into clear categories. Pick whichever apply:

- **Process gaps** — workflow steps that are missing, wrong order, or unclear
- **Skill gaps** — a skill that should exist but doesn't, or an existing skill that misled
- **Tool gaps** — missing automation, scripts, or hooks
- **Task quality** — patterns in task context that caused implementation drift
- **User corrections** — what the user had to fix manually that the process should have caught
- **Environment** — repo conventions, configuration, dependencies

For each item, write a single tight paragraph: **what happened**, **why it cost time**, **a concrete fix proposal**.

Present this summary back to the user verbatim and ask: "Does this capture it? Anything to add, edit, or remove before I propose changes?"

Iterate until the user signs off.

### Step 4: Locate the Skills Repo

The proposed changes typically land in the superpowers fork — not in the project where the implementation happened. Before making changes:

1. Check whether the current working directory is the superpowers repo (has `skills/` and `CLAUDE.md` referencing superpowers)
2. If yes: use this checkout as the coordination surface
3. If no: ask the user for the absolute path to their superpowers checkout. Use the supplied path.

### Step 5: Route Approved Changes to Implementation

Invoke `orchestrator-agent` with the approved findings, skills-repository path,
proposed edits, and verification criteria. It owns launch approval and assigns
the changes to a dedicated implementation sub-worktree. Keep the retrospective
changes in a separate PR from the implementation that prompted them.

The implementation worker applies the approved edits, verifies them, and uses
`superpowers:create-pull-request` to publish against the approved fork and base.
Pass the template guidance below as context. If publication is unavailable,
report the verified branch, commits, and blocker. The user owns integration.

### Using the Project PR Template

Before opening the PR, check for a template:

```bash
ls.github/PULL_REQUEST_TEMPLATE.md.github/pull_request_template.md PULL_REQUEST_TEMPLATE.md 2>/dev/null | head -1
```

**If a template exists:** read it end-to-end. Then fill out **every section** with content from the retrospective. Fill each section with a concrete answer or a brief explanation of applicability. Map content like this:

- **Problem / motivation sections** → the friction summary from Step 3 (what broke, why it mattered, with concrete examples from the session)
- **Change sections** → 1-3 sentences summarizing the edits assigned in Step 5
- **Alternatives sections** → other process changes you considered and rejected, with one-line reasoning
- **Evaluation sections** → honest about what you did. If the retrospective is based on a single session, say so. Report the evidence actually collected.
- **Checklist sections** → only tick boxes that are genuinely satisfied. Leave unchecked boxes with a one-line note explaining why.
- **Environment / tool tables** → fill from the actual session: harness (Claude Code, Codex, etc.), model, model ID

Preserve the template headings, replace its placeholders, and prepare the body
as a file for `superpowers:create-pull-request` to publish with `--body-file`.

**If no template exists:** use the default structure from `superpowers:create-pull-request`,
with the approved friction summary as motivation.

Use a title identifying the retrospective topic, following the detected repository convention.

### Step 6: Report Back

Tell the user:

- Branch name and base branch
- Commit SHAs created
- PR URL if one was opened
- A one-sentence summary of what changed

Then stop. Integration of the retrospective changes is the user's call.

## When to Stop and Ask for Help

- The user's friction description is genuinely ambiguous and you can't draft a concrete proposal — ask one clarifying question
- The proposed change would conflict with existing skills the user might not want touched — flag it and let the user choose
- You cannot locate the superpowers repo — ask for the path; use the supplied location
- The PR template has sections you cannot honestly fill (e.g., asks for adversarial test results you didn't run) — surface this to the user instead of fabricating content

## Remember

- Gather implementation context **before** asking the user — sharper questions, better proposals
- **User corrections are first-class learning signals** — scan the conversation for them and surface each one in Step 2
- One open question with concrete prompts beats five narrow questions
- The implementation worker owns the separate sub-worktree and PR in the skills repo
- Be surgical: touch only what the friction findings require
- Follow the project's PR template if one exists; fill every section honestly
- Hand the resulting PR back to the user for integration

## Integration

**Typically called by:**
- **superpowers:orchestrator-agent** — the orchestration run that completed the implementation tasks

**Operates on:**
- The superpowers skills repo (separate from the project where the implementation happened)

**Completion:** Return the skills PR and its verification evidence to the user.
