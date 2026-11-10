---
name: router
description: Name the skill or flow that fits, check state when asked what's next, and return the next step. Use standalone, or inside a mission when the mission needs the next step.
disable-model-invocation: true
---

# Router

Before performing a skill, stating what it does, or recommending that a step be
skipped, load it with the Skill tool. The summaries here are orientation only.
If a named skill will not load, stop and say which one failed; never simulate its
output.

`mission` drives the main flow and owns its phases, scope table, gate table,
phase boundaries, and handback. This skill gives the next step; when a mission
is active, the mission owns the phase and gate decision.

## Answer shape

When the owner must act, end with one plain sentence: `Next step: <the action>`.
Name the exact skill or command, the work or document, why it is next, and what
it unlocks. Name the work in plain words, never by a ticket id or issue key. Why:
a key is for the tracker, not for the owner.

The next step is the action that unblocks the work now, not the phase after it.
Standalone, the next step is that action. Inside a mission, `mission` owns the
next step and the gate decision; read the mission document and name the action it
gives. A pending gate or an open stack outranks the next frontier, and the next
frontier waits until merges unblock it.

| Situation | Next step |
| --- | --- |
| A gate is pending | the owner approves the named document |
| A blocking PR is a draft | make it ready for review |
| A blocking PR has failing checks | fix the checks |
| A blocking PR is open and not mergeable | make it mergeable |
| A blocking PR is green and mergeable | the owner merges it |
| A blocking PR is closed unmerged | the owner decides |
| A stack has an unmerged bottom PR | the owner merges the bottom, then the next layer |

Next step: `/code-review` the open PR, because its checks are green and it is the
last gate before the merge.

When the next step is `/handoff`, the prompt is the deliverable. `handoff` owns
the prompt contract and the delivery format.

## State read order

`What's next`, `what now`, and `continue` are state questions, not classification
questions. Read the state in this order before you name a step, and before you
recommend any phase that starts new work.

1. Check for a mission. If the conversation is in a mission, or an active mission
   document exists, `mission` owns the phase, gate, and handoff decision. Read
   the mission document and name the action it gives. A mission can be active
   before its record exists, and the record is not authority. The gate is the
   owner's words in the conversation; never infer it from a record. Stop here;
   the rest of this procedure is the standalone path.
2. Read the standalone state. Read the ticket graph, the current branch, and the
   latest PR. Use the configured tracker, not memory. Why: a remembered state
   goes stale, and the tracker is the source.
3. Check the stack. Resolve each ticket in the frontier to its PR and read its
   state, base branch, checks, mergeability, and head SHA. On GitHub, use
   `gh pr view <n> --json state,isDraft,baseRefName,mergeable,mergeStateStatus,statusCheckRollup,mergeCommit,headRefOid`;
   on GitLab, use `glab mr view <n>` and read the draft, pipeline, base, and
   merge status. A ticket with no PR is done only when the tracker marks it
   completed; a canceled or duplicate ticket does not satisfy the graph. Why: a
   canceled ticket is not work, and a duplicate double-counts. A
   dependent ticket stacks on its blocker's branch, so it can be built before
   the blocker merges. A ticket with several blockers waits for all but one to
   merge, then stacks on the last. The next step is the bottom unmerged PR, not
   the next layer. Report each open PR's URL, base, check state, what changed,
   what it unlocks, and the merge danger. The owner merges bottom-up. The head
   SHA stays in the PR. Why: the SHA is for the machine; the owner's decision is
   the merge. After a merge, retarget the next layer to `main`, confirm
   the ticket is done, fetch `origin`, and rebase the next layer on the merge
   commit. A ticket that cannot stack waits for all its blockers' PRs to merge.
   Why: a PR with several bases is not reviewable.
4. Choose the session. Continue here when the next step stays inside the current
   frontier or session: a review, a fix, the PR, a pending gate, or the build
   through `implement` or `implement-spec`. Hand off when the next step needs a
   different context: a fresh worktree or directory, a new harness, a side task,
   or a full context. A new frontier in the same context stays in the session.
   Each worker gets its own subagent context. Inside a mission, `mission` owns the
   phase boundary and the handoff points.
5. Answer once. Name the gate or PR that decides the step, then one Next step
   line with the why and the unlock. Name a skill to load, not a phase to
   perform. When the choice is handoff, name `/handoff`, not the phase it will
   run, and produce the prompt with `handoff`; the prompt is the deliverable, and
   it goes in chat.

## Context hygiene

Keep the grill, spec, tickets, wayfinder decisions, and the mission record in one
unbroken context window so they build on the same thinking. Each worker then
starts fresh from its ticket; the crew chief keeps the graph.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
