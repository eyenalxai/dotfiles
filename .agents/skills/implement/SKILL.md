---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

If the user passes a ticket reference, fetch it from the issue tracker and state its title before starting. If the reference is ambiguous, ask.

## Reporting

Before each step, say what you are about to do, why now, why this way, and what
it unlocks. After it, say what changed and what the next step can now do. Scale
the detail to the step; never drop the why. Inside a mission, the mission
output contract owns the reply shape and the ask-don't-invent rule. Outside a
mission, ask when the why is missing and record the answer in the ticket.

## Seams and checks

Call the Skill tool with "tdd" where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, call the Skill tool with "code-review" to review the work.

Commit your work to the current branch.
