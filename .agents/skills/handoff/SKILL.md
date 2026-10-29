---
name: handoff
description: Compact the current conversation into a handoff document and a next-session prompt for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save to the temporary directory of the user's OS (`$TMPDIR`, else `/tmp`; `%TEMP%` on Windows) - not the current workspace.

Inside a mission, the mission skill uses this contract automatically at planned session boundaries.

A next-ticket prompt waits until its blocking PRs are merged. If a blocking PR is open, the handoff is premature: report the PR URL, head SHA, and check state instead.

Include a "suggested skills" section in the document, naming which skills the next agent should call the Skill tool for.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.

## The prompt is the handoff

The document is the handoff summary; the prompt is the deliverable. End the
chat reply with one fenced `text` block the user can copy with one click. That
is the only copy of the prompt. Never put the delivered prompt in an issue, a
PR, a commit, the repo, or the mission document. If the mission document is an
issue, the issue gets the log line, not the prompt.

The prompt is self-contained:

- the handoff path or mission document;
- the fixed point (the merge commit), the next ready ticket, and the blocking
  PRs, plus the blocking edges after it;
- the current gate, the method that reached it, and its status when a mission
  is active;
- the skill to call first (the mission, the next phase, or `router` for a
  standalone flow), then `code-review` and `pr` per PR;
- the build and check commands;
- the handback: open one PR, run `code-review`, fix the findings, report the PR
  URL, head SHA, checks, and the next ready ticket. The user reviews and
  merges.

Write the prompt in the user's language and keep it positive: state the
desired end state and the user's merge step.
