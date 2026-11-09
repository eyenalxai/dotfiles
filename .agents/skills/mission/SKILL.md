---
name: mission
description: Drive one piece of work from a request to reviewable pull requests. Classifies the scope, runs the grill and the owner's approval gates, keeps a durable mission document, recommends the next skill, tracks references across sessions, and hands off automatically when the work travels.
argument-hint: "<request> | continue | status | handoff | done"
disable-model-invocation: true
---

# Mission

## What this skill is

`mission` is the single entry point for a piece of work. It turns a request into
a flow, keeps that flow in a mission document, and drives it phase by phase until
every ticket has a pull request the owner can review and merge.

It does six things:

- the scope decision, made with `router`;
- the grill and the owner's approval gates;
- the mission document once it exists; before that, the handoff prompt carries
  the state;
- the frontier, the flow, and the session plan;
- the reference index and the handoff prompt;
- the answer-first reply, with the state kept out of it.

The flow runs the ready frontier: independent tickets together, dependent
tickets stacked, up to the mission's cap. It does not queue tickets behind the
previous PR when the graph says they are ready. Why: a queue leaves the frontier
idle, and the frontier is the work the graph allows now.

Each skill owns its own procedure. Read the skill's `SKILL.md` and follow it.
`mission` decides what happens next, what it produces, and which gate it must
pass.

A skill named here is a file to load, not a label to perform. Load it with the
Skill tool before you produce its output. The summaries in this skill are
orientation; the procedure lives in the named skill. If a named skill will not
load, stop and say which one failed. Never simulate its output.

## Commands

| Command | What it does |
| --- | --- |
| `/mission <request>` | Start a mission, or attach to the matching one |
| `/mission continue` | Read the mission, verify references, name the next step |
| `/mission status` | Show the state: from the record, or from the conversation before the gate |
| `/mission handoff` | Force a handoff prompt at the current boundary |
| `/mission done` | Close a mission whose PRs are merged |

## Start

1. Read `AGENTS.md`, the tracker doc, and `router`.
2. Classify the scope with the table below.
3. Find an existing work item in the configured tracker. Do not create or update
   the mission record before the first gate, except for a wayfinder map, which is
   the fog path's decision artifact and is created by `wayfinder` before its
   decision gates. Until the owner approves, the conversation holds the state for
   every other scope. After approval, create or claim the one work item issue
   (see The record).
4. Load the grill. Call the Skill tool for `grilling`, and for
   `domain-modeling` when the repo has `GLOSSARY.md` or `docs/adr/`. When the
   work is a full architecture pass, also load `improve-codebase-architecture`.
5. Run the survey and the grill. When the work is a full architecture pass, run
   the survey first and carry its report and candidate index into the grill. The
   grill builds the fact base, asks the question frontier, and ends when the
   owner confirms shared understanding. When an existing spec, ticket, or direct
   instruction already holds the understanding, run a short grill to confirm the
   question frontier is empty and record that source. Do not write a round from
   a summary.
6. For a fog, load `wayfinder` and work the map until every decision ticket is
   resolved, across sessions as needed. The map is the record. Then load `to-spec`
   and draft the spec. For a feature, load `to-spec` and draft the spec. The spec
   is a proposal until the gate. Do not publish the spec or create a second
   tracker record yet.
7. Present the phase-boundary gate: the problem, the constraints, the rule
   changes, the file scope, the flow, the frontier, its stack order, its cap,
   and what implementation unlocks. For a feature or a fog whose decisions are
   resolved, present the spec with the scope: the solution, the user stories,
   the implementation decisions, the testing seams, and what is out of scope.
   The spec is the gate document. If a fog still has an open decision, return to
   `wayfinder`. Wait for the owner's words when a gate is presented.
8. After the owner's approval, create or claim the one work item issue, or use
   the fog map, and write the record from `./mission-template.md`. When claiming
   an existing issue, keep its problem statement and add the record sections;
   never replace the report. A feature's record is the spec: publish the approved
   spec and add the record sections to that issue. A fog's record is the map:
   publish the spec as a separate issue and link it from the map. A change or bug
   uses its issue; a trivial may use its issue or the PR. Never create a separate
   `Mission:` issue. Update the record only at a boundary.
9. Route by scope. A change, bug, or trivial goes to `implement`. A feature or
   fog goes to `to-tickets`, then the crew chief. A frontier of one ticket uses
   `implement`; a frontier of two or more uses `implement-spec`. Do not implement
   a proposal.

The gate opens after the grill, not before it. The owner cannot approve an
understanding that does not exist yet. On a feature or fog, the gate also opens
after the spec draft, so the scope and the written design are approved together.
Why: the prior flow recorded a scope approval before the questions were answered,
and the record looked legitimate while the understanding was empty.

## The grill

`grilling` owns the round format, the question frontier, and the wait.
`domain-modeling` owns the glossary and the ADRs. `mission` owns the gate: when
the grill opens, what it produces, and whether a short grill is enough. Load
`grilling`, and `domain-modeling` when the repo has docs, before the first
round.

The depth comes from the question frontier, not from the scope. A clear bug may
need one question about the repro and the expected behavior. A foggy idea may
need many rounds. The grill is part of the process at every scope, and the owner
answers the questions inside the mission.

`domain-modeling` writes only what clears its bar: resolved terms in
`GLOSSARY.md`, and ADRs for decisions that are hard to reverse, surprising, and a
real tradeoff. A short grill can write nothing.

## Scope paths

Wayfinder is for fog, not size. A clear but large feature goes through spec and
tickets; a foggy idea goes through the map first. A feature's tickets run as a
frontier: independent tickets from the current base, dependent tickets stacked
by edge.

Ask, in order:

- Is something broken? -> bug.
- Is the destination or a key decision unknown? -> fog.
- Does the work span more than one session or ticket? -> feature.
- Is the change small and clear? -> change.
- Is it one obvious edit? -> trivial.

| Scope | Signal | Entry | Path | Exit |
| --- | --- | --- | --- | --- |
| Fog | destination or key decisions unknown | `wayfinder` plus the grill | map -> decisions -> scope and spec gate -> tickets -> implement-spec | PRs |
| Feature | multi-session, shape known | grill, then `to-spec` | grill -> spec draft -> scope and spec gate -> tickets -> implement-spec | one PR per ticket, stacked by edge |
| Change | one session, clear outcome | grill, then `implement` | grill -> implement | one PR |
| Bug | something broken | `diagnosing-bugs` plus the grill | repro -> issue -> implement | one PR |
| Trivial | one obvious edit | short grill plus the tracker issue | issue -> implement | one PR |

Every path ends at a PR per ticket with `code-review` and `pr`.
The owner reviews and merges.

## Gates

The gates a flow passes depend on its scope. A gate that the scope does not have
is `not used`, never `skipped`. Why: `skipped` implies a gate was bypassed;
`not used` says the path has no such gate. The prior newsletter thread asked the
owner to approve a ticket on a bug because the skill made every gate universal,
and the ticket gate did not exist for that path.

| Scope | Gates |
| --- | --- |
| Fog | decisions, scope and spec, tickets, PR |
| Feature | scope and spec, tickets, PR |
| Change | scope and understanding, PR |
| Bug | scope and understanding (the repro and the fix direction), PR |
| Trivial | scope and understanding (the issue), PR |

A feature has the scope and spec gate and the ticket gate because the spec and
the ticket graph are the design decisions before a multi-session build. The spec
is the gate document, so the scope and the written design are approved once. A
change, bug, or trivial has only the scope and understanding gate and the PR
gate. The issue is the work item, not a separate approval. Why: a one-session
path has no ticket graph to approve, and a ticket gate there stops the work for
no decision.

On a fog path, the decision gates come first. The scope and spec gate then
approves the written design that the decisions produced.

## Gate integrity

A gate is approved only by the owner's own words in the conversation. Nothing
else counts: not a handoff prompt, not the mission document, not a tracker
status, not an agent summary. If the words do not clearly approve the named
gate, stop and ask. Why: the agent writes the record, so a record can only check
the agent against itself.

The agent never writes an approval on the owner's behalf. It records the
decision, the date, and the gate the decision answered. It never reproduces the
owner's words and never names who decided. The record is a status, not evidence;
the conversation is the evidence, and a new session asks again. Why: a false
approval record hides the skipped gate, and a quote turns one message into
durable authority.

## Neutral writing

Never reproduce the user's words directly in an artifact, and never mention the
user. State decisions in neutral, general language. Do not name who decided.
The record is current state only: no prior attempts, prior sessions, prior
issues, prior missions, or earlier versions. This applies to every artifact: the
record, issues, comments, PR bodies, commits, specs, tickets, ADRs, handoffs,
reviews, and replies. Why: a quote or a name turns one message into durable text
the next session can read as authority, and history invites a settled decision to
reopen.

The approved scope is the rule changes and the file scope. State them at the
level the change needs: a list for a small change, a pattern plus exceptions for
a large one. The plan's length follows the number of decisions, not the number of
files. Why: a per-file list for a large change is unreadable, and the PR is the
detailed review.

A change, bug, or trivial has one approval at the phase boundary and one at the
PR. The phase boundary is the end of the grill, when the rule changes and the
file scope are known. The PR is the second approval. A feature adds the scope and
spec gate and the ticket gate before the build. The spec is the gate document, so
the scope and the written design are one decision. Why: per-file approval is a
chore, not a gate, and a record check cannot replace the owner.

A gate found skipped reopens. Stop the build, correct the record, and ask the
owner at the gate. Do not apologize and continue; the next action is the gate,
not a new artifact. Why: a new artifact looks like progress and buries the
missing decision.

## Phase contracts

| Phase | Skill | Produces | Approval | Next |
| --- | --- | --- | --- | --- |
| Classify | `router` | scope and flow | Scope and understanding | grill |
| Map | `wayfinder` | decision map | Decision gates | spec or research |
| Research | `research` | cited markdown | Scope and understanding | spec or implement |
| Architecture survey | `improve-codebase-architecture` | HTML report and candidate index | Scope and understanding | grill |
| Grill | `grilling` and `domain-modeling` with docs; `grilling` without | shared understanding, GLOSSARY, ADR when warranted | Scope and understanding | spec or implement |
| Prototype | `prototype` | answer to a runnable question | Scope and understanding | spec or implement |
| Spec | `to-spec` | spec draft | Scope and spec | tickets |
| Tickets | `to-tickets` | tickets with blocking edges and surface ownership | Tickets | implement or implement-spec |
| Implement | `implement` for one ticket, `implement-spec` for the frontier | code and PRs, one per ticket, stacked by edge | PR | code-review |
| Review | `code-review` | Standards and Spec findings | PR | fix or PR |
| PR | `pr` | PR body, evidence, merge danger | PR | owner review and merge |
| Handoff | `handoff` | next-session prompt | Current gate | new session |
| Done | none | merged PRs | none | close the mission |

The grill phase loads the two skills that `grill-with-docs` wraps. The wrapper
remains the standalone shortcut for a user who wants to start a grill outside a
mission.

The approval column names the gate the phase's output feeds, not the immediate
next row. On a feature or fog, the scope and understanding approval joins the
spec at the scope and spec gate; on a change, bug, or trivial, the scope and
understanding gate is the first gate. The spec is drafted before the combined
gate and published after approval. The ticket graph is cut only after it. Why:
the spec is the gate document, and a ticket graph cut from an unapproved spec
multiplies the unapproved decision.

Optional detours: `research` when facts are missing,
`improve-codebase-architecture` when the work is a full architecture pass,
`prototype` when a question needs runnable code,
`domain-modeling` when a decision is hard to reverse,
`diagnosing-bugs` when the cause is unclear.

## The session plan

The record holds the session plan once the gate is approved. Before the gate,
the plan stays in the conversation. A feature plans work per frontier, not per
ticket; a bug or a change has one frontier. The current session carries the
next frontier when the context holds. The plan is a table in the record:

| Session | Work | Exit |
| --- | --- | --- |
| 1 | classify, grill, draft the spec and cut the tickets on a feature or fog, present the gate | the design gate decisions |
| 2 | implement the frontier as a stack (up to the cap), review each PR | the stack's PRs are open; the owner merges |
| 3 | after merges unblock it, implement the next frontier | the next stack's PRs are open |

A session is a context boundary, not a phase boundary. The mission session runs
the build with `implement` for one ticket or `implement-spec` workers for a
frontier. Hand off only when the context is full, the work moves to a new
directory or harness, a side task needs its own context, or the owner asks. Why:
a phase change in the same context does not need a copied prompt or a new
approval.

For a change, bug, or trivial, session 1 stops at the scope and understanding
gate. There is no spec draft and no ticket step. Row 3 is conditional: start a
new session only when the current context cannot carry the next frontier.

A frontier of one ticket is the single-ticket path. The cap is the maximum, not
a target; a frontier of two runs two. If the owner changes the cap, record it in
the record's Decisions. Why: the cap is a mission decision, and the next session
reads the record, not this message.

Replan when the scope changes. The owner sees the whole flow and where the
handoffs fall before the work starts.

## Handoff boundaries

`mission` hands off at the planned boundary without waiting for the
`/mission handoff` command. A boundary is a place where the work travels or the
current context cannot carry it, not a phase change:

- the context is nearly full;
- a side task needs its own context;
- the next phase runs in a different harness or directory;
- the owner asks for a fresh session;
- the next frontier cannot fit in the current context.

The build does not need a handoff. The mission session loads `implement` for one
ticket or `implement-spec` for a frontier. For a frontier, it acts as the crew
chief: it claims the tickets, spawns one worker per ticket, reviews each PR, and
reports the stack. A handoff is for travel, not for a phase change. If the
harness cannot isolate checkouts, run the tickets one at a time in the same
session and say so. Why: a fresh session forces a copied prompt and a new gate
confirmation, and the workers already provide the context isolation.

At the boundary:

1. If the record exists, update the phase, gates, frontier, and session plan. If
   the gate is still pending, keep the state in the prompt, including the ledger
   and open questions, and do not create a record.
2. Generate the prompt with the `handoff` contract.
3. Deliver one fenced `text` block in the chat. That is the only copy of the
   prompt. Never put the delivered prompt in an issue, a PR, a commit, the repo,
   or the mission document. The record keeps no log entry.
4. Stop editing. The new session starts with `/mission continue`.

An approval does not carry on its own. The new session presents the gate with
its recorded status and waits for the owner's words. The owner may confirm the
earlier decision in their own words; the agent never assumes it. Why: a prompt
written by the agent cannot grant authority, and an exception in the prompt is
still the agent's words. The handoff reports the gate, it never grants it.

A mission stays in one session while the context holds. Handoff is for travel: a
new session, a new directory, a new harness, a side task, or a frontier the
current context cannot carry. A phase change in the same context stays in the
session.

## The handoff prompt

The prompt is self-contained:

- the work item issue title and team, not its id or URL, or that no record
  exists yet and must not be created before the gate;
- the goal, why this work is next, and what it unlocks;
- the base commit, the stack order, the open PRs, and the next frontier in plain
  words, plus the blocking edges after it;
- the current gate, its method, and whether it is approved or pending, stated
  neutrally and never with the words or the name of the person who decided;
- the current state only, with no prior attempts, sessions, issues, or versions;
- the approved rule changes and the file scope;
- the skills to load, in order;
- the references for that phase;
- the build and check commands;
- the output contract for the next session;
- the exit: open one PR per ticket, stacked by edge; run `code-review` on each
  and fix the findings; report the stack bottom-up with each PR URL, check
  state, what changed, what it unlocks, and the merge danger. The owner merges
  bottom-up.

A starting shape:

```text
Find the work item issue in team <team> by its title: <title>. Run /mission
continue. The goal is <goal>. The current gate is <gate>, <approved or
pending>, reached with <method>. The approved rule changes are <list or
pattern>. The file scope is <list or pattern>, and <what is out> is out.
The open PRs are <urls>, in merge order <...>, or no PR is open yet. The base
commit is <sha>. The next frontier is <plain name>: <why it is next, and what it
unlocks>. Its tracking key is in the mission document.
Read the mission references for <phase>, then load <skills> in order with the
Skill tool. If a skill will not load, stop and say which one, and do not
simulate its output.
Run <checks>. Open one PR per ticket, stacked by edge. Run code-review on each.
Report the stack bottom-up: each PR URL, check state, what changed, what it
unlocks, and the merge danger. Name the next frontier in plain words. The owner
reviews and merges bottom-up.
```

Write the prompt in the owner's language. The `mission` skill owns the decision
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

The `research` output, the `improve-codebase-architecture` report and candidate
index, and the `domain-modeling` ADRs are references. The handoff prompt carries
the work item issue title and team, plus the next phase's top references.

## Output contract

The reply is the answer, not a status report. The mission document holds the
state; read it, and write it only at a boundary. Do not repeat it in every
reply.

- Put the answer first, and name the work in plain words.
- Do not open with a progress trail, mission name, gate, or labeled reasoning.
  Explain the why in the body when it helps the decision.
- Do not put a ticket id, mission id, issue key, or tracker link in a reply.
  Give one only when the owner asks for it. Those keys belong in the mission
  document, the tracker, the branch, the commit, and the PR body.
- When the owner must act, end with one plain sentence:
  `Next step: <the action>`. Do not add a trail, a gate block, or repeated
  context around it.
- The full state, the why, the unlock, and the gate belong in the handoff
  prompt, when the work moves to a new session, a new thread, or another agent.
  That is where context is lost. The handoff prompt is the one place that
  carries the mission state; it names the work item issue by title and team, not
  by id or URL.

When the reason for a step is not in the mission, the ticket, the spec, or the
code, stop and ask the owner. Record the answer in the record's Decisions at the
next boundary, not after every reply. Never invent a rationale. A next skill is
a load, not a phase to perform.

At a pending gate, the reply presents the decision and the recommendation. The
gate opens only on a clear decision in the conversation. If the decision is
ambiguous, stop and ask. Do not reproduce the words or name who decided in any
artifact. There is no template sentence. Why: a template turns the approval into
a password and moves the authority back to the agent.

At a PR, report the PR URL, the check state, what changed, what it unlocks, and
the merge danger. At a stack, report each PR and the merge order, bottom-up. The
head SHA stays in the PR.

## Pushback

When the owner challenges a finding, a recommendation, or a fact, name the
claim and its check before you reply.

1. State the claim in one line: what is being challenged and what it rests on.
   A claim about the owner's position points to the owner's message; no source,
   no claim. Why: an invented position turns one message into an argument the
   owner never made.
2. Name the check. A check is evidence that can fail: a command, a test, a doc
   line, a repro, or a measurement against an agreed threshold. If you cannot
   name one, the claim is a preference or a reversible judgment. Why: a named
   check is the difference between a fact and a mood.
3. A failed check stops the work. Show the check, keep the finding, and say what
   would change it. A direct instruction does not resolve a failed check; only a
   new fact, a changed check, or a fix does. Why: an instruction cannot make a
   failing check pass.
4. A preference or a reversible judgment has no check. The owner decides it.
   State the tradeoff once, then follow the instruction. Why: the owner owns the
   decision, the agent owns the facts.
5. When the challenge adds a new fact, a new constraint, or a real error, change
   the position and name what changed it. Keep the parts that were right; do not
   collapse the whole position because one detail was wrong. Why: changing
   without a fact is folding; changing with one is correcting.
6. Never open with "You're right" or an apology. Agreement needs a reason. Tone
   is not evidence. One sentence for a real error, then the correction. Why:
   agreement without a reason hides whether the claim was checked.

Why: a model reads disagreement as evidence and folds, which turns the owner's
first guess into the final answer.

## Handback

A ticket ends with a reviewable PR. In a frontier, the crew chief opens one PR
per ticket, stacked by blocking edge. The mission session is the crew chief;
`implement-spec` spawns the workers. Run `code-review` on each and fix the
findings. Report the stack bottom-up: each PR URL, check state, what changed,
what it unlocks, and the merge danger. Name the next frontier in plain words.
The head SHA stays in the PR. The owner reviews and merges bottom-up. A ticket
starts when its blockers' branches have the interface it needs, not when the
whole stack merges. When the owner asks the mission skill to merge, use a merge
commit.

## Recovery

When a gate is found skipped, the next action is the gate, not an artifact.

1. Stop the build and stop adding files.
2. Correct the record: remove any approval the owner did not give, record the
   decision and date, or mark the gate pending.
3. Make any artifact produced before the gate a draft or a proposal.
4. Rebuild the fact base: the surface inventory and the prior decisions.
5. Ask the whole question frontier once, with the round ledger.
6. Wait for the owner's words at the gate.

Do not ask the owner whether to continue. State the gate and wait. Why: asking
whether to continue moves the decision back to the owner without a document to
approve, and the prior session used that question to keep working.

## The record

Use the configured tracker. Linear: `rata` creates and updates the work item
issue and the wayfinder map. GitHub: `gh` creates the issue and the PR. If no
tracker is configured, stop and ask the owner to set one up.

One record per mission. The mission document is the work item issue: the bug or
change issue, the spec, or the map. A trivial may use its issue or the PR. Never
create a separate `Mission:` issue. Why: a second issue duplicates the work item
and doubles the writes.

Create or claim the record after the first gate. Before the gate, the
conversation holds the problem, the grill ledger, and the open questions. A
wayfinder map is the exception: `wayfinder` creates it before its decision gates
because the map is the fog path's decision artifact. Why: the owner has not
approved the work yet, and a record created at Start keeps changing through the
grill.

The record is a snapshot, not a diary. Write it at the gate, at a handoff, on a
scope change, or when a false record would mislead. Do not comment after each
decision, session, or PR state. The PR carries its own status. Why: an update
after every small decision buries the current state and makes the owner re-read
the history.

The record is current state only. No prior attempts, prior sessions, prior
issues, prior missions, or earlier versions. The record keeps the frontier in
the session plan, the concurrency cap in the decisions, and the flow, gates,
references, settled decisions, rejected options, outputs, and next step. It
keeps no handoff log and never the prompt itself. Why: a log is history, and
history invites a settled decision to reopen.

## Scope changes

A mission can move between scopes. If a phase reveals fog, add a wayfinder or
research detour. If the fog clears and the work collapses, reduce the flow to
a change or a bug. If the work grows past one session, reclassify to a feature
and add the scope and spec gate and the ticket gate. Update the record to the
current scope, gates, frontier, and next step. Do not narrate the old scope or
the reason for the change. Why: the record is current state only.

When the owner explicitly chooses one PR for work that is larger than one
session, record that choice and keep the change path. The owner owns the review
size; the agent does not silently grow the PR.

## It is working if

- The grill runs at every scope, and its depth follows the question frontier.
- Every phase starts with its skill loaded, and a missing skill stops the
  session instead of producing a substitute.
- Every gate is approved by the owner's words, recorded with its decision and
  date, or marked `not used` when the scope does not have it.
- A feature approves the scope and the spec at one gate, and the ticket gate
  follows before the build.
- No mission record exists before the first gate, except a fog map, and the
  record is updated only at a boundary, never after each decision.
- No artifact reproduces words from the conversation, names who decided, or
  carries history of the issue or mission.
- The approved scope is the rule changes and the file scope, not a per-file
  click.
- The reply starts with the answer, and the mission document plus the handoff
  carry the state and the why.
- A fresh session resumes from the mission document, or from the handoff prompt
  before the gate, without re-explaining, and it asks again at a pending gate.
- Every load-bearing reference is a path or URL in the mission, and stale
  references are flagged at session start.
- Each ticket in a frontier ends at a PR with `code-review`, the stack is
  reported bottom-up, and the owner merges bottom-up.
- The flow computes the frontier at every phase and runs up to the cap, or says
  why the work is sequential.
- The mission session runs the build with `implement` or `implement-spec`, and a
  handoff happens only for travel or a full context.
- A handoff prompt appears in chat at the planned boundary, reports the gate
  status, and never grants it.
