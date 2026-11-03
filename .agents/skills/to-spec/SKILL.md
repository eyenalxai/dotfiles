---
name: to-spec
description: "Turn the current conversation into a spec and publish it to the project issue tracker: no interview, just synthesis of what you have already discussed."
disable-model-invocation: true
---

# To Spec

Take the current conversation and the codebase understanding and produce a spec.
Do not interview the owner; synthesize what you already know. Why: the grill
already asked the questions, and a second interview re-opens settled decisions.

The issue tracker and triage label vocabulary should have been provided to you.
If not, ask the owner for the tracker.

## Process

1. Explore the repo to understand the current state of the codebase, if you have
   not already. Use the project's domain glossary vocabulary throughout the spec,
   and respect any ADRs in the area you touch. Why: a spec that invents a term or
   contradicts an ADR sends the ticket graph in the wrong direction.

2. Sketch the seams at which the feature will be tested. Prefer an existing seam
   to a new one, and use the highest seam possible. If a new seam is needed,
   propose it at the highest point you can. The fewer seams across the codebase,
   the better; the ideal number is one. Why: every new seam is a new place the
   implementation can drift from the spec.

   Check with the owner that the seams match their expectations. Why: a seam the
   owner does not expect becomes a test the owner did not approve, and the owner
   sees it first at the PR.

3. Write the spec using the template below, then publish it to the project issue
   tracker. Apply the `ready-for-agent` triage label; no additional triage is
   needed. Why: the spec is the gate document, so it must be in the tracker
   before the ticket graph is cut.

## The spec template

```markdown
## Problem Statement

The problem the owner is facing, from the owner's perspective.

## Solution

The solution from the owner's perspective.

## User Stories

One story per actor and outcome in the scope:

1. As an <actor>, I want a <feature>, so that <benefit>

Cover every actor and every outcome in the scope. A story that cannot be tested
is not a story; move it to Out of Scope. Do not write a story the spec does not
cover. Why: the ticket graph is cut from these stories, so a missing story is a
missing ticket and an invented story is unapproved work.

## Implementation Decisions

The decisions already made:

- the modules to build or modify
- the interfaces that change
- the technical clarifications from the owner
- the architectural decisions
- the schema changes
- the API contracts
- the specific interactions

Do not include specific file paths or code snippets; they go stale. Exception:
when a prototype produced a snippet that encodes a decision more precisely than
prose can (a state machine, a reducer, a schema, a type shape), inline the
decision-rich part and note that it came from a prototype. Trim it to the
decision, not a working demo.

## Testing Decisions

- what makes a good test: external behavior, not implementation details
- which modules are tested
- the prior art for these tests in the codebase

## Out of Scope

Everything this spec does not cover, with the reason. Move any user story here
that is real but not in this scope. Why: the ticket graph must stop at the
scope, and an unlisted out-of-scope item comes back as a surprise ticket.

## Further Notes

Anything else the implementer needs.
```

## Check before publishing

- Every problem in the Problem Statement has a solution.
- Every in-scope actor and outcome has a story.
- Every story has an acceptance the tests can check.
- Every testing decision names a seam the owner approved.
- No file paths, no code snippets, except a prototype decision.
- Every rejected option is in Out of Scope or in the mission's Rejected options
  with its reason. Why: a rejected option that is only in chat comes back in the
  tickets.

Publish the spec, then create the tickets with `to-tickets`. The owner approves
the spec at the Spec gate before the tickets are cut. Why: a ticket graph cut
from an unapproved spec multiplies the unapproved decision.
