---
name: to-tickets
description: Break a plan, spec, or the current conversation into a set of tracer-bullet tickets, each declaring its blocking edges, published to the configured tracker (edges as text in one file per ticket locally, or native blocking links on a real tracker).
disable-model-invocation: true
---

# To Tickets

Break a plan, spec, or conversation into a set of **tickets**: tracer-bullet vertical slices, each declaring the surface it **owns** and the tickets that **block** it.

The issue tracker and triage label vocabulary should have been provided to you. If not, ask the owner for the tracker.

## Gate check

This skill runs on a spec. Inside a mission, it runs only on the feature or fog
path, after the scope and spec gate is approved. Read the mission document and
the gate decision. If the scope and spec gate is pending, stop and ask. On a fog
path, the decision gates must also be approved. Standalone, the owner's request
to cut the tickets is the approval; the published spec is the source. A ticket
graph cut from an unapproved spec multiplies the unapproved decision. For a
change, bug, or trivial, this skill is not used; the issue is the work item, not
a ticket graph. Why: the prior newsletter thread asked the owner to approve a
ticket on a bug, and the bug path has no ticket gate.

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the owner passes a reference (a spec path, an issue number or URL) as an argument, fetch it and read its full body and comments.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Ticket titles and descriptions should use the project's domain glossary vocabulary, and respect ADRs in the area you're touching.

Look for opportunities to prefactor the code to make the implementation easier. "Make the change easy, then make the easy change."

### 3. Draft vertical slices

Break the work into **tracer bullet** tickets.

<vertical-slice-rules>

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests): vertical, NOT a horizontal slice of one layer. Why: a horizontal slice lands no user-visible behavior, so the owner cannot verify it.
- A completed slice is demoable or verifiable on its own. Why: a slice the owner cannot see is a slice the owner cannot approve.
- Each slice is sized to fit in a single fresh context window. Why: a ticket that does not fit a session forces a handoff in the middle of the build.
- Each slice names the surface it owns: the module, route, schema, or command it changes. Two ready tickets that own the same surface get a blocking edge and stack; the one that lands the surface first blocks the other. Why: parallel branches that edit one surface conflict, and a stack keeps the second change reviewable as a layer.
- Any prefactoring should be done first. Why: a prefactor mixed into a slice hides the behavior change.

</vertical-slice-rules>

Give each ticket its **blocking edges**: the other tickets that must complete before it can start. A ticket with no blockers can start immediately. A ticket with one blocker stacks on the blocker's branch; a ticket with several blockers waits for all but one to merge, then stacks on the last. The stack order is the merge order. Why: a missing edge starts a ticket before its prerequisite, and an invented edge keeps a ready ticket off the frontier. A stack lets dependent work start before the blocker merges without a PR with several bases.

**Wide refactors are the exception to vertical slicing.** A **wide refactor** is one mechanical change (rename a column, retype a shared symbol) whose **blast radius** fans across the whole codebase, so a single edit breaks thousands of call sites at once and no vertical slice can land green. Don't force it into a tracer bullet; sequence it as **expand, then contract**. First expand: add the new form beside the old so nothing breaks. Then migrate the call sites over in batches sized by blast radius (per package, per directory), each batch its own ticket blocked by the expand, keeping CI green batch to batch because the old form still exists. Finally contract: delete the old form once no caller remains, in a ticket blocked by every migrate batch. When even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify ticket; green is promised only there.

### 4. Quiz the owner

Present the proposed breakdown as a numbered list. For each ticket, show:

- **Title**: short descriptive name
- **Blocked by**: which other tickets (if any) must complete first
- **What it delivers**: the end-to-end behaviour this ticket makes work

Ask the owner:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct: does each ticket only depend on tickets that genuinely gate it?
- Should any tickets be merged or split further?
- Does the stack order match the merge order, and are the surfaces disjoint for the tickets that run together?

Iterate until the ticket graph is approved. Record the decision and date in the
mission document's Tickets gate. Never reproduce the words, mention the user, or
name who decided. Keep no history of the rounds. Why: the ticket graph is the
gate document; a summary written by the agent is a log, not the approval.

### 5. Publish the tickets to the configured tracker

Publish the approved tickets. **How** depends on the tracker the owner configured; the tickets are the same either way, only the shape of the blocking edges changes:

- **Local files** → write one file per ticket under `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01` in dependency order (blockers first). Each file's "Blocked by" lists the numbers/titles it depends on. Use the per-ticket file template below: one ticket per file, never a single combined file.
- **A real issue tracker (GitHub, Linear, …)** → publish one issue per ticket in dependency order (blockers first) so each ticket's blocking edges can reference real identifiers. Use the platform's native blocking relationship where it has one; otherwise set each ticket's "Blocked by" to the blocking issues. If the source was an existing issue, make each ticket its sub-issue (tracker doc's operation). Apply the `ready-for-agent` triage label unless instructed otherwise; the tickets are agent-grabbable by construction. Record the surface and the stack order in the ticket body. The native blocking edges carry the graph; the stack order is the order the owner merges.

Work the **frontier**: any ticket whose blockers are done. Use the stack rule above for a blocker that is not merged. For a purely linear chain that means top to bottom.

Do NOT close or modify any parent issue.

<local-ticket-template>

# <NN>: <Ticket title>

**What to build:** the end-to-end behaviour this ticket makes work, from the user's perspective, not a layer-by-layer implementation list.

**Surface owned:** the module, route, schema, or command this ticket changes. Two ready tickets that share a surface are stacked, not run side by side.

**Blocked by:** the numbers/titles of the tickets that gate this one, or "None (can start immediately)".

**Status:** ready-for-agent

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2

</local-ticket-template>

<issue-template>

## Parent

A reference to the parent issue on the tracker (if the source was an existing issue, otherwise omit this section).

## What to build

The end-to-end behaviour this ticket makes work, from the user's perspective, not layer-by-layer implementation.

## Surface owned

The module, route, schema, or command this ticket changes. Two ready tickets that share a surface are stacked, not run side by side.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

- A reference to each blocking ticket, or "None (can start immediately)". Omit this section when blockers were set as native edges.

</issue-template>

In either form, avoid specific file paths or code snippets: they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it and note briefly that it came from a prototype. Trim to the decision-rich parts, not a working demo, just the important bits.

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
