---
name: to-spec
description: "Turn the current conversation into a spec and publish it to the project issue tracker after the gate in a mission. Synthesize the discussion; never interview."
disable-model-invocation: true
---

# To spec

Turn the current conversation and the codebase understanding into a spec. Never
interview the owner; synthesize what is known. Why: the grill already asked the
questions, and a second interview reopens settled decisions.

Write the spec in neutral language. Never reproduce words directly or name the
person who decided. The spec is current state only: no prior attempts, sessions,
issues, or versions. Why: the spec records what will be
built, not who said it or how the decision was reached.

The issue tracker and triage label vocabulary come from the repo's agent docs. If
they are missing, ask the owner for the tracker.

## Process

1. Explore the repo to understand the current state of the codebase, if not
   already done. Use the project's domain glossary vocabulary throughout the spec,
   and respect ADRs in the area you touch. Why: a spec that invents a term or
   contradicts an ADR sends the ticket graph in the wrong direction.

2. Sketch the seams at which the feature will be tested. Prefer an existing seam
   to a new one, and use the highest seam possible. If a new seam is needed,
   propose it at the highest point available. The ideal is one seam across the
   codebase. Put the seams in Testing Decisions. The owner approves them at the
   scope and spec gate; never ask for a separate seam approval. Why: every new seam is a new place the implementation can drift from
   the spec, and the gate is the approval that covers it.

3. Write the spec using the template below. Inside a mission, the spec is a draft
   until the scope and spec gate is approved. Present it with the scope in the
   conversation. Never publish it before the gate. After approval, publish it to
   the project issue tracker and apply the `ready-for-agent` triage label; no
   additional triage is needed. When the mission uses the spec as its record, add
   the record sections from the mission template to the same issue; never create
   a second issue. On a fog, the map is the record: publish the spec as a
   separate issue and link it from the map. Why: the spec is the gate document,
   and it is a draft until the scope and spec gate. Standalone, the owner's
   request to write and publish the spec is the approval.

## The spec template

```markdown
## Problem Statement

The problem the owner is facing, from the owner's perspective.

## Solution

The solution from the owner's perspective.

## User Stories

One story per actor and outcome in the scope:

1. As an <actor>, I want a <feature>, so that <benefit>

Cover every actor and outcome in the scope. A story that cannot be tested is not
a story; move it to Out of Scope. Never write a story the spec does not cover.
Why: the ticket graph is cut from these stories, so a missing story is a missing
ticket and an invented story is unapproved work.

## Implementation Decisions

The decisions already made:

- the modules to build or modify
- the interfaces that change
- the technical clarifications from the owner
- the architectural decisions
- the schema changes
- the API contracts
- the specific interactions

Never include specific file paths or code snippets; they go stale. The one
exception is a prototype snippet that encodes a decision more precisely than
prose can (a state machine, a reducer, a schema, a type shape). Inline the
decision-rich part and note that it came from a prototype. Trim it to the
decision, not a working demo.

## Testing Decisions

- what a test must check: external behavior, not implementation details
- which modules are tested
- the prior art for these tests in the codebase

## Out of Scope

Everything this spec does not cover, with the reason. Move any user story here
that is real but not in this scope. Why: the ticket graph must stop at the scope,
and an unlisted out-of-scope item comes back as a surprise ticket.

## Further Notes

Anything else the implementer needs.
```

## Check before publishing

- Every problem in the Problem Statement has a solution.
- Every in-scope actor and outcome has a story.
- Every story has an acceptance criterion the tests can check.
- Every testing decision names a seam the owner approved.
- No file paths, no code snippets, except a prototype decision.
- Every rejected option is in Out of Scope or in the mission's Rejected options
  with its reason. Why: a rejected option that is only in chat comes back in the
  tickets.

After publishing, create the tickets with `to-tickets`.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
