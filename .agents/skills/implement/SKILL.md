---
name: implement
description: "Implement a piece of work based on a spec, ticket, or approved rule changes."
disable-model-invocation: true
---

# Implement

Implement the work the owner approved. The approved work is the rule changes and
the file scope in the mission document, not a proposal and not a draft PR.

If the owner passes a ticket reference, fetch it from the issue tracker and state
its title before starting. Use the title in replies, not the id. If the
reference is ambiguous, ask.

## Check the gate before the first edit

Read the mission document and the owner's words.

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
unlocks, and the merge danger. The head SHA stays in the PR and the handoff log.
Why: a SHA is a machine identifier; the owner's decision is the merge.

Commit your work to the current branch. Open one PR. The owner reviews and
merges.
