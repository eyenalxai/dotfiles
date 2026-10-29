---
name: mission
description: Drive one piece of work from a request to reviewable pull requests. Classifies the scope, runs the process grill and approval gates, keeps a durable mission artifact, recommends the next skill, tracks references across sessions, and hands off to fresh sessions automatically.
argument-hint: "<request> | continue | status | handoff | done"
disable-model-invocation: true
---

# Mission

## What this skill is

`mission` is the single entry point for a piece of work. It turns a request into
a route, keeps that route in a mission artifact, and drives the route stage by
stage until every ticket has a pull request the owner can review and merge.

It owns five things:

- the scope decision, made with `router`;
- the process grill and the approval gates;
- the mission artifact, the only state that survives a session;
- the route and the session plan;
- the reference index and the handoff prompt.

The stage skills own their procedures. Read the stage skill's `SKILL.md` and
follow it. `mission` decides which stage comes next, what artifact it produces,
and which gate it must pass.

## Commands

| Command | What it does |
| --- | --- |
| `/mission <request>` | Start a mission, or attach to the matching one |
| `/mission continue` | Read the mission, verify references, name the next step |
| `/mission status` | Show scope, stage, gate, method, references, and next step |
| `/mission handoff` | Force a handoff prompt at the current boundary |
| `/mission done` | Close a mission whose PRs are merged |

## Start

1. Read `AGENTS.md`, the tracker doc, and `router`.
2. Classify the scope with the table below.
3. Find the mission artifact. Create it from `./mission-template.md` when none
   exists.
4. Run the process grill. `grilling` and `domain-modeling` are model-invoked;
   call them. When the repo has `GLOSSARY.md` or `docs/adr/`, call both. When it
   has no docs, call `grilling`. When an existing spec, ticket, or direct
   instruction already holds the understanding, run a short grill to confirm
   the frontier is empty and record that source.
5. Record the scope and understanding gate. Present the problem, constraints,
   approach, route, and the method. Wait for the owner's approval.
6. Only after approval, name the next stage.

## The process grill

`grilling` and `domain-modeling` are model-invoked, so `mission` runs them as
part of the route. `grill-with-docs` is the user-invoked shortcut that calls the
same two skills; it is the standalone command, not the process dependency.

The depth comes from the frontier, not from the scope. A clear bug may have one
question about the repro and the expected behavior. A foggy idea may take many
rounds. The grill step is part of the process at every scope, and the owner
answers the questions inside the mission.

`domain-modeling` writes only what clears its bar: resolved terms in
`GLOSSARY.md`, and ADRs for decisions that are hard to reverse, surprising, and a
real tradeoff. A short grill can write nothing.

## Scope routes

Wayfinder is the fog rung, not the size rung. A clear but large feature goes
through spec and tickets; a foggy idea goes through the map first.

Ask, in order:

- Is something broken? -> bug.
- Is the destination or a key decision unknown? -> fog.
- Does the work span more than one session or ticket? -> feature.
- Is the change small and clear? -> change.
- Is it one obvious edit? -> trivial.

| Scope | Signal | Entry | Route | Exit |
| --- | --- | --- | --- | --- |
| Fog | destination or key decisions unknown | `wayfinder` plus the process grill | map -> decisions -> spec -> tickets -> implement | PRs |
| Feature | multi-session, shape known | process grill, then `to-spec` | grill -> spec -> tickets -> implement | one PR per ticket |
| Change | one session, clear outcome | process grill, then `implement` | grill -> implement | one PR |
| Bug | something broken | `diagnosing-bugs` plus the process grill | repro -> issue -> implement | one PR |
| Trivial | one obvious edit | short process grill plus the tracker issue | issue -> implement | one PR |

Every route ends at a PR with `code-review` and `pr`.
The owner reviews and merges.

## Gates

Every route passes the same gates. The method scales with the situation; the
gate stays.

| Gate | Method | The owner approves | Next |
| --- | --- | --- | --- |
| Scope and understanding | process grill, research, diagnosis, an existing spec or ticket, or a direct confirmation | problem, constraints, approach, route | spec or issue |
| Spec | the owner reads the spec or issue | requirements, non-goals, acceptance | tickets |
| Tickets | the owner reads the ticket graph or issue | ticket graph, blocking edges, acceptance | implement |
| PR | `code-review` | diff, evidence, merge danger | merge |

At a pending gate, `mission` presents the artifact, the open questions, and the
decision it needs. It records the owner's approval, then advances. The next step
at a pending gate is the approval itself, not the next stage.

## Stage contracts

| Stage | Skill | Produces | Gate | Next |
| --- | --- | --- | --- | --- |
| Classify | `router` | scope and route | Scope and understanding | process grill |
| Map | `wayfinder` | decision map | Decision gates | spec or research |
| Research | `research` | cited markdown | Scope and understanding | spec or implement |
| Grill | `grilling` and `domain-modeling` with docs; `grilling` without | shared understanding, GLOSSARY, ADR when warranted | Scope and understanding | spec or implement |
| Prototype | `prototype` | answer to a runnable question | Scope and understanding | spec or implement |
| Spec | `to-spec` | spec | Spec | tickets |
| Tickets | `to-tickets` | tickets with blocking edges | Tickets | implement |
| Implement | `implement` or `implement-spec` | code and PRs | PR | code-review |
| Review | `code-review` | Standards and Spec findings | PR | fix or PR |
| PR | `pr` | PR body, evidence, merge danger | PR | owner review and merge |
| Handoff | `handoff` | next-session prompt | Current gate | new session |
| Done | none | merged PRs | none | close the mission |

The grill stage uses the two model-invoked skills that `grill-with-docs` wraps.
The wrapper remains the standalone shortcut for a user who wants to start a
grill outside a mission.

Optional detours: `research` when facts are missing,
`prototype` when a question needs runnable code,
`domain-modeling` when a decision is hard to reverse,
`diagnosing-bugs` when the cause is unclear.

## The session plan

The mission artifact plans the sessions. A feature with three tickets has one
session per ticket; a bug has one session. The plan is a table in the artifact:

| Session | Work | Exit |
| --- | --- | --- |
| 1 | classify, grill, route | prompt for the first stage |
| 2 | implement <ticket>, review, PR | prompt for the next ticket |

Replan when the scope changes. The owner sees the whole route and where the
handoffs fall before the work starts.

## Automatic handoff

`mission` hands off at the planned boundary without waiting for the
`/mission handoff` command. A boundary is any of:

- the tickets are ready and the first implementation starts;
- a ticket's PR is open and the next ready ticket starts;
- a gate is pending and the next session should carry it;
- the context reaches the smart zone;
- a side task needs its own context;
- the next stage runs in a different harness or directory;
- the owner asks for a fresh session;
- the scope changes enough that the current session is the wrong place.

At the boundary:

1. Update the mission stage, gates, session plan, and handoff log.
2. Generate the prompt with the `handoff` contract.
3. Deliver one fenced `text` block in the chat and in the mission artifact.
4. Stop editing. The new session starts with `/mission continue`.

A single-session change or bug stays in one session through the PR. Handoff is
for travel: a new session, a new ticket, a new directory, a new harness, or a
side task.

## The handoff prompt

The prompt is self-contained:

- the mission path or URL;
- the fixed point and the next ready ticket, plus the blocking edges after it;
- the current gate, its method, and its status;
- the next skill to read;
- the references for that stage;
- the build and check commands;
- the exit: open one PR, run `code-review`, fix the findings, report the PR URL,
  head SHA, checks, and the next ready ticket. The owner reviews and merges.

A starting shape:

```text
Read the mission at <path or URL>. Run /mission continue.
The current gate is <gate>, <approved or pending>, reached with <method>.
The previous PR is <url>. The next ticket is <id>.
Read the mission references for <stage>, then <skill>.
Run <checks>. Open one PR. Report the PR URL, head SHA, checks, and the next
ready ticket. The owner reviews and merges.
```

The `mission` skill owns the decision and the content. The `handoff` skill owns
the format.

## References

The mission artifact carries the reference index:

| Reference | Why | Path or URL | Stage |
| --- | --- | --- | --- |

At each stage:

- read the repo agent docs;
- name the components involved: source, vendor source, API docs, examples,
  ADRs, research;
- add the rows with the reason and the stage;
- show the top references for the current stage;
- at session start, check each path and URL and mark stale entries.

The `research` output and the `domain-modeling` ADRs are references. The
handoff prompt carries the mission path and the next stage's top references.

## Output contract

Every mission reply starts with the mission line and ends with the next step:

```text
Mission: <slug> | <scope> | <stage>
Gate: <gate> <approved or pending>
Method: <grill method>
Next skill: <skill> (<why>)
Read: <top references>
Produce: <artifact>
Next step: <exact command>
```

At a pending gate, the next step is the owner's approval of the named artifact.
At a handoff, the prompt follows. At a PR, the line is the PR URL, head SHA,
check state, and the owner review and merge.

## Owner handback

A ticket ends with a reviewable PR. Open one PR, run `code-review`, fix the
findings, and report the PR URL, head SHA, checks, and the next ready ticket.
The owner reviews and merges. When the owner asks the mission skill to merge,
use a merge commit.

## Trackers

Use the configured tracker. Linear: `rata` creates and updates the mission
issue or project and the wayfinder map. GitHub: `gh` creates the issue and the
PR. With no tracker, use `docs/agents/missions/<slug>.md`.

The mission artifact is the issue, project, or file. Keep the route, gates,
session plan, references, decisions, artifacts, next step, and handoff log in
that one place.

## Scope changes

A mission can move between scopes. If a stage reveals fog, add a wayfinder or
research detour. If the fog clears and the work collapses, reduce the route to
a change or a bug. Record the change, the reason, the new gates, and the new
next step in the mission artifact.

## It is working if

- The process grill runs at every scope, and its depth follows the frontier.
- Every gate is recorded with its method and approved before the next stage.
- The owner always knows the scope, stage, gate, method, next skill, and next
  command.
- A fresh session resumes from the mission artifact without re-explaining.
- Every load-bearing reference is a path or URL in the mission, and stale
  references are flagged at session start.
- Each ticket ends at a PR with `code-review`, and the owner merges it.
- A handoff appears at the planned boundary with the prompt already written.
