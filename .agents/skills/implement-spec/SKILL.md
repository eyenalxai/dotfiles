---
name: implement-spec
description: "Implement a frontier of two or more tickets as a stack of per-ticket PRs, or one integration PR when the owner asks."
disable-model-invocation: true
---

# Implement spec

Run a frontier of 2+ ready tickets as **crew chief**: claim ready tickets, spawn one isolated worker subagent per ticket, review each PR, and report the stack bottom-up for the owner to merge. A 1-ticket frontier routes to `implement`.

The mission session loads this skill and acts as crew chief. Never hand off for a phase change; workers already isolate ticket contexts. If the harness cannot isolate checkouts, run tickets sequentially in one checkout and say so; parallel edits in one directory conflict.

## Gate check

Read the mission document first. Both the **scope and spec gate** and the **tickets gate** must be approved (plus **decision gates** on a Fog path). If any gate is pending, stop and ask. Building a graph on an unapproved decision multiplies the mistake across every ticket.

## Steps

1. **Load the graph.** Read the spec, tickets, mission record, concurrency cap (default 10 unless Decisions overrides it), and PR model (stacked per-ticket PRs by default; one integration PR only if recorded in Decisions).
2. **Optional shared exploration.** If several tickets touch unfamiliar areas, run one exploration subagent to write shared notes outside the repo (e.g., OS temp dir). One pass is cheaper than repeating the same search in every worker.
3. **Claim the frontier.** Assign every ready ticket to yourself in the tracker before spawning workers so another session does not grab it. Release the claim if a worker fails before opening a PR.
4. **Prepare stack bases.**
   - No blockers: branch from `main` (or the mission's named base commit).
   - One unmerged blocker: branch from the blocker's branch once that branch exposes the needed interface (you do not need to wait for the blocker's PR to merge).
   - Multiple blockers: wait until all but one merge, then branch from the last.
   - Integration-PR mode: create the integration branch and branch every worker from it.
5. **Spawn one worker per frontier ticket** (up to the cap), each in its own worktree/checkout. Give sparse pointers only (its ticket, the relevant spec section, shared notes, base branch; never copy-paste specs that can drift). Each worker must:
   - confirm its checkout is based on its stack base;
   - load `tdd` via the Skill tool when the ticket has a code seam (otherwise run the ticket's named check, or report none);
   - commit to its layer, rebase onto its stack base, and open one PR against that base with `Closes <ticket>` (or report the branch and blocker if it cannot open a PR; never fail silently).
6. **Review each PR.** Load `code-review` against each layer's base branch with the ticket as spec source. Run wave reviews concurrently when supported. Never ask a worker still implementing to review its own diff. Fix the findings and shape each PR body with `pr`.
7. **Clean up worktrees.** Remove worker worktrees once branches are pushed and PRs are open, but **keep all branches** until merged (deleting a base branch closes stacked PRs above it).
8. **Report bottom-up and stop.** List each PR in merge order: URL, base, check state, what changed, what it unlocks, and merge danger. Name the next frontier in plain words (keep head SHAs in the PR). Wait for the owner to merge bottom-up.

## Integration PR mode

When the owner requested one integration PR: merge each worker branch into the integration branch (using a merger subagent if needed), run `code-review` against the integration base using the full spec as spec source, shape the single PR body with `pr`, and report it.

## After a merge

Retarget the next layer's PR to `main`, fetch `origin`, and rebase it on the merge commit. If the merge unblocks new tickets, start them up to the cap (stay in this session if context holds; otherwise hand off). If asked to merge, use a merge commit.

Once every ticket is merged, close the parent spec issue with a neutral comment linking the merged PRs (ticket PRs close tickets, not the spec).

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
