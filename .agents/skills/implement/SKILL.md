---
name: implement
description: "Implement a piece of work based on a spec, ticket, or approved rule changes."
disable-model-invocation: true
---

# Implement

Implement the work the owner approved. The approved work is the rule changes and
the file scope in the mission document, never a proposal and never a draft PR.

This skill builds one ticket. A frontier of two or more ready tickets routes to
`implement-spec` as the crew chief. Why: the crew chief owns the graph and the
stack, and one session per ticket would spread the graph across contexts.

If the owner passes a ticket reference, fetch it from the issue tracker and state
its title before starting. Use the title in replies, never the id. If the
reference is ambiguous, ask.

## Check the gate before the first edit

Read the mission document and the gate decision. On a fog path, the decision
gates must also be approved.

- If the gate is pending, stop and ask. Never start with a small edit; a small
  edit is still a build.
- If the approval does not cover the edit, stop and ask. Never widen the scope
  because the edit is related.
- If the artifact is a proposal or a draft, it is not an approval. A draft PR is
  evidence of work, not permission to continue.
- If the approved scope is a rule plus a file pattern, implement only files that
  match the pattern. A new file outside the pattern reopens the gate.

Why: a build makes a missing decision harder to see, because the artifact looks
like progress.

## Work the approved scope

The approved scope is the rule changes and the file scope. State them at the
level the owner approved: a list for a small change, a pattern plus exceptions
for a large one. The plan's length follows the number of decisions, not the
number of files. Why: per-file approval is a chore and does not scale; the PR is
the detailed review.

One ticket, one PR. A stacked ticket branches from its blocker's branch, and its
PR base is that branch. A ticket with several blockers stacks on the last one
after the others merge. The owner merges bottom-up. Why: a PR based on `main`
would show the blocker's diff again.

If the work needs a new decision, stop and ask. Never add a file, a skill, a
script, or a test harness the owner did not approve. Why: unasked work looks like
progress, and the owner did not approve it.

## Seams and checks

Call the Skill tool with `tdd` when the work has a code seam. Use the seams the
owner approved. A markdown or prose change has no code seam; never invent a test
framework. The check is the review of the changed text against the repo's
standard.

Run the commands the repo documents. If the repo has no build command, say so in
the PR. Never invent one.

Once done, call the Skill tool with `code-review` to review the work. Fix the
findings. Then call `pr` to shape the PR body.

## Reporting

Put the answer or the work first. Explain the why in the body when it helps the
decision; never open with a status block. After a step, say what changed and what
it unlocks. Inside a mission, the mission output contract owns the reply shape
and the ask-don't-invent rule. Outside a mission, ask when the why is missing and
record the answer in the ticket.

The handback report carries the PR URL, the check state, what changed, what it
unlocks, and the merge danger. The head SHA stays in the PR. Why: a SHA is a
machine identifier; the owner's decision is the merge.

Commit your work to the current branch. Open one PR. If the ticket is stacked,
open it against its blocker's branch. The owner reviews and merges bottom-up.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
