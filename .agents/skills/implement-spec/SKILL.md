---
name: implement-spec
description: "Implement a frontier of two or more tickets as a stack of per-ticket PRs, or one integration PR when the owner asks."
disable-model-invocation: true
---

# Implement spec

You have been provided a spec. The spec has tickets that describe how to
implement it.

The issue tracker comes from the repo's agent docs. If it is missing, ask the
owner for the tracker.

The goal is the frontier implemented as one PR per ticket, stacked by blocking
edge, or one integration PR when the owner asks. This skill runs the crew chief
role: it claims the ready tickets, runs one worker subagent per ticket, reviews
each PR, and reports the stack bottom-up. The owner merges.

A one-ticket frontier uses `implement`. This skill runs two or more tickets. When
the harness cannot isolate checkouts, run the tickets one at a time in the same
session and say so. Why: parallel edits in one checkout conflict, and a single
ticket has no graph for the crew chief to run.

The mission session loads this skill and acts as the crew chief. A fresh session
is needed only when the work travels or the current context cannot continue. A
subagent is a worker inside the session, not a handoff. Why: the workers already
provide the context isolation, and a handoff forces a copied prompt and a new
gate confirmation.

The tickets are a task graph with blocking relationships, not a list of steps.
There is a frontier of tickets that are ready to be grabbed, unless every ticket
is blocked.

Communication to and from workers is sparse. Communicate through context
pointers: the spec, the ticket, research notes, and previous commits. Never
duplicate what a pointer already carries. Why: a copy drifts from the source, and
the worker cannot tell which copy is current.

Workers run in the background where the harness allows it, each in its own
checkout. Why: parallel work finishes sooner, and isolated checkouts keep one
ticket's edits out of another.

## Gate check

Before the first edit, read the mission document and the gate decision. If the
scope and spec gate or the ticket gate is pending, stop and ask. A feature has
both gates; a draft spec or a proposed ticket graph is not an approval. On a fog
path, the decision gates must also be approved. Why: the feature path multiplies
one unapproved decision across every ticket.

## Steps

1. Read the spec, the tickets, and the mission document. Read the concurrency cap
   from the mission document. `mission` defines the cap; the Decisions may set a
   different value. Note the PR model: a per-ticket stack by default, one
   integration PR only when the owner asked for it and the record notes it. Why:
   the next session reads the record, not this message.

2. Optionally use an exploration subagent to gather what the tickets need:
   relevant codebase files or external documentation. The exploration notes go
   outside the repo, where every worker can read them. Why: the workers stay on
   implementation, and one set of notes is cheaper than the same search in every
   worker.

3. Claim the frontier. For each ready ticket, assign it to yourself in the
   tracker before spawning its worker. An open, unassigned ticket is available
   to another session. Release a claim if a worker fails before it opens a PR.
   Why: the assignee is the reservation, and a claimed ticket with no worker
   blocks the frontier.

4. Create the stack bases. For a ticket with no blockers, branch from the current
   base (`main`, or the merge commit the mission names). For a ticket with one
   unmerged blocker, branch from the blocker's branch. For a ticket with several
   blockers, wait for all but one to merge, then branch from the last. If the
   owner asked for one integration PR, create the integration branch and branch
   every worker from it. Why: the PR base is the layer below, and a ticket with
   several PR bases is not reviewable.

5. Spawn one worker per frontier ticket, up to the cap. Each worker:
   - confirms its checkout is based on its stack base before starting;
   - gets only its ticket body, the spec section it needs, and the context
     pointers, not the whole graph;
   - calls the Skill tool with `tdd` when the ticket has a code seam;
   - commits to its layer and rebases onto its base before reporting done;
   - opens one PR against its base, with `Closes <ticket>`.
   A worker with no code seam runs the check the ticket names, or reports that it
   names none. A worker that cannot open a PR reports the branch and the blocker.
   Why: a silent failure leaves the frontier stalled.

6. Review each PR as it opens. Call the Skill tool with `code-review` on the PR,
   using the ticket as the spec source and the PR's base as the fixed point. Fix
   the findings in the worker or a fix worker. Run the reviews for a wave
   together when the harness supports concurrent subagents; otherwise run them
   one at a time and say so. Never nest a review inside a worker that is still
   implementing. Why: the crew chief owns the review, and a worker reviewing its
   own diff is not an independent check.

7. Clean up the worker worktrees after the branches are pushed and the PRs are
   open. Keep the branches until the owner merges. Why: deleting a base branch
   closes its stacked PRs.

8. Report the stack bottom-up. For each PR: URL, base, check state, what changed,
   what it unlocks, and the merge danger. Name the merge order and the next
   frontier in plain words. Stop. The owner merges bottom-up.

## After the merge

After a merge, retarget the next layer to `main` and rebase it on the merge
commit. Continue in the current session when the context holds. Run
`/mission continue` when a merge unblocks a new frontier. If the owner asks the
crew chief to merge, use a merge commit.

When every ticket is merged, close the spec with a comment that points at the
stack. Why: the spec is the parent issue, and the stack's PRs close the tickets,
not the spec.

## Integration branch

When the owner asks for one integration PR, the crew chief merges each worker's
branch into the integration branch with a merger subagent, runs `code-review` on
the integration branch, opens one PR, and reports it. The review uses the spec as
the spec source and the integration branch's base as the fixed point. The owner
merges the one PR.

## The frontier is dynamic

A ticket enters the frontier when its blockers' branches have the interface it
needs, not only when the blockers' PRs merge. A merge can unblock several tickets
at once; start them together, up to the cap. If the frontier has one ticket, use
`implement`. If the harness cannot isolate checkouts, run the tickets one at a
time and say so.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
