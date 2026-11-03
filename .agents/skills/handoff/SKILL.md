---
name: handoff
description: Compact the current conversation into a handoff document and a next-session prompt for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

# Handoff

Write a handoff document summarising the current conversation so a fresh agent
can continue the work. Save it to the temporary directory of the owner's OS
(`$TMPDIR`, else `/tmp`; `%TEMP%` on Windows), not the current workspace. Why:
the document is a scratch artifact, not a deliverable; the repo should not carry
session transport.

Inside a mission, the mission skill uses this contract automatically at planned
session boundaries. When a mission is active, the mission output contract owns
the reply around the prompt.

A next-ticket prompt waits until its blocking PRs are merged. If a blocking PR
is open, the handoff is premature: report the PR URL, check state, what changed,
what it unlocks, and the merge danger instead. Why: a handoff that starts the
next ticket while its blocker is open creates a stacked PR the owner did not ask
for.

Include a "suggested skills" section in the document, naming which skills the
next agent should load with the Skill tool, in order.

Do not duplicate content already captured in other artifacts (specs, plans,
ADRs, issues, commits, diffs). Reference them by path or URL instead. Why: a
copy drifts from the source, and the next session cannot tell which copy is
current.

Redact any sensitive information, such as API keys, passwords, or personally
identifiable information.

If the owner passed arguments, treat them as a description of what the next
session will focus on and tailor the document accordingly.

## The prompt is the handoff

The document is the summary; the prompt is the deliverable. End the chat reply
with one fenced `text` block the owner can copy with one click. That is the only
copy of the prompt. Never put the delivered prompt in an issue, a PR, a commit,
the repo, or the mission document. The mission document gets the log line, not
the prompt. Why: a prompt pasted into a durable record becomes state the owner
did not approve, and the next agent treats the record as authority.

## The prompt reports the gate, it never grants it

The prompt may say that a gate was approved, pending, or not used. It may quote
the owner's words. It may not turn those words into a new approval. The next
session presents the gate and waits for the owner's words, unless the owner
explicitly says the earlier approval carries. Why: the prompt is written by the
agent; if a prompt can grant a gate, the agent can approve its own work.

An approval does not survive a handoff. There is no exception. A fresh session
is a fresh conversation, and the owner's words in the old conversation are not
the owner's words in the new one. Quote the old words as context, mark the gate
`pending` in the new session, and ask. Why: a prompt that says the earlier
approval carries is still the agent's words, and the owner did not speak them in
the new conversation.

If the gate is pending, say `Open gate: pending` and name the decision. Do not
write "the scope is approved" or "decide this first." The first is a false
record; the second is the agent delegating the owner's decision to itself.

## What the prompt carries

The prompt is self-contained:

- the mission issue title and team, not its id or URL. The prompt carries the
  state, so the next session can start without opening the issue;
- the goal, why the next step is next, and what it unlocks;
- the mission flow, the decisions that constrain the work, and the session
  plan;
- the fixed point (the merge commit), the next ready work in plain words, and
  the blocking PRs, plus the blocking edges after it;
- the current gate, the method that reached it, and whether it is approved or
  pending;
- the approved rule changes and the file scope, at the level the change needs: a
  list for a small change, a pattern plus exceptions for a large one;
- the skills to load first, in order (the mission, the next phase, or `router`
  for a standalone flow), then `code-review` and `pr` per PR;
- the stop: if a named skill will not load, stop and say which one failed; do
  not simulate its output;
- the build and check commands;
- the output contract the next session must use: answer first, no status block,
  state in the mission document, one plain Next step sentence when the owner
  must act;
- the handback: open one PR, run `code-review`, fix the findings, report the PR
  URL, check state, what changed, what it unlocks, and the merge danger. Name
  the next ready work in plain words. The owner reviews and merges.

The prompt is the one place that carries the full mission state. It names the
mission issue by title and team, not by id or URL. The reply around it does not
repeat the state, and it does not print a ticket id, mission id, or issue key in
the prose.

Write the prompt in the owner's language and keep it positive: state the
desired end state and the owner's merge step. Name the load chain in order, for
example `wayfinder`, then `grilling` and `domain-modeling`, or `implement`, then
`tdd` and `code-review`.

## What the prompt must not carry

- A rejected option, unless the prompt names it as rejected with the reason and
  says `Do not re-offer`. Why: a bare rejected option reads as an open choice,
  and the next session re-offers it.
- A constraint with no source. Label it `proposed` when it is not in the mission
  or the owner's words. Why: a proposal that looks like a decision closes a
  question the owner never answered.
- A stale reference without a mark. Write `stale: <what changed>` when the path
  or URL no longer holds. Why: the next session spends its first round
  discovering the reference is gone.
- An approval the owner did not give. Why: that is the failure this contract
  exists to prevent.

## Check before delivering

Read the prompt as the next session would.

1. Does it claim an approval the owner did not give? If yes, cut the claim and
   mark the gate pending.
2. Does it list a rejected option without `Do not re-offer`? If yes, add the
   reason.
3. Does it carry a constraint with no source? If yes, label it `proposed`.
4. Does it point at a missing reference without marking it stale? If yes, mark
   it.
5. Does it name a per-file approval list for a large change? If yes, replace it
   with the rule and the file scope.
6. Does it say `head SHA` in the human report? If yes, move the SHA to the PR
   and the log; the human report carries the decision.

This is a reading, not a program. There is no build command for a prompt. Why:
the gate is the owner's words, and a program can only check the agent's text
against itself.
