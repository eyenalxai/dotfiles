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

The document is the durable copy; the prompt is the deliverable. End the chat
reply with one fenced `text` block the owner can copy with one click, and put
the same block at the end of the document.

The prompt is self-contained:

- the handoff path or mission artifact;
- the fixed point (the merge commit), the next ready ticket, and the blocking
  PRs, plus the blocking edges after it;
- the current gate, the method that reached it, and its status when a mission
  is active;
- the skill to call first (the mission, the next stage, or `router` for a
  standalone route), then `code-review` and `pr` per PR;
- the build and check commands;
- the handback: open one PR, run `code-review`, fix the findings, report the PR
  URL, head SHA, checks, and the next ready ticket. The owner reviews and
  merges.

Write the prompt in the owner's language and keep it positive: state the
desired end state and the owner's merge step.
