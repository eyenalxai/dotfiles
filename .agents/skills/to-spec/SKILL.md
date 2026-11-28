---
name: to-spec
description: "Turn the current conversation into a spec and publish it to the project issue tracker after the gate in a mission. Synthesize the discussion; never interview."
disable-model-invocation: true
---

# To spec

Synthesize the settled discussion and codebase understanding into a spec. Never re-interview the owner; grilling already settled the decisions, and asking again reopens them.

Read the tracker doc and triage-label mapping first. If either is missing, ask the owner.

## Process

1. **Confirm repo context.** Explore the codebase if not already done. Use `GLOSSARY.md` vocabulary and respect existing ADRs; inventing terms or contradicting an ADR sends the ticket graph off course.
2. **Pick testing seams.** Prefer an existing seam over a new one, and place seams as high as possible (ideally one seam across the codebase). Record them in **Testing Decisions**. Never ask for a separate seam approval; the scope and spec gate covers them.
3. **Draft the spec** using the template below. Write in neutral current state only: never quote the conversation, name who decided, or include history.
4. **Gate and publish:**
   - **Inside a mission:** keep the spec as a draft in conversation until the scope and spec gate is approved. After approval, publish to the tracker with the `ready-for-agent` label (no extra triage needed). On a Feature, add the mission record sections from `mission-template.md` to this same issue (never create a second issue). On a Fog, the map is the record: publish the spec as a separate issue and link it from the map.
   - **Standalone:** the owner's request to write and publish the spec is the approval.

## Spec template

```markdown
## Problem Statement

The problem from the owner's perspective.

## Solution

The solution from the owner's perspective.

## User Stories

One story per in-scope actor and outcome:

1. As an <actor>, I want <capability>, so that <benefit>.

Move any untestable story to Out of Scope. Never add a story outside the agreed scope; tickets are cut directly from these stories.

## Implementation Decisions

Settled technical decisions:
- modules to build or change
- interface, schema, and API contract changes
- architectural and interaction decisions

Never put specific file paths or code snippets here; they go stale. One exception: a trimmed prototype snippet that captures a decision sharper than prose (state machine, reducer, schema, type shape), marked as coming from a prototype.

## Testing Decisions

- external behaviors tests must check (never internals)
- approved seams and modules under test
- existing test prior art in the codebase

## Out of Scope

Excluded items with the reason for each, plus any rejected options so they do not resurface as tickets.

## Further Notes

Remaining constraints or context an implementer needs.
```

## Check before publishing

- [ ] Every problem in Problem Statement maps to a solution.
- [ ] Every in-scope actor and outcome has a testable User Story.
- [ ] Every Testing Decision names an approved seam.
- [ ] No file paths or code snippets (except trimmed prototype decision shapes).
- [ ] Every rejected option is recorded in Out of Scope (or mission Rejected options) with its reason.
- [ ] Neutral language, no quotes, no decider names, no history.

After publishing, load `to-tickets` to cut the ticket graph.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
