---
name: wayfinder
description: Chart a large, uncertain effort as one map issue with child decision tickets, and resolve one ticket per session until the path to the destination is clear.
disable-model-invocation: true
---

# Wayfinder

Chart a foggy effort as one **map** issue on the repo's tracker, with child **decision tickets**. Resolve tickets until the destination and path are clear enough for a spec or direct build.

## Roles

- **Orchestrator (`opencode-go/kimi-k3.1-pro`)**: charts the map, runs HITL grilling/domain-modeling exchanges with the owner, critiques worker outputs, and writes the map body, child ticket questions, resolution comments, and Decisions so far.
- **Workers (`openrouter/deepseek/deepseek-v4.1-flash-1017#max`)**: run all `wayfinder:research` tickets in parallel, build `wayfinder:prototype` artifacts, execute AFK `wayfinder:task` legwork, and gather codebase context before HITL tickets.

## When to use

Use wayfinder when the destination or key decisions are unknown and cannot be settled in one session. If the path is clear, skip wayfinder and use a Feature or Change flow; a map for clear work creates busywork tickets that delay building.

**Plan, do not do.** Tickets resolve decisions or investigations; they do not deliver the final product unless the map's **Notes** explicitly overrides this.

## Tracker and writing rules

- Read the tracker doc's "Wayfinding operations" section first. If no tracker is configured, stop and ask the owner to set one up.
- **Neutral current state only.** Never quote the conversation, name who decided, or log history in the map, tickets, or comments.
- **Refer by title.** In every owner-facing line and in `Decisions so far`, name maps and tickets by title (with the URL inside the markdown link), never by a bare id or slug.
- **Labels.** Map gets `wayfinder:map`. Each child gets exactly one `wayfinder:<type>` label (`research`, `prototype`, `grilling`, or `task`) and no other labels. Never apply `ready-for-agent`; these are decision tickets, not build tickets.
- **Claiming and blocking.** Assign a ticket to yourself before starting it so concurrent sessions stay off it. Use native tracker blocking edges (fall back to body references only if the tracker has none). The **frontier** is open, unblocked, unclaimed child tickets in map order.

## Ticket types

Every ticket is **HITL** (requires live owner exchange; never answer the owner's side yourself) or **AFK** (worker runs alone):

| Label | Mode | Owner / Worker split |
| --- | --- | --- |
| `wayfinder:grilling` | HITL (default) | Orchestrator loads `grilling` + `domain-modeling`; worker gathers repo facts |
| `wayfinder:research` | AFK | Worker (`openrouter/deepseek/deepseek-v4.1-flash-1017#max`) loads `research`, writes cited findings to throwaway `research/<name>` branch (pushed, no PR); orchestrator critiques citations and records summary |
| `wayfinder:prototype` | HITL | Worker builds throwaway artifact per `prototype`; orchestrator verifies it answers the question and reviews with owner |
| `wayfinder:task` | AFK or HITL | Manual prerequisite unblocking a decision (provisioning access, migrating sample data). Worker executes if AFK; orchestrator hands owner a checklist if HITL |

## Fog vs. ticket vs. out of scope

```text
Is this work past the stated Destination?
├── Yes → Out of scope (close any ticket, record one line with reason; never graduates)
└── No
    ├── Can you phrase the exact question now (even if blocked)?
    │   ├── Yes → Child ticket (wire blocking edges)
    │   └── No  → Not yet specified (fog; keep coarse until frontier clears it)
```

## Map and ticket templates

The map is a low-resolution index loaded once per session. Never list open tickets in its body; query open child issues instead. Record each decision once in its ticket, with a one-line gist and link on the map.

```markdown
## Destination

<1-2 lines: what the end of this map produces (spec, locked decision, or in-place change).>

## Notes

<Domain, skills every session must load, standing preferences.>

## Decisions so far

- [<closed ticket title>](link): <one-line gist>

## Not yet specified

<Coarse fog still in scope, excluding decided, ticketed, or out-of-scope items.>

## Out of scope

<Ruled past the destination, with one-line reason and link if a ticket was closed.>
```

Child ticket body (sized to one session; never include the type or the answer in the body):

```markdown
## Question

<The exact decision or investigation this ticket resolves.>
```

## Mode 1: chart the map

Invoked with a loose idea. Charting resolves nothing and ends in one session.

1. **Pin the destination.** Load `grilling` and `domain-modeling` to settle the destination first; it defines scope.
2. **Sweep breadth-first.** Grill across the space to surface open decisions and first steps. If no fog remains, stop and tell the owner this fits a Feature or Change without a map.
3. **Create the map** (`wayfinder:map`) with Destination, Notes, empty Decisions so far, and coarse fog in Not yet specified.
4. **Create tickets, then wire edges.** Create all specifiable child issues first so real IDs exist, then wire blocking edges and cross-references in a second pass (placeholder `#<n>` numbers auto-link to wrong issues).
5. **Launch parallel research workers.** For every `wayfinder:research` ticket just created, spawn a DeepSeek `general` worker (`openrouter/deepseek/deepseek-v4.1-flash-1017#max`) to run `research` in parallel and push findings to `research/<name>` (no PR). Critique their findings and link them from the tickets.
6. **Stop.** Present the map and frontier to the owner.

## Mode 2: work through the map

Invoked with a map URL or number (ticket optional; if omitted, pick the first frontier ticket in map order). Resolve at most one HITL ticket per session so the decision stays coherent; parallel research tickets are the only exception.

1. **Load the map** (index only; fetch specific closed/related ticket bodies on demand).
2. **Claim the ticket** by assigning it before doing any work.
3. **Resolve by label.** Read its `wayfinder:<type>` label and load any skills named in the map's Notes (default to `grilling` + `domain-modeling` when unsure).
4. **Record resolution.** Post the answer as a neutral resolution comment (link assets rather than pasting them), close the ticket, and append the one-line gist + link to the map's `Decisions so far`.
5. **Update the map.** Graduate newly clear fog into child tickets (create-then-wire) and remove those items from `Not yet specified`. Close and move to `Out of scope` any ticket now past the destination. Update or close tickets invalidated by the decision.

Expect concurrent edits from other sessions working unblocked frontier tickets.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
