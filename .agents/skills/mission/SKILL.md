---
name: mission
description: Drive one piece of work from a request to reviewable pull requests. Classifies the scope, runs the grill and approval gates, keeps a durable mission document, recommends the next skill, tracks references across sessions, and hands off to fresh sessions automatically.
argument-hint: "<request> | continue | status | handoff | done"
disable-model-invocation: true
---

# Mission

## What this skill is

`mission` is the single entry point for a piece of work. It turns a request into
a flow, keeps that flow in a mission document, and drives it phase by phase until
every ticket has a pull request you can review and merge.

It does five things:

- the scope decision, made with `router`;
- the grill and the approval gates;
- the mission document, the only state that survives a session;
- the flow and the session plan;
- the reference index and the handoff prompt.

Each skill owns its own procedure. Read the skill's `SKILL.md` and follow it.
`mission` decides what happens next, what it produces, and which gate it must
pass.

## Commands

| Command | What it does |
| --- | --- |
| `/mission <request>` | Start a mission, or attach to the matching one |
| `/mission continue` | Read the mission, verify references, name the next step |
| `/mission status` | Show scope, phase, gate, method, references, and next step |
| `/mission handoff` | Force a handoff prompt at the current boundary |
| `/mission done` | Close a mission whose PRs are merged |

## Start

1. Read `AGENTS.md`, the tracker doc, and `router`.
2. Classify the scope with the table below.
3. Find the mission document. Create it from `./mission-template.md` when none
   exists.
4. Run the grill. `grilling` and `domain-modeling` are model-invoked;
   call them. When the repo has `GLOSSARY.md` or `docs/adr/`, call both. When it
   has no docs, call `grilling`. When an existing spec, ticket, or direct
   instruction already holds the understanding, run a short grill to confirm
   the frontier is empty and record that source.
5. Record the scope and understanding gate. Present the problem, constraints,
   approach, flow, and the method. Wait for the user's approval.
6. Only after approval, name the next phase.

## The grill

`grilling` and `domain-modeling` are model-invoked, so `mission` runs them as
part of the flow. `grill-with-docs` is the user-invoked shortcut that calls the
same two skills; it is the standalone command, not the process dependency.

The depth comes from the frontier, not from the scope. A clear bug may have one
question about the repro and the expected behavior. A foggy idea may take many
rounds. The grill is part of the process at every scope, and the user answers
the questions inside the mission.

`domain-modeling` writes only what clears its bar: resolved terms in
`GLOSSARY.md`, and ADRs for decisions that are hard to reverse, surprising, and a
real tradeoff. A short grill can write nothing.

## Scope paths

Wayfinder is for fog, not size. A clear but large feature goes through spec and
tickets; a foggy idea goes through the map first.

Ask, in order:

- Is something broken? -> bug.
- Is the destination or a key decision unknown? -> fog.
- Does the work span more than one session or ticket? -> feature.
- Is the change small and clear? -> change.
- Is it one obvious edit? -> trivial.

| Scope | Signal | Entry | Path | Exit |
| --- | --- | --- | --- | --- |
| Fog | destination or key decisions unknown | `wayfinder` plus the grill | map -> decisions -> spec -> tickets -> implement | PRs |
| Feature | multi-session, shape known | grill, then `to-spec` | grill -> spec -> tickets -> implement | one PR per ticket |
| Change | one session, clear outcome | grill, then `implement` | grill -> implement | one PR |
| Bug | something broken | `diagnosing-bugs` plus the grill | repro -> issue -> implement | one PR |
| Trivial | one obvious edit | short grill plus the tracker issue | issue -> implement | one PR |

Every path ends at a PR with `code-review` and `pr`.
The user reviews and merges.

## Gates

Every flow passes the same gates. The method can change; the gate cannot.

| Gate | Method | The user approves | Next |
| --- | --- | --- | --- |
| Scope and understanding | grill, research, diagnosis, an existing spec or ticket, or a direct confirmation | problem, constraints, approach, flow | spec or issue |
| Spec | the user reads the spec or issue | requirements, non-goals, acceptance | tickets |
| Tickets | the user reads the ticket graph or issue | ticket graph, blocking edges, acceptance | implement |
| PR | `code-review` | diff, evidence, merge danger | merge |

At a pending gate, `mission` presents the document, the open questions, and the
decision it needs. It records the user's approval, then advances. The next step
at a pending gate is the approval itself, not the next phase.

## Phase contracts

| Phase | Skill | Produces | Gate | Next |
| --- | --- | --- | --- | --- |
| Classify | `router` | scope and flow | Scope and understanding | grill |
| Map | `wayfinder` | decision map | Decision gates | spec or research |
| Research | `research` | cited markdown | Scope and understanding | spec or implement |
| Grill | `grilling` and `domain-modeling` with docs; `grilling` without | shared understanding, GLOSSARY, ADR when warranted | Scope and understanding | spec or implement |
| Prototype | `prototype` | answer to a runnable question | Scope and understanding | spec or implement |
| Spec | `to-spec` | spec | Spec | tickets |
| Tickets | `to-tickets` | tickets with blocking edges | Tickets | implement |
| Implement | `implement` or `implement-spec` | code and PRs | PR | code-review |
| Review | `code-review` | Standards and Spec findings | PR | fix or PR |
| PR | `pr` | PR body, evidence, merge danger | PR | user review and merge |
| Handoff | `handoff` | next-session prompt | Current gate | new session |
| Done | none | merged PRs | none | close the mission |

The grill phase uses the two model-invoked skills that `grill-with-docs` wraps.
The wrapper remains the standalone shortcut for a user who wants to start a
grill outside a mission.

Optional detours: `research` when facts are missing,
`prototype` when a question needs runnable code,
`domain-modeling` when a decision is hard to reverse,
`diagnosing-bugs` when the cause is unclear.

## The session plan

The mission document records the session plan. A feature with three tickets has
one session per ticket; a bug has one session. The plan is a table in the
document:

| Session | Work | Exit |
| --- | --- | --- |
| 1 | classify, grill, choose the path | prompt for the first phase |
| 2 | implement <ticket>, review, PR | merged PR, then prompt for the next ticket |

Replan when the scope changes. The user sees the whole flow and where the
handoffs fall before the work starts.

## Automatic handoff

`mission` hands off at the planned boundary without waiting for the
`/mission handoff` command. A boundary is any of:

- the tickets are ready and the first implementation starts;
- a ticket's PR is merged and the next ready ticket starts;
- a gate is pending and the next session should carry it;
- the context reaches the smart zone;
- a side task needs its own context;
- the next phase runs in a different harness or directory;
- the user asks for a fresh session;
- the scope changes enough that the current session is the wrong place.

At the boundary:

1. Update the mission phase, gates, and session plan.
2. Generate the prompt with the `handoff` contract.
3. Deliver one fenced `text` block in the chat. That is the only copy of the
   prompt. Never put the delivered prompt in an issue, a PR, a commit, the repo,
   or the mission document. Add one line to the handoff log: date, session,
   phase, gate, method, `prompt delivered in chat`.
4. Stop editing. The new session starts with `/mission continue`.

A single-session change or bug stays in one session through the PR. Handoff is
for travel: a new session, a new ticket, a new directory, a new harness, or a
side task.

## The handoff prompt

The prompt is self-contained:

- the mission path or URL;
- the fixed point (the merge commit), the next ready ticket, and the blocking
  PRs, plus the blocking edges after it;
- the current gate, its method, and its status;
- the next skill to read;
- the references for that phase;
- the build and check commands;
- the exit: open one PR, run `code-review`, fix the findings, report the PR URL,
  head SHA, checks, and the next ready ticket. The user reviews and merges.

A starting shape:

```text
Read the mission at <path or URL>. Run /mission continue.
The current gate is <gate>, <approved or pending>, reached with <method>.
The blocking PRs are merged: <urls>. The merge commit is <sha>. The next ticket is <id>.
Read the mission references for <phase>, then <skill>.
Run <checks>. Open one PR. Report the PR URL, head SHA, checks, and the next
ready ticket. The user reviews and merges.
```

Write the prompt in the user's language. The `mission` skill owns the decision
and the content. The `handoff` skill owns the format.

## References

The mission document carries the reference index:

| Reference | Why | Path or URL | Phase |
| --- | --- | --- | --- |

At each phase:

- read the repo agent docs;
- name the components involved: source, vendor source, API docs, examples,
  ADRs, research;
- add the rows with the reason and the phase;
- show the top references for the current phase;
- at session start, check each path or URL and mark stale entries.

The `research` output and the `domain-modeling` ADRs are references. The
handoff prompt carries the mission path and the next phase's top references.

## Output contract

Every mission reply starts with the mission line and ends with the next step:

```text
Mission: <slug> | <scope> | <phase>
Gate: <gate> <approved or pending>
Method: <grill method>
Next skill: <skill> (<why>)
Read: <top references>
Produce: <output>
Next step: <exact command>
```

At a pending gate, the next step is the user's approval of the named document.
At a handoff, the prompt follows in chat. At a PR, the line is the PR URL, head
SHA, check state, and the user review and merge.

## Handback

A ticket ends with a reviewable PR. Open one PR, run `code-review`, fix the
findings, and report the PR URL, head SHA, checks, and the next ready ticket.
The user reviews and merges. The next ticket starts only after that merge,
unless the user explicitly asks for a stacked PR. When the user asks the
mission skill to merge, use a merge commit.

## Trackers

Use the configured tracker. Linear: `rata` creates and updates the mission
issue or project and the wayfinder map. GitHub: `gh` creates the issue and the
PR. With no tracker, use `docs/agents/missions/<slug>.md`.

The mission document is the issue, project, or file. Keep the flow, gates,
session plan, references, decisions, outputs, and next step in that one place.
Keep the handoff log there too, but never the prompt itself.

Older mission documents use the previous headings. Read `Stage` as `Phase`,
`Route` as `Flow`, and `Artifacts` as `Outputs`.

## Scope changes

A mission can move between scopes. If a phase reveals fog, add a wayfinder or
research detour. If the fog clears and the work collapses, reduce the flow to
a change or a bug. Record the change, the reason, the new gates, and the new
next step in the mission document.

## It is working if

- The grill runs at every scope, and its depth follows the frontier.
- Every gate is recorded with its method and approved before the next phase.
- The user always knows the scope, phase, gate, method, next skill, and next
  command.
- A fresh session resumes from the mission document without re-explaining.
- Every load-bearing reference is a path or URL in the mission, and stale
  references are flagged at session start.
- Each ticket ends at a PR with `code-review`, and the user merges it.
- A handoff prompt appears in chat at the planned boundary, and the mission
  document has only the log line.
