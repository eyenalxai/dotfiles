---
name: implement
description: "Implement a piece of work based on a spec, ticket, or approved rule changes."
disable-model-invocation: true
---

# Implement

Build one approved ticket or change and deliver one reviewable PR. A frontier of 2+ ready tickets routes to `implement-spec` so the crew chief owns the graph and stack.

## Roles: orchestrator and worker

- **Orchestrator (`opencode-go/kimi-k3.1-pro`)**: checks the gate, writes the worker brief, critiques the worker's output at the forest level (seam, interface, scope, architecture), runs `code-review`, writes the PR body via `pr`, and reports to the owner. Never writes production code or iterates test/build loops in the main session.
- **Worker (`openrouter/deepseek/deepseek-v4.1-flash-1017#max`, `general` subagent)**: does all implementation work in a single worker session. Reads the codebase, loads `tdd` when a code seam exists, edits files, runs repo checks, commits to the branch, and returns a compact report.
- **Critique loop**: read the worker's summary and selectively inspect public interface diffs. If the design, seam, or scope is off, send concrete redirection to the **same worker `sessionID`** and have it revise and re-verify before moving to review.

## 1. Check the gate before the first edit

Read the mission document and gate decisions. If a ticket reference was passed, fetch it and refer to it by title in replies (never by bare id).

```text
Is every authorizing gate approved (plus Fog decision gates if Fog)?
├── No  → Stop and ask at the gate. Never make "just a small edit" or treat a draft/proposal as approval.
└── Yes
    ├── Does the edit stay inside the approved rule changes and file pattern?
    │   ├── No  → Stop and reopen the gate. Never widen scope silently.
    │   └── Yes → Proceed to dispatch.
```

Never add an unapproved file, skill, script, or test harness. Unasked work looks like progress while bypassing the owner's decision.

## 2. Branch and stack base

One ticket, one PR.

- **No blockers:** branch from `main` (or the mission's named base commit).
- **One unmerged blocker:** branch from the blocker's branch and set that branch as the PR base, so the PR shows only this layer's diff.
- **Multiple blockers:** wait until all but one merge, then stack on the last.

## 3. Dispatch the worker

Spawn one `general` worker (`openrouter/deepseek/deepseek-v4.1-flash-1017#max`) with a lean brief built from pointers (never duplicate the whole spec or ticket when a path or URL exists):

- Approved rule changes, file scope, and approved seams.
- Pointer to the ticket/issue, spec section, glossary, relevant ADRs, and branch/base.
- Instruction to load `tdd` via the Skill tool when the work has a code seam. (Prose/markdown changes have no code seam; skip `tdd` and never invent a test harness.)
- Exact repo build/test commands (if none exist, note that; never invent one).
- Required return format (under 400 words): changed files, public interface or behavior summary, exact commands run with pass/fail output, any blockers or open decisions, and commit SHA.

If the worker hits a missing decision, it stops and reports back instead of guessing; the orchestrator asks the owner.

## 4. Critique, review, and PR

1. **Forest check (orchestrator).** Read the worker's report. Check public interface changes and any risky hunks directly if needed. If the implementation chose a leaky seam, drifted from scope, or over-engineered, send a follow-up to the **same worker `sessionID`** explaining what to change. Repeat until the shape is right.
2. **Code review.** Load `code-review` (which runs Standards and Spec passes on DeepSeek workers, then your forest check). Send real findings back to the implementation worker's `sessionID` to fix and re-test.
3. **Shape and open the PR.** Load `pr` and write the PR body yourself (owner-facing). Have the worker push the branch and open the PR against its stack base (with `Closes <ticket>`), or open it directly.

## 5. Handback

Put the answer first in plain words (no status block, no bare tracking keys). Report the PR URL, check state, what changed, what it unlocks, and merge danger. Keep head SHAs in the PR.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
