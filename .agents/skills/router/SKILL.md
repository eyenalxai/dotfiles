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

When the owner must act, end with one plain sentence: `Next step: <the action>`.
Name the exact skill or command, the work or document, why it is next, and what
it unlocks. Name the work in plain words, never by a ticket id or issue key.

Inside a mission, even before its record exists, the mission output contract
owns the reply: answer first, no status block, and one plain Next step sentence
when the owner must act. The mission document holds the state once it exists;
before the gate, the conversation holds it. Standalone, the Next step line
carries the why and the unlock.

The next step is the action that unblocks the work now, not the phase after it.
For a pending gate or an open PR in a stack, use this table:

| Situation | Next step |
| --- | --- |
| A gate is pending | the owner approves the named document |
| A blocking PR is a draft | the next step is to make it ready for review |
| A blocking PR has failing checks | the next step is the fix |
| A blocking PR is open and not mergeable | the next step is to make it mergeable |
| A blocking PR is green and mergeable | the owner merges it |
| A blocking PR is closed unmerged | the owner decides |
| A stack has an unmerged bottom PR | the owner merges the bottom, then the next layer |

A pending gate or an open stack outranks the next frontier. The next frontier
waits until merges unblock it. These are the standalone answers. If an active
mission document exists, the next step is `/mission continue`; the mission owns
the phase and handoff decision.

Next step: `/handoff` for the dependency bump, because its blockers are merged and it unblocks the release note.
Next step: `/code-review` the open PR, because its checks are green and it is the last gate before your merge.

When the next step is `/handoff`, the prompt is the deliverable: one fenced
`text` block in chat that the owner can copy with one click. Never put the
delivered prompt in an issue, a PR, a commit, the repo, or the mission document.

## When asked what's next

"What's next", "what now", and "continue" are state questions, not
classification questions. Read the state in this order before you name a step.
The same check applies before you recommend any phase that starts new work.

1. **Check for a mission.** If the conversation is in a mission, or an active
   mission document exists, the next step is `/mission continue`; the mission
   owns the phase, gate, and handoff decision. A mission can be active before
   its record exists, and the record is not authority. The gate is the owner's
   words in the conversation; do not infer it from a record. Stop here. The rest
   of this procedure is the standalone path.
2. **Read the standalone state.** Read the ticket graph, the current branch, and
   the latest PR. Use the configured tracker, not memory.
3. **Check the stack.** Resolve each ticket in the frontier to its PR and read
   its state, base branch, checks, mergeability, and head SHA. On GitHub, use
   `gh pr view <n> --json state,isDraft,baseRefName,mergeable,mergeStateStatus,statusCheckRollup,mergeCommit,headRefOid`;
   on GitLab, use `glab mr view <n>` and read the draft, pipeline, base, and
   merge status. A ticket with no PR is done only when the tracker marks it
   completed; a cancelled or duplicate ticket does not satisfy the graph.
   A dependent ticket stacks on its blocker's branch, so it may be built before
   the blocker merges. A ticket with several blockers waits for all but one to
   merge, then stacks on the last. The next step is the bottom unmerged PR, not
   the next layer. Report each open PR's URL, base, check state, what changed,
   what it unlocks, and the merge danger. The owner merges bottom-up. The head
   SHA stays in the PR. After a merge, retarget the next layer to `main`,
   confirm the ticket is done, fetch `origin`, and rebase the next layer on the
   merge commit. A ticket that cannot stack waits for all its blockers' PRs to
   merge.
4. **Choose the session.** Continue here when the next step stays inside the
   current frontier or session: a review, a fix, the PR, a pending gate, or the
   build through `implement` or `implement-spec`. Hand off when the next step
   needs a different context: a fresh worktree or directory, a new harness, a
   side task, or a context that is full. A new frontier in the same context stays
   in the session. Each worker gets its own subagent context.
5. **Answer once.** Name the gate or PR that decides the step, then one Next
   step line with the why and the unlock. Name a skill to load, not a phase to
   perform. If the choice is handoff, name `/handoff`, not the phase it will
   run, and produce the prompt with `handoff`; the prompt is the deliverable,
   and it goes in chat.

## The main flow: idea to reviewable PR

`mission` drives this flow. The phases below are the underlying map.

1. **The grill and the survey.** Load `grilling`, and `domain-modeling` when the repo has docs, with the Skill tool. They build shared understanding. For a full architecture pass, `improve-codebase-architecture` surveys state machines, invariants, and deepening candidates before the grill. With no working directory, use `grill-me`. `/grill-with-docs` is the standalone command for the same composition in a repo.
2. **The plan.** Draft the spec with `to-spec` and approve it with the scope at one gate. Then use `to-tickets` to cut it into tickets with blocking edges, and approve the ticket graph. `wayfinder` charts a foggy, multi-session effort as decision tickets first. `research` supplies facts and `prototype` answers a question that needs runnable code.
3. **The build.** `implement` builds one ticket and drives `tdd` at the agreed seams; `implement-spec` is the crew chief for the frontier: it claims the ready tickets, runs one worker per ticket in its own worktree, and opens one PR per ticket, stacked by edge. The mission session is the crew chief; a handoff is not needed to start the build. Both close with `code-review`. `pr` shapes the body. The owner reviews and merges bottom-up.

A single-session change skips the spec and tickets and goes from the grill to `implement`. A bug goes through `diagnosing-bugs` and a short grill before the issue and the PR.

## On-ramps

- **Incoming requests and bugs** -> `triage`. It verifies the claim, grills if needed, and writes an agent-ready issue.
- **Something broken** -> `diagnosing-bugs`. It builds a tight feedback loop before it theorises.
- **A full architecture pass** -> `improve-codebase-architecture`. It surveys implicit state machines, unenforced invariants, and deepening candidates, then either grills the chosen candidate or hands the candidate index to the mission.
- **A huge, foggy effort** -> `wayfinder`. It charts a map of decision tickets and hands the clear path back to the flow.

## Design vocabulary

- `domain-modeling` sharpens the project's language and writes `GLOSSARY.md` and ADRs.
- `codebase-design` is the deep-module vocabulary for specs, tickets, and implementation seams.
- `improve-codebase-architecture` applies that vocabulary in a read-only survey and returns state, invariant, and deepening candidates.

## Standalone

- `grill-me` is the stateless grill for a plan or design with no repo.
- `grilling` is the interview primitive underneath every grill.
- `improve-codebase-architecture` surveys a codebase and grills the chosen candidate when used alone.
- `prototype` answers a design question with throwaway code.
- `research` investigates a question against primary sources and leaves a cited markdown file.
- `to-questionnaire` turns a decision someone else holds into a questionnaire.
- `handoff` writes the handoff document and gives you the next-session prompt in chat.

## Phase boundary

At a boundary, the options are continue, clear, handoff, subagent, and compact. Continue when the next step stays inside the current frontier or session. Use a subagent when the work is parallel or isolated but stays in the session. Hand off when the work travels to a new session, a directory, a harness, or another agent, or when the context is full. A phase change alone is not a handoff. `mission` plans the handoff points and produces the prompt in chat. Outside a mission, `handoff` produces it.

## Ticket handback

A ticket ends with a reviewable PR. In a frontier, the crew chief opens one PR
per ticket, stacked by blocking edge, runs `code-review` on each, and fixes the
findings. It reports the stack bottom-up: each PR URL, check state, what
changed, what it unlocks, and the merge danger. The head SHA stays in the PR.
The reply names the next frontier in plain words. The owner merges bottom-up. A
dependent ticket starts when its blocker's branch has the interface it needs,
not when the blocker's PR merges. When the owner asks the agent to merge, use a
merge commit.

## Context hygiene

Keep the grill, spec, tickets, wayfinder decisions, and the mission record in
one unbroken context window so they build on the same thinking. Each worker then
starts fresh from its ticket; the crew chief keeps the graph.

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
