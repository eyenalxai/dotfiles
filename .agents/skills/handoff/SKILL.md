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

Inside a mission, the mission skill uses this contract at planned session
boundaries. When a mission is active, the mission output contract owns the reply
around the prompt.

A handoff is for travel, not for a phase change. When the next step stays in the
current session, use a subagent when the work is parallel or isolated, and keep
the mission session as the crew chief. A subagent is a worker inside the session,
not a handoff. Why: the worker keeps the approved context, and a handoff forces a
copied prompt and a new gate confirmation.

A stack handback reports the stack's open PRs and stops. The next frontier waits
until merges unblock it. A stacked ticket may start when its blocker's branch
has the interface it needs, even if the blocker's PR is open; the prompt carries
the stack order and the merge order. A ticket with several blockers waits for
all but one to merge, then stacks on the last. A ticket that cannot stack waits
for all its blockers' PRs to merge. Why: a stack that is not reported as a stack
looks like a queue, and the owner cannot see the merge order.

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
the repo, or the mission document. The record gets no log line and no prompt.
Why: a prompt pasted into a durable record becomes state the owner did not
approve, and the next agent treats the record as authority.

## The prompt reports the gate, it never grants it

The prompt may say that a gate was approved, pending, or not used. It reports
the decision, never the words, never the user, and never the name of the person
who decided. It may not turn that decision into a new approval. The next
session presents the gate with its recorded status and waits for the owner's
words. The owner may confirm the earlier decision in their own words; the agent
never assumes it. Why: the prompt is written by the agent; if a prompt can grant
a gate, the agent can approve its own work.

An approval does not carry on its own. A fresh session is a fresh conversation,
and the owner's words in the old conversation are not the owner's words in the
new one. If the record says a gate is approved, present it that way and ask the
owner to confirm it still holds. If the gate is pending, state the decision to be
made and ask. Do not write "the scope is approved" as a fact, and do not carry
the old words. Why: a prompt that says the earlier approval carries is still the
agent's words, and the owner did not speak them in the new conversation.

If the gate is pending, say `Open gate: pending` and name the decision. If the
gate is approved, say `Open gate: approved, confirm it still holds` and name the
decision. Do not write "the scope is approved" as a fact, and do not write
"decide this first." The first is a false record; the second is the agent
delegating the owner's decision to itself.

## What the prompt carries

The prompt is self-contained:

- the work item issue title and team, not its id or URL, or that no record
  exists yet and the next session must not create one before the gate;
- the goal, why the next step is next, and what it unlocks;
- the mission flow, the decisions that constrain the work, and the session
  plan;
- the base commit, the stack order, the open PRs, and the next frontier in plain
  words, plus the blocking edges after it;
- the current gate, the method that reached it, and whether it is approved or
  pending, stated neutrally and never with words or a name;
- the current state only, with no prior attempts, sessions, issues, or versions;
- the grill ledger and the open questions when no record exists yet;
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
- the handback: the crew chief opens one PR per ticket, stacked by edge; run
  `code-review` on each and fix the findings; report the stack bottom-up with
  each PR URL, check state, what changed, what it unlocks, and the merge danger.
  Name the next frontier in plain words. The owner merges bottom-up.

The prompt is the one place that carries the full mission state. It names the
work item issue by title and team, not by id or URL. The reply around it does not
repeat the state, and it does not print a ticket id, mission id, or issue key in
the prose.

Write the prompt in the owner's language and keep it positive: state the
desired end state and the owner's merge step. Name the load chain in order, for
example `wayfinder`, then `grilling` and `domain-modeling`, or `implement` for
one ticket, or `implement-spec` for a frontier, then `tdd` and `code-review`.

## What the prompt must not carry

- A rejected option, unless the prompt names it as rejected with the reason and
  says `Do not re-offer`. Why: a bare rejected option reads as an open choice,
  and the next session re-offers it.
- A constraint with no source. Label it `proposed` when it is not in the record
  or the decision. Why: a proposal that looks like a decision closes a question
  that was never answered.
- A stale reference without a mark. Write `stale: <what changed>` when the path
  or URL no longer holds. Why: the next session spends its first round
  discovering the reference is gone.
- An approval the owner did not give. Why: that is the failure this contract
  exists to prevent.
- A direct quote, a mention of the user, or the name of the person who decided.
  State the decision in neutral language. Why: the prompt is read as authority,
  and a name or a quote ties that authority to one message.
- History of the issue or mission: prior attempts, sessions, issues, or versions.
  State the current state only. Why: history invites the next session to reopen
  a settled decision.

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
6. Does it say `head SHA` in the human report? If yes, move the SHA to the PR;
   the human report carries the decision.
7. Does it quote, mention the user, name who decided, or carry history? If yes,
   rewrite it as neutral current state.
8. Does it treat a stack as a queue? If yes, state the stack order and the merge
   order. Why: the owner merges bottom-up, and a queue hides the layers.

This is a reading, not a program. There is no build command for a prompt. Why:
the gate is the owner's words, and a program can only check the agent's text
against itself.

## Pushback

When the owner challenges a finding, a recommendation, or a fact, name the claim
and its check before you reply. A claim about the owner's position points to the
owner's message; no source, no claim. A check is evidence that can fail: a
command, a test, a doc line, a repro, or a measurement against an agreed
threshold. A failed check stops the work: show it, keep the finding, and say what
would change it, because an instruction cannot make a failing check pass. A
direct instruction does not resolve a failed check. No check means a preference
or a reversible judgment, and the owner decides it: state the tradeoff once, then
follow the instruction, because the owner owns the decision and the agent owns
the facts. When the challenge adds a new fact, change the position and name what
changed it; keep the parts that were right. Never open with agreement or an
apology; agreement needs a reason, and tone is not evidence.

Why: a model reads disagreement as evidence and folds, which turns the owner's
first guess into the final answer.
