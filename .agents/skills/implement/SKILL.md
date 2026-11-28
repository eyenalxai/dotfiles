---
name: implement
description: "Implement a piece of work based on a spec, ticket, or approved rule changes."
disable-model-invocation: true
---

# Implement

Build one approved ticket or change and deliver one reviewable PR. A frontier of 2+ ready tickets routes to `implement-spec` so the crew chief owns the graph and stack.

If the owner passes a ticket reference, fetch it from the tracker and refer to it by title in replies (never by bare id). If the reference is ambiguous, ask.

## 1. Check the gate before the first edit

Read the mission document and gate decisions.

```text
Is every authorizing gate approved (plus Fog decision gates if Fog)?
├── No  → Stop and ask at the gate. Never make "just a small edit" or treat a draft/proposal as approval.
└── Yes
    ├── Does the edit stay inside the approved rule changes and file pattern?
    │   ├── No  → Stop and reopen the gate. Never widen scope silently.
    │   └── Yes → Proceed.
```

Never add an unapproved file, skill, script, or test harness. Unasked work looks like progress while bypassing the owner's decision.

## 2. Branch and stack base

One ticket, one PR.

- **No blockers:** branch from `main` (or the mission's named base commit).
- **One unmerged blocker:** branch from the blocker's branch and set that branch as the PR base, so the PR shows only this layer's diff.
- **Multiple blockers:** wait until all but one merge, then stack on the last.

## 3. Build and verify

- **Seams and tests:** load `tdd` via the Skill tool when the work has a code seam, and test only at the seams approved in the spec, ticket, or gate. Prose or markdown changes have no code seam; skip `tdd`, never invent a test harness, and verify against the repo's writing standard instead.
- **Repo commands:** run the build and check commands the repo documents. If none exist, say so in the PR; never invent one.
- **New decisions:** if building reveals a missing decision, stop and ask the owner instead of guessing.
- **Review and PR:** once built, load `code-review` and fix the findings, then load `pr` to shape the PR body. Commit to the current branch and open one PR against its stack base (with `Closes <ticket>`).

## 4. Handback

Put the answer first in plain words (no status block, no bare tracking keys). Report the PR URL, check state, what changed, what it unlocks, and merge danger. Keep head SHAs in the PR. The owner reviews and merges bottom-up.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
