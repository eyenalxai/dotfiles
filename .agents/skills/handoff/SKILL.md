---
name: handoff
description: Compact the current conversation into a handoff document and a next-session prompt for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

# Handoff

Package the current state so a fresh session can resume without re-litigating settled work.

## Roles

- **Orchestrator (`opencode-go/kimi-k3.1-pro`)**: writes the handoff document and the chat prompt. Both are owner-read and control the next session's direction.
- **Worker (`openrouter/deepseek/deepseek-v4.1-flash-1017#max`)**: if reference paths, URLs, open PRs, or stack states need verification before handoff, run one `explore` or `general` worker to check them and return a compact status table.

## When to hand off

Hand off only when the work travels or the current context cannot carry it: context is nearly full, a side task needs isolation, the next step moves to another directory or harness, or the owner asks. Never hand off for a normal phase change in the same session; worker subagents already isolate implementation and research without forcing a copied prompt and a fresh gate confirmation.

## Outputs

1. **Scratch handoff doc**: save to the OS temp directory (`$TMPDIR`, fallback `/tmp`; `%TEMP%` on Windows), never inside the repo. It is session transport, not a deliverable. Reference specs, ADRs, issues, commits, and diffs by path or URL instead of copying them, so nothing drifts. Redact secrets, tokens, and PII. Include a `Suggested skills` section listing the skills to load in order.
2. **Next-session prompt (the deliverable)**: end the chat reply with one fenced `text` block ready to copy. This is the only copy of the prompt. Never paste a delivered prompt into an issue, PR, commit, repo file, or mission document, because durable text gets mistaken for owner authority by later sessions.

If the owner passed arguments, focus the handoff on that next-session goal. Inside an active mission, follow the `mission` output contract around the prompt block.

## Gate integrity

A handoff prompt **reports** a gate; it **never grants** one. The agent writes the prompt, so treating a prompt as approval lets the agent approve its own work.

- If a gate is pending: write `Open gate: pending` and name the decision.
- If a gate was approved earlier: write `Open gate: approved, confirm it still holds` and name the decision. The next session presents it and waits for the owner's words.
- If a gate does not apply to the scope: write `Open gate: not used`.

Never write "the scope is approved" as settled authority, never write "decide this first", never quote the owner's words, and never name who decided.

## What the prompt must carry

- Work item issue title and team (never its tracking key or URL), or `No work item record exists; do not create one before the gate` plus the grill ledger and open questions.
- Goal, why the next step is next, and what it unlocks.
- Scope, settled decisions, rejected options (marked `Do not re-offer` with reason), and session plan.
- Base commit, open PRs in bottom-up merge order, stack order, next frontier in plain words, and remaining blocking edges. A stacked ticket can start once its blocker's branch exposes the needed interface; a ticket with multiple blockers waits until all but one merge, then stacks on the last.
- Current gate, how it was reached, and its status (`pending`, `approved, confirm it still holds`, or `not used`).
- Approved rule changes and file scope (a file list for small changes; a pattern plus exceptions for large ones).
- Top references for the next phase by path or URL, marking broken ones `stale: <what changed>`.
- Ordered skills to load with the Skill tool, plus the stop rule: if a named skill fails to load, stop and name it instead of simulating it.
- Exact build and check commands.
- Execution model: orchestrator (`opencode-go/kimi-k3.1-pro`) owns the forest, gates, and owner-facing artifacts; workers (`openrouter/deepseek/deepseek-v4.1-flash-1017#max`) handle exploration, research, implementation, and diff reviews.
- Output contract and handback: answer first, no status header, one plain `Next step:` sentence when the owner must act; open one PR per ticket stacked by edge, run `code-review`, report the stack bottom-up with URL, check state, what changed, what it unlocks, and merge danger (keep head SHAs in the PR).

## What the prompt must exclude

- History of any kind: prior attempts, prior sessions, prior issues, or earlier versions. History invites the next session to reopen settled work.
- Unsourced constraints: label any unapproved constraint `proposed`.
- Direct quotes from the conversation or names of who decided.
- Tracking keys or head SHAs in the prose around the prompt.

## Starting shape

```text
Find the work item issue in team <team> by its title: <title>. Run /mission continue.
Goal: <goal>.
Current gate: <gate>, reached with <method>. Open gate: <pending | approved, confirm it still holds | not used>.
Rule changes: <list or pattern>. File scope: <list or pattern>. Out of scope: <what is out>.
Rejected options (do not re-offer): <option: reason>.
Open PRs (merge order, bottom-up): <urls, or none>. Base commit: <sha>.
Next frontier: <plain name>: <why it is next and what it unlocks>. Tracking keys live in the mission document.
References for <phase>: <paths or URLs, with stale marks if broken>.
Load these skills in order with the Skill tool: <skills>. If any skill fails to load, stop and name it; never simulate its output.
Orchestrator (opencode-go/kimi-k3.1-pro) owns decisions, gates, and owner-facing writing; delegate exploration, research, implementation, and diff review to workers (openrouter/deepseek/deepseek-v4.1-flash-1017#max) and critique before accepting.
Checks: <commands>. Open one PR per ticket, stacked by edge, run code-review on each, and report the stack bottom-up (PR URL, check state, what changed, what it unlocks, merge danger). Keep head SHAs in the PR. The owner reviews and merges bottom-up.
```

*(Replace the first line with `No work item record exists; do not create one before the gate.` and include the grill ledger and open questions when handing off before the first gate.)*

## Audit before sending

Read the prompt as the next session will:

- [ ] No claimed approval without owner confirmation in the new session.
- [ ] Every rejected option carries a reason and `Do not re-offer`.
- [ ] Every unsourced constraint is labeled `proposed`.
- [ ] Every broken reference is marked `stale: <what changed>`.
- [ ] Large changes state rule + file pattern, not a per-file list.
- [ ] No quotes, no names of deciders, no history, no head SHAs in chat prose.
- [ ] Stacks state both stack order and bottom-up merge order, never treated as a queue.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
