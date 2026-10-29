---
name: router
description: Ask which skill or flow fits your situation. A router over the skills in this repo and the classifier behind mission.
disable-model-invocation: true
---

# Router

You don't remember every skill, so route.

Before stating what a skill does or recommending a step be skipped, read that skill's SKILL.md: the summaries here are for orientation only.

`mission` drives the main flow as one entry. This router is the classifier it calls, and it also works on its own when you only want the next step.

## Answer shape

End every routing reply with a **Next step** line that names the exact skill or
command, the ticket or artifact, and what it produces.

Next step: `/implement` ticket 123. It produces a reviewable PR, then `/code-review`.
Next step: `/handoff`. It produces the next-session prompt for the next ticket.

When the next step is `/handoff`, the prompt is the deliverable: one fenced
`text` block the owner can copy with one click.

## The main flow: idea to reviewable PR

`mission` drives this flow. The stages below are the underlying map.

1. **The grill.** `grilling` and `domain-modeling` build shared understanding. In a working directory, the process grill calls both. With no working directory, use `grill-me`. `/grill-with-docs` is the standalone command for the same composition in a repo.
2. **The plan.** Use `to-spec` to record the agreed spec and `to-tickets` to cut it into tickets with blocking edges. `wayfinder` charts a foggy, multi-session effort as decision tickets first. `research` supplies facts and `prototype` answers a question that needs runnable code.
3. **The build.** `implement` builds one ticket and drives `tdd` at the agreed seams; `implement-spec` works the whole ticket graph. Both close with `code-review`. `pr` shapes the body. The owner reviews and merges.

A single-session change skips the spec and tickets and goes from the grill to `implement`. A bug goes through `diagnosing-bugs` and a short grill before the issue and the PR.

## On-ramps

- **Incoming requests and bugs** -> `triage`. It verifies the claim, grills if needed, and writes an agent-ready issue.
- **Something broken** -> `diagnosing-bugs`. It builds a tight feedback loop before it theorises.
- **A huge, foggy effort** -> `wayfinder`. It charts a map of decision tickets and hands the clear route back to the flow.

## Design vocabulary

- `domain-modeling` sharpens the project's language and writes `GLOSSARY.md` and ADRs.
- `codebase-design` is the deep-module vocabulary for specs, tickets, and implementation seams.

## Standalone

- `grill-me` is the stateless grill for a plan or design with no repo.
- `grilling` is the interview primitive underneath every grill.
- `prototype` answers a design question with throwaway code.
- `research` investigates a question against primary sources and leaves a cited markdown file.
- `handoff` writes the handoff document and the next-session prompt.

## Phase boundary

At a boundary, the options are continue, clear, handoff, subagent, and compact. `mission` plans the handoff points and produces the prompt. Outside a mission, use `handoff` when the work travels to a new session, a new directory, a new harness, or another agent.

## Ticket handback

A ticket ends with a reviewable PR. The implementer opens one PR, runs
`code-review`, fixes the findings, and reports the PR URL, head SHA, checks,
and the next ready ticket. The owner reviews and merges. When the owner asks
the agent to merge, use a merge commit.

## Context hygiene

Keep the grill, spec, and tickets in one unbroken context window so they build
on the same thinking. Each implementation then starts fresh from the ticket.
