---
name: router
description: Name the skill or flow that fits, check state when asked what's next, and return the next step. Use standalone, or inside a mission when the mission needs the next step.
disable-model-invocation: true
---

# Router

Pick the right skill for a request, or inspect live repo/tracker state when asked "what's next", and return one concrete next action.

Before describing what a skill does, performing it, or recommending skipping it, load it with the Skill tool. If a named skill fails to load, stop and name it; never simulate its output.

## State read order

"What's next", "what now", and "continue" are state checks, not scope guesses. Walk these steps in order:

1. **Check for an active mission.** If this conversation is in a mission or an active mission document exists, `mission` owns the phase, gate, and handoff decision. Read the record and return its next action. Remember: a mission can be active before its record exists, and a record never grants a gate (only the owner's words in conversation do). Stop here if a mission is active.
2. **Read standalone state.** Query the configured tracker (never memory), current git branch, and every frontier ticket's PR:
   - GitHub: `gh pr view <n> --json state,isDraft,baseRefName,mergeable,mergeStateStatus,statusCheckRollup,mergeCommit,headRefOid`
   - GitLab: `glab mr view <n>` (draft, pipeline, base, merge status)
   - A ticket without a PR is done only if marked completed; canceled or duplicate tickets do not satisfy blocking edges.
3. **Decide the next step.** A pending gate or open stack outranks the next frontier. Match the first row that applies:

| Condition | Next step |
| --- | --- |
| A gate is pending | Owner approves the named document |
| A blocking PR is a draft | Mark it ready for review |
| A blocking PR has failing checks | Fix the checks |
| A blocking PR is open and unmergeable | Rebase or resolve conflicts |
| A blocking PR is green and mergeable | Owner merges it (bottom-up for stacks) |
| A blocking PR is closed unmerged | Owner decides how to proceed |
| A stack's bottom PR just merged | Retarget next layer to `main`, fetch `origin`, rebase on the merge commit |
| A frontier is unblocked | Load `implement` (1 ticket) or `implement-spec` (2+ tickets) |

Stacking rule: a dependent ticket can stack on its single blocker's branch once that branch exposes the needed interface; a ticket with multiple blockers waits for all but one to merge, then stacks on the last.

4. **Check session fit.** Stay in the current session for reviews, fixes, PRs, gates, and builds (`implement-spec` workers already isolate parallel tickets). Recommend `/handoff` only when work moves to another directory/harness, needs a side context, or context is nearly full; when choosing handoff, load `handoff` and deliver the prompt in chat.

## Answer format

- Put the decision first in plain words. Never print bare tracking keys or head SHAs in replies (head SHAs stay in the PR).
- For open PRs or stacks, list each PR bottom-up with URL, base, check state, what changed, what it unlocks, and merge danger.
- End with one plain sentence when the owner must act:
  `Next step: <exact skill or action> on <plain work name>, because <reason>; this unlocks <outcome>.`

## Context hygiene

Keep grilling, specs, tickets, wayfinder decisions, and the mission record in one unbroken context so they share the same mental model. Each `implement-spec` worker starts fresh from its ticket while the crew chief holds the graph.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
