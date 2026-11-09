---
name: implement
description: "Implement a piece of work based on a spec, ticket, or approved rule changes."
disable-model-invocation: true
---

# Implement

Implement the work the owner approved. The approved work is the rule changes and
the file scope in the mission document, not a proposal and not a draft PR.

This skill builds one ticket. A frontier of two or more ready tickets routes to
`implement-spec` as the crew chief. Why: the crew chief owns the graph and the
stack; one session per ticket would spread the graph across contexts.

If the owner passes a ticket reference, fetch it from the issue tracker and state
its title before starting. Use the title in replies, not the id. If the
reference is ambiguous, ask.

## Check the gate before the first edit

Read the mission document and the gate decision. On a fog path, the decision
gates must also be approved.

- If the gate is pending, stop and ask. Do not start with a "small" edit; a small
  edit is still a build.
- If the approval does not cover the edit, stop and ask. Do not widen the scope
  because the edit is "related."
- If the artifact is a proposal or a draft, it is not an approval. A draft PR is
  evidence of work, not permission to continue.
- If the approved scope is a rule plus a file pattern, implement only files that
  match the pattern. A new file outside the pattern reopens the gate.

Why: the prior session treated a handoff prompt as the owner's delegation and
built before the gate. A build makes the missing decision harder to see, because
the artifact looks like progress.

## Work the approved scope

The approved scope is the rule changes and the file scope. State them at the
level the owner approved: a list for a small change, a pattern plus exceptions
for a large one. The plan's length follows the number of decisions, not the
number of files. Why: per-file approval is a chore and does not scale; the PR is
the detailed review.

One ticket, one PR. A stacked ticket branches from its blocker's branch, and its
PR base is that branch. A ticket with several blockers stacks on the last one
after the others merge. The owner merges bottom-up. Why: the stack is the
approved model for dependent tickets, and a PR based on `main` would show the
blocker's diff again.

If the work needs a new decision, stop and ask. Do not add a file, a skill, a
script, or a test harness the owner did not approve. Why: the prior session added
an unasked `pushback` skill and a Python parser, and both looked like progress.

## Seams and checks

Call the Skill tool with `tdd` when the work has a code seam. Use the seams the
owner approved. For a markdown or prose change, there is no code seam; do not
invent a test framework. The check is the review of the changed text against the
repo's standard.

Run the commands the repo documents. If the repo has no build command, say so in
the PR. Do not invent one.

Once done, call the Skill tool with `code-review` to review the work. Fix the
findings. Then call `pr` to shape the PR body.

## Reporting

Put the answer or the work first. Explain the why in the body when it helps the
decision; do not open with a status block. After a step, say what changed and
what it unlocks. Inside a mission, the mission output contract owns the reply
shape and the ask-don't-invent rule. Outside a mission, ask when the why is
missing and record the answer in the ticket.

The handback report carries the PR URL, the check state, what changed, what it
unlocks, and the merge danger. The head SHA stays in the PR.
Why: a SHA is a machine identifier; the owner's decision is the merge.

Commit your work to the current branch. Open one PR. If the ticket is stacked,
open it against its blocker's branch. The owner reviews and merges bottom-up.

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
