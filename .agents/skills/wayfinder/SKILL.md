---
name: wayfinder
description: Chart a large, uncertain effort as one map issue with child decision tickets, and resolve one ticket per session until the path to the destination is clear.
disable-model-invocation: true
---

# Wayfinder

Use this skill when the destination or the key decisions are unknown and one session cannot hold the work. A **map** is one issue on the repo's issue tracker. Its **tickets** are child issues. Each ticket resolves one decision. Work tickets one at a time until the path to the destination is clear.

Write the map, the tickets, and the resolution comments in neutral language. Never quote the conversation or name the person who decided. The map is current state only: no prior attempts, sessions, issues, or versions. Why: the map records the route, not the conversation.

## When to use

Use wayfinder when the destination or the key decisions are unknown. Do not use it when the path is clear; that case is a feature or a change. Why: a map for a clear path adds decision tickets that decide nothing, and the build waits on them.

The destination varies per effort, and naming it is the first act of charting because it shapes every ticket. It can be a spec to hand off, a decision to lock before planning starts, or a change made in place such as a data-structure migration. The map is domain-agnostic: engineering work, course content, or any other effort that fits the shape.

## Plan, do not do

Wayfinder plans. Each ticket resolves a decision or an investigation; it does not deliver the destination. If a ticket starts to deliver work, stop and hand off. An effort can override this rule in the map's **Notes** and carry execution into the map itself. Without that override, produce decisions, not deliverables.

## Refer by name

Every map and ticket is an issue with a title. In everything the owner reads (narration and the map's Decisions so far), refer to it by title, never by a bare id, number, or slug. The id and URL ride inside the title link; they never stand in for the title. Why: a row of numbers is illegible, and a title reads at a glance.

## The map

The map is one issue on this repo's issue tracker, labeled `wayfinder:map`. Its tickets are child issues of the map. The map is an index, not a store: it lists the decisions made and links to the ticket that holds each detail. A decision lives in one place, its ticket. The map gists it and links; it never restates it.

Where the map, its child tickets, blocking, and frontier queries live is tracker-specific. Read the tracker doc's "Wayfinding operations" section for how this repo expresses them. If no tracker is configured, stop and ask the owner to set one up.

### The map body

The map is the low-resolution view, loaded once per session. Do not list open tickets in the body; find them by query as open child issues.

```markdown
## Destination

<what reaching the end of this map looks like: the spec, decision, or change this effort is finding its way to. One or two lines; every session reads this before choosing a ticket.>

## Notes

<domain; skills every session must load; standing preferences for this effort>

## Decisions so far

<!-- the index: one line per closed ticket, enough to judge relevance, then the link for the detail the ticket holds -->

- [<closed ticket title>](link): <one-line gist of the answer>

## Not yet specified

<!-- see "Fog": in-scope work that is not sharp enough to ticket yet; graduates as the frontier advances -->

## Out of scope

<!-- see "Out of scope": work ruled beyond the destination; closed, never graduates -->
```

### Tickets

Each ticket is a child issue of the map. The tracker's issue id is its identity. The body is the question, sized to one 100K token session:

```markdown
## Question

<the decision or investigation this ticket resolves>
```

Each ticket carries one `wayfinder:<type>` label: `research`, `prototype`, `grilling`, or `task` (see [Ticket types](#ticket-types)). A map and its tickets carry no other labels. Never add a triage label such as `ready-for-agent`; these tickets are decisions, not implementation work.

A session **claims** a ticket by assigning it to itself before any work. That assignee is the claim: an open, unassigned ticket is unclaimed. Why: a visible claim keeps concurrent sessions off the same ticket.

Blocking uses the tracker's **native** dependency relationship. Native blocking renders the frontier in the tracker UI, so the owner sees what is takeable without opening the map. Fall back to a body convention only when the tracker has no native blocking. A ticket is **unblocked** when every ticket blocking it is closed. The **frontier** is the open, unblocked, unclaimed child tickets, in map order.

The answer is not part of the body. Record it on resolution (see [Work through the map](#work-through-the-map)). Link assets created while resolving a ticket from the issue; do not paste them in.

## Ticket types

Every ticket is **HITL** (a person works with the agent) or **AFK** (the agent works alone). A HITL ticket resolves only through a live exchange with the owner; the agent never answers the owner's side. A grilling agent that answers its own questions has broken this rule.

- **Research** (AFK): read documentation, third-party APIs, or local resources such as knowledge bases to find a fact a decision waits on. Resolve it with a subagent that loads `research` with the Skill tool. Use when the knowledge sits outside the working directory.
- **Prototype** (HITL): build a cheap, rough artifact to react to: an outline, a rough take, a stub, or UI or logic code. Load `prototype` with the Skill tool. Link the prototype as an asset. Use when the key question is how something will look or behave.
- **Grilling** (HITL): talk with the owner. This is the default. Load `grilling` and `domain-modeling` with the Skill tool.
- **Task** (HITL or AFK): manual work that must happen before a decision can be made. There is nothing to decide, prototype, or research, but the discussion is blocked until the work is done: sign up for a service so its API can be judged, provision access, move data so its shape can be seen. A task executes work; it does not decide. It earns its place by unblocking a decision. The agent drives it alone when it can (AFK); otherwise it hands the owner a precise checklist (HITL). Resolve it when the work is done; the answer records what was done and the facts later tickets need (credential location, new URLs, row counts).

## Fog

The map is deliberately incomplete. Do not chart what you cannot see yet. Beyond the live tickets lies the **fog**: the decisions and investigations you can tell are coming but cannot state precisely because they hang on questions still open. Resolving a ticket clears the fog ahead of it and graduates what is now specifiable into fresh tickets, one at a time, until the way to the destination is clear and no tickets remain.

The map's **Not yet specified** section holds the fog: the suspected question, the area to revisit later. Everything there is in scope; it is not sharp enough to ticket. Write it as loosely or as fully as the view allows. It also shows collaborators where the effort is headed.

**Fog or ticket?** The test is whether you can state the question precisely now, not whether you can answer it now.

- **Ticket when** the question is sharp, even when a blocker stops work on it.
- **Not yet specified when** you cannot phrase it that sharply. Do not slice the fog into ticket-sized pieces: it is coarser than a ticket, and one patch may become several tickets, or none, once the frontier reaches it.

**Not yet specified** excludes what is already decided (Decisions so far), what is already a live ticket, and what is out of scope (the next section).

## Out of scope

The destination fixes the scope. Work beyond it is **out of scope**: it is not fog and does not belong in **Not yet specified**. The map gets an **Out of scope** section for work ruled out of this effort. Scope, not sharpness, puts it there.

Out-of-scope work never graduates. The frontier stops at the destination, so that work returns only when the owner redraws the destination, and then as a fresh effort, not a resumption.

Ruling something out of scope is a scoping act, not a step on the route. When an existing ticket turns out to sit past the destination, close it (a closed ticket is off the frontier) and add one line to **Out of scope**: the gist, why it is out of scope, and a link to the closed ticket. Keep it out of **Decisions so far**, which records the route walked; a scope line is not a step on it.

## Invocation

Two modes. In both, never resolve more than one ticket per session, except research tickets. Why: one ticket per session keeps the decision and its context in one place.

### Chart the map

The owner invokes this mode with a loose idea.

1. **Name the destination.** Load `grilling` and `domain-modeling` with the Skill tool to pin down what this map is finding its way to: the spec, decision, or change. The destination fixes the scope, so settle it first.
2. **Map the frontier.** Grill again, breadth-first: fan out across the whole space, list the open decisions, and find the first steps takeable now. If this finds no fog, the path is clear and one session can hold it. Do not make a map; stop and ask the owner how to proceed.
3. **Create the map** with the `wayfinder:map` label. Fill in Destination and Notes, leave Decisions so far empty, and sketch the fog into **Not yet specified**.
4. **Create the tickets you can specify now** as child issues of the map, then wire blocking edges in a second pass. Issues need ids before they can reference each other. Write cross-references in that pass with real ids; a placeholder `#<n>` auto-links to an unrelated issue. Wiring sorts tickets into the frontier and the blocked. Leave everything you cannot specify in **Not yet specified**.
5. **Start the research subagents.** For each `research` ticket just created, run a subagent that loads `research` with the Skill tool to resolve it in parallel. Capture its findings on a throwaway `research/<name>` branch with a context pointer from the ticket. Push the branch and open no PR; it is never merged.
6. **Stop.** Charting is one session's work and resolves nothing.

### Work through the map

The owner invokes this mode with a map URL or number. A ticket is optional: without one, you choose the next decision, not the owner.

1. **Load the map**: the low-resolution view, not every ticket body.
2. **Choose the ticket.** Use the ticket the owner named. Otherwise take the first frontier ticket in map order. Claim it by assigning it before any work.
3. **Resolve it as the type in its `wayfinder:<type>` label.** Read the label, not the body; the body never states the type. Fetch the full body of any related or closed ticket on demand. Load the skills the map's **Notes** block names. When in doubt, load `grilling` and `domain-modeling` with the Skill tool.
4. **Record the resolution**: post the answer as a resolution comment, close the issue, and append a context pointer to the map's Decisions so far.
5. **Update the map.** Add newly surfaced tickets with create-then-wire. Graduate the fog the answer made specifiable and clear each graduated patch from **Not yet specified**, so it lives only as its new ticket. If the answer puts a ticket past the destination, rule it out of scope. If the decision invalidates other parts of the map, update or delete those tickets.

Other sessions may run unblocked tickets in parallel. Expect concurrent edits to the tracker.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
