---
name: router
description: Ask which skill or flow fits your situation, check state when asked what's next, and return the next step. A router over the skills in this repo and the classifier behind mission.
disable-model-invocation: true
---

# Router

You don't remember every skill, so route.

Before performing a skill, stating what it does, or recommending a step be skipped, load it with the Skill tool: the summaries here are for orientation only. If a named skill will not load, stop and say which one failed; do not simulate its output.

`mission` drives the main flow as one entry. This router is the classifier it calls, and it also works on its own when you only want the next step.

## Answer shape

End every routing reply with a **Next step** line that names the exact skill or
command, the ticket or document, and what it produces.

The next step is the action that unblocks the work now, not the phase after it.
For a pending gate or an open blocking PR, use this table:

| Situation | Next step |
| --- | --- |
| A gate is pending | the user approves the named document |
| A blocking PR is a draft | the next step is to make it ready for review |
| A blocking PR has failing checks | the next step is the fix |
| A blocking PR is open and not mergeable | the next step is to make it mergeable |
| A blocking PR is green and mergeable | the user merges it |
| A blocking PR is closed unmerged | the user decides |

A pending gate or an open blocking PR outranks a ready ticket. The next ticket
waits. These are the standalone answers. If an active mission document exists,
the next step is `/mission continue`; the mission owns the phase and handoff
decision.

Next step: `/handoff` for ticket 123. It produces the prompt for a fresh session that runs `/implement` and `/code-review` to a reviewable PR.
Next step: `/code-review` the open PR. It produces findings to fix before the user merges.

When the next step is `/handoff`, the prompt is the deliverable: one fenced
`text` block in chat that the user can copy with one click. Never put the
delivered prompt in an issue, a PR, a commit, the repo, or the mission document.

## When asked what's next

"What's next", "what now", and "continue" are state questions, not
classification questions. Read the state in this order before you name a step.
The same check applies before you recommend any phase that starts new work.

1. **Check for a mission.** If an active mission document exists, the next step
   is `/mission continue`; the mission owns the phase, gate, and handoff
   decision. Stop here. The rest of this procedure is the standalone path.
2. **Read the standalone state.** Read the ticket graph, the current branch, and
   the latest PR. Use the configured tracker, not memory.
3. **Check the blocking PRs.** Resolve each blocking ticket to its PR and read
   its state, merge commit, checks, mergeability, and head SHA. On GitHub, use
   `gh pr view <n> --json state,isDraft,mergeable,mergeStateStatus,statusCheckRollup,mergeCommit,headRefOid`;
   on GitLab, use `glab mr view <n>` and read the draft, pipeline, and merge
   status. A blocking ticket with no PR is done only when the tracker marks it
   completed; a cancelled or duplicate ticket does not satisfy the gate. A
   ticket does not hand over to the next ticket until its blocking PRs are
   merged, unless the user explicitly asks for a stacked PR. If any blocking
   PR is open, the next step is that PR, not the next ticket: report each open
   PR's URL, head SHA, and check state, and say they must merge before the next
   ticket starts. Use the table above for the branch. After a merge, confirm the
   ticket is done, fetch `origin`, and branch from the merge commit.
4. **Choose the session.** Continue here when the next step stays inside the
   current ticket or session: a review, a fix, the PR, a pending gate. Hand off
   when the next step starts a new ticket, a fresh worktree or directory, a new
   harness, or a side task, or when the context is full. In a multi-ticket
   effort, each ticket starts in a fresh session.
5. **Answer once.** Name the gate or PR that decides the step, then one Next
   step line. Name a skill to load, not a phase to perform. If the choice is
   handoff, name `/handoff`, not the phase it will run, and produce the prompt
   with `handoff`; the prompt is the deliverable, and it goes in chat.

## The main flow: idea to reviewable PR

`mission` drives this flow. The phases below are the underlying map.

1. **The grill.** Load `grilling`, and `domain-modeling` when the repo has docs, with the Skill tool. They build shared understanding. With no working directory, use `grill-me`. `/grill-with-docs` is the standalone command for the same composition in a repo.
2. **The plan.** Use `to-spec` to record the agreed spec and `to-tickets` to cut it into tickets with blocking edges. `wayfinder` charts a foggy, multi-session effort as decision tickets first. `research` supplies facts and `prototype` answers a question that needs runnable code.
3. **The build.** `implement` builds one ticket and drives `tdd` at the agreed seams; `implement-spec` works the whole ticket graph. Both close with `code-review`. `pr` shapes the body. The user reviews and merges.

A single-session change skips the spec and tickets and goes from the grill to `implement`. A bug goes through `diagnosing-bugs` and a short grill before the issue and the PR.

## On-ramps

- **Incoming requests and bugs** -> `triage`. It verifies the claim, grills if needed, and writes an agent-ready issue.
- **Something broken** -> `diagnosing-bugs`. It builds a tight feedback loop before it theorises.
- **A huge, foggy effort** -> `wayfinder`. It charts a map of decision tickets and hands the clear path back to the flow.

## Design vocabulary

- `domain-modeling` sharpens the project's language and writes `GLOSSARY.md` and ADRs.
- `codebase-design` is the deep-module vocabulary for specs, tickets, and implementation seams.

## Standalone

- `grill-me` is the stateless grill for a plan or design with no repo.
- `grilling` is the interview primitive underneath every grill.
- `prototype` answers a design question with throwaway code.
- `research` investigates a question against primary sources and leaves a cited markdown file.
- `handoff` writes the handoff document and gives you the next-session prompt in chat.

## Phase boundary

At a boundary, the options are continue, clear, handoff, subagent, and compact. Continue only when the next step stays inside the current ticket or session. Hand off when the work travels to a new session, a new directory, a new harness, or another agent. `mission` plans the handoff points and produces the prompt in chat. Outside a mission, `handoff` produces it.

## Ticket handback

A ticket ends with a reviewable PR. The implementer opens one PR, runs
`code-review`, fixes the findings, and reports the PR URL, head SHA, checks,
and the next ready ticket. The user reviews and merges. The next ticket starts
only after that merge, unless the user explicitly asks for a stacked PR. When
the user asks the agent to merge, use a merge commit.

## Context hygiene

Keep the grill, spec, and tickets in one unbroken context window so they build
on the same thinking. Each implementation then starts fresh from the ticket.
