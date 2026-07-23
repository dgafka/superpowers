---
name: improve-workflow
allowed-tools: Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh api:*), Bash(git log:*), Bash(git diff:*), Bash(git show:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(cat:*), Bash(ls:*)
disable-model-invocation: false
description: >-
  Mine a pull request's review feedback for repeatable lessons, then hand
  them to brainstorming to turn each into a CI rule or an agent skill/rule
  so future work stops repeating the same mistakes. Use when the user asks
  to improve the workflow from a PR's review feedback, learn from PR review
  comments, turn review feedback into enforceable rules or agent skills, or
  invokes /improve-workflow.
---

Mine a pull request's review feedback for lessons worth keeping, then route each
one to where it will actually prevent recurrence — a **CI rule** that fails the
build next time, or an **agent skill/rule** that steers generation next time.
Feedback that is purely one-off (specific to this feature's business logic) is
recognized and deliberately dropped.

This command is a thin collector. Its only hard job is to gather the review
signals and correlate each with the fix that followed. Everything from
categorization onward — deciding which lessons are worth enforcing and designing
how to apply them — is **led by the brainstorming skill**, which owns the rest of
the pipeline (`brainstorming → executing-specs`).

Run it **inside the project the PR belongs to** (superpowers installed as a
plugin), so the resulting improvements land where they belong: the project's CI
config and its `.claude/` / `CLAUDE.md`. Everything repo-specific (which linters
exist, ticket format) is detected at runtime — this command carries none of a
project's own conventions as fixed values.

## Reader-Friendly Output

Before presenting the collected summary, apply the shared reader-friendly rule
set — @commands/references/reader-friendly-writing.md. The summary is a write-up
the user reads to understand what the review surfaced — it should be why-first,
behavior-level, scannable, and free of code the reader can already see in the
diff.

## Process

### 1. Resolve the PR

- `$ARGUMENTS` is a GitHub PR reference — a URL or `owner/repo#123`. Resolve it
  to `{owner}`, `{repo}`, and `{number}`.
- Confirm access and get the basics: `gh pr view <ref> --json
  title,body,number,url,headRefName,baseRefName,state`.
- If no argument is given, try `gh pr view --json ...` with no ref to resolve an
  open PR for the current branch. If none exists, stop and ask the user for a PR
  reference.

### 2. Collect Every Review Signal

Fetch all comment surfaces — a lesson can live in any of them:

- **Inline review comments** (anchored to file/line):
  `gh api repos/{owner}/{repo}/pulls/{number}/comments`
- **Reviews / top-level review bodies** (approve, request-changes, summary):
  `gh api repos/{owner}/{repo}/pulls/{number}/reviews`
- **General PR (issue) comments**:
  `gh api repos/{owner}/{repo}/issues/{number}/comments`

Capture, per comment: author, timestamp, body, and (for inline comments) the
`path` and line anchor. Preserve threading so a back-and-forth reads as one
discussion.

### 3. Correlate Each Comment With the Fix That Followed

The strongest signal of a repeatable rule is the **delta between what the
reviewer flagged and what the author actually changed** — not the comment text
alone.

- Get the change history: `gh pr diff <ref>` and
  `git log <baseRefName>..<headRefName> --oneline` (fall back to
  `git log` against the PR head if the branch isn't checked out locally).
- For each inline comment, use its `path`, line anchor, and timestamp to find
  the commits/diff hunks that landed **after** it and touch the same area.
- Summarize each thread as a **flagged → changed** pair: what was raised, and
  what (if anything) changed in response.
- Where a comment produced no corresponding change, note it as **unaddressed** —
  it's still a candidate lesson.

### 4. Draft-Categorize

Pre-sort each collected signal into one of three buckets. This is a **starting
point** for brainstorming to accept or override, not the final word.

| Bucket | Meaning | Fate |
|---|---|---|
| **1. PR-only** | Business / logic / flow feedback specific to this feature; no future value once fixed | Recognized, then **dropped** |
| **2. Enforced rule** | Expressible as a CI rule that fails future builds | → CI rule candidate |
| **3. Agent-driven** | A habit better steered by an agent skill or a `CLAUDE.md` rule | → skill/rule candidate |

For bucket 2, PHP is the assumed default vocabulary (phpcs, phpstan,
deptrac-style architecture rules). But **only propose rules for tooling that
actually exists in the repo** — detect it first:

- `phpcs.xml` / `phpcs.xml.dist` → phpcs
- `phpstan.neon` / `phpstan.neon.dist` → phpstan
- `deptrac.yaml` / `depfile.yaml` (or equivalent) → architecture rules
- `composer.json` `require-dev` → confirms which tools are live

Propose *adding* a tool only when a lesson clearly warrants it and none of the
existing tools can express the rule.

### 5. Present the Collected Summary

Show the user a why-first, scannable summary of what the review surfaced:
threads grouped by draft bucket, each as a one-line **flagged → changed** with
its proposed bucket. Lead with buckets 2 and 3 (the ones with future value);
list bucket 1 briefly so the user can see what's being dropped and why. Flag
unaddressed comments explicitly.

State plainly that this is a draft categorization — brainstorming will confirm
or override it with the user.

### 6. Hand Off to Brainstorming

Invoke the **brainstorming** skill, seeding it with the collected +
draft-categorized summary as the idea to explore. From here, brainstorming
leads:

- Confirm / refine the categorization with the user; drop bucket 1.
- Present buckets 2 and 3 as improvement candidates; get the user's agreement on
  which to pursue.
- Design *how* to apply each agreed improvement — a **new** rule/skill vs. an
  **update** to an existing one.
- Its own pipeline (`brainstorming → executing-specs`) applies the agreed
  improvements in the project.

Do **not** invoke `executing-specs`, `recognize-and-learn`, or any other skill
directly from this command — brainstorming owns the rest of the pipeline.

## Notes

- This command never applies fixes itself — `brainstorming → executing-specs`
  does. It collects, correlates, draft-categorizes, and hands off.
- Bucket 1 (PR-only) feedback is recognized then dropped; it is never carried
  forward.
- Which linters/static-analysis tools exist is always detected at runtime — PHP
  is the assumed vocabulary, not a fixed requirement.
- This is not `recognize-and-learn`: that learns from the live conversation;
  this learns from a PR's review feedback and shares none of its machinery.
