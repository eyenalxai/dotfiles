---
name: to-tickets
description: Break a plan, spec, or the current conversation into tracer-bullet tickets, each declaring its blocking edges, and publish them to the configured tracker.
disable-model-invocation: true
---

# To tickets

Break a plan, spec, or conversation into a set of tickets: tracer-bullet vertical
slices, each declaring the surface it owns and the tickets that block it.

The issue tracker and triage label vocabulary come from the repo's agent docs. If
they are missing, ask the owner for the tracker.

## Gate check

This skill runs on a spec. Inside a mission, it runs only on the feature or fog
path, after the scope and spec gate is approved. Read the mission document and
the gate decision. If the scope and spec gate is pending, stop and ask. On a fog
path, the decision gates must also be approved. Standalone, the owner's request
to cut the tickets is the approval; the published spec is the source. Never cut a
ticket graph from an unapproved spec. Why: the graph multiplies the unapproved
decision. A change, bug, or trivial never uses this skill; the issue is the work
item, not a ticket graph.

## Process

### 1. Gather context

Work from what is already in the conversation context. When the owner passes a
reference (a spec path, an issue number or URL), fetch it and read its full body
and comments.

### 2. Explore the codebase

If the codebase is not already explored, explore it to understand the current
state of the code. Use the project's domain glossary vocabulary in ticket titles
and descriptions, and respect ADRs in the area you touch.

Look for opportunities to prefactor the code to make the implementation easier.
Make the change easy, then make the easy change.

### 3. Draft vertical slices

Break the work into tracer-bullet tickets.

### Vertical slice rules

- Each slice cuts a narrow but complete path through every layer (schema, API,
  UI, tests): vertical, never a horizontal slice of one layer. Why: a horizontal
  slice lands no user-visible behavior, so the owner cannot verify it.
- A completed slice is demoable or verifiable on its own. Why: a slice the owner
  cannot see is a slice the owner cannot approve.
- Each slice fits in a single fresh context window. Why: a ticket that does not
  fit a session forces a handoff in the middle of the build.
- Each slice names the surface it owns: the module, route, schema, or command it
  changes. Two ready tickets that own the same surface get a blocking edge and
  stack; the one that lands the surface first blocks the other. Why: parallel
  branches that edit one surface conflict, and a stack keeps the second change
  reviewable as a layer.
- Do prefactoring first. Why: a prefactor mixed into a slice hides the behavior
  change.

Give each ticket its blocking edges: the other tickets that must complete before
it can start. A ticket with no blockers can start immediately. A ticket with one
blocker stacks on the blocker's branch; a ticket with several blockers waits for
all but one to merge, then stacks on the last. The stack order is the merge
order. Why: a missing edge starts a ticket before its prerequisite, and an
invented edge keeps a ready ticket off the frontier. A stack lets dependent work
start before the blocker merges without a PR with several bases.

**Wide refactors are the exception to vertical slicing.** A wide refactor is one
mechanical change (rename a column, retype a shared symbol) whose blast radius
fans across the codebase, so a single edit breaks thousands of call sites at once
and no vertical slice can land green. Never force it into a tracer bullet;
sequence it as expand, then contract. First expand: add the new form beside the
old so nothing breaks. Then migrate the call sites over in batches sized by blast
radius (per package, per directory), each batch its own ticket blocked by the
expand, keeping CI green batch to batch because the old form still exists.
Finally contract: delete the old form once no caller remains, in a ticket blocked
by every migrate batch. When even the batches cannot stay green alone, keep the
sequence but let them share an integration branch that all block a final
integrate-and-verify ticket; green is promised only there.

### 4. Quiz the owner

Present the proposed breakdown as a numbered list. For each ticket, show:

- Title: short descriptive name
- Blocked by: which other tickets (if any) must complete first
- What it delivers: the end-to-end behavior this ticket makes work

Ask the owner:

- Is the granularity right? Too coarse or too fine?
- Are the blocking edges correct: does each ticket depend only on tickets that
  genuinely gate it?
- Do any tickets need to merge or split?
- Does the stack order match the merge order, and are the surfaces disjoint for
  the tickets that run together?

Iterate until the owner approves the ticket graph. Record the decision and date
in the mission document's Tickets gate. Never reproduce the owner's words or
name the person who decided. Keep no history of the rounds. Why: the ticket graph
is the gate document, and an agent summary is a log, not the approval.

### 5. Publish the tickets to the configured tracker

Publish the approved tickets. The tracker decides the form; the tickets are the
same either way, and only the shape of the blocking edges changes:

- Local files: write one file per ticket under
  `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01` in
  dependency order (blockers first). Each file's "Blocked by" lists the numbers or
  titles it depends on. Use the per-ticket file template below: one ticket per
  file, never a single combined file.
- A real issue tracker (GitHub, Linear, and so on): publish one issue per ticket
  in dependency order (blockers first) so each ticket's blocking edges reference
  real identifiers. Use the platform's native blocking relationship where it has
  one; otherwise set each ticket's "Blocked by" to the blocking issues. If the
  source was an existing issue, make each ticket its sub-issue (tracker doc's
  operation). Apply the `ready-for-agent` triage label unless instructed
  otherwise; the tickets are agent-grabbable by construction. Record the surface
  and the stack order in the ticket body. The native blocking edges carry the
  graph; the stack order is the order the owner merges.

Work the frontier. A frontier ticket has all its blockers done. Use the stack
rule above for a blocker that is not merged. For a purely linear chain, that
means top to bottom.

Never close or modify a parent issue. Why: the parent is the spec, and closing it hides the work item.

### Local ticket template

```markdown
# <NN>: <Ticket title>

**What to build:** the end-to-end behavior this ticket makes work, from the
owner's perspective, not a layer-by-layer implementation list.

**Surface owned:** the module, route, schema, or command this ticket changes. Two
ready tickets that share a surface are stacked, not run side by side.

**Blocked by:** the numbers or titles of the tickets that gate this one, or "None
(can start immediately)".

**Status:** ready-for-agent

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2
```

### Issue template

```markdown
## Parent

A reference to the parent issue on the tracker (if the source was an existing
issue, otherwise omit this section).

## What to build

The end-to-end behavior this ticket makes work, from the owner's perspective, not
layer-by-layer implementation.

## Surface owned

The module, route, schema, or command this ticket changes. Two ready tickets that
share a surface are stacked, not run side by side.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

- A reference to each blocking ticket, or "None (can start immediately)". Omit
  this section when blockers were set as native edges.
```

Never use specific file paths or code snippets in either form; they go stale
fast. The one exception is a prototype snippet that encodes a decision more
precisely than prose can (state machine, reducer, schema, type shape). Inline it
and note that it came from a prototype. Trim to the decision, not a working demo.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
