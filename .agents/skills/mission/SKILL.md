---
name: mission
description: Drive one piece of work from a request to reviewable pull requests. Classifies the scope, runs the grill and the owner's approval gates, keeps a durable mission document, names the next skill, tracks references across sessions, and hands off automatically when the work travels.
argument-hint: "<request> | continue | status | handoff | done"
disable-model-invocation: true
---

# Mission

Single entry point for a piece of work: from raw request through grilling, design, implementation, and review, ending at one reviewable PR per ticket.

Every skill named here is a file to load with the Skill tool before producing its output; summaries here are orientation only. If a skill fails to load, stop and name it. Never simulate its output.

## Commands

| Command | Action |
| --- | --- |
| `/mission <request>` | Start a mission or attach to the matching active one |
| `/mission continue` | Read the record, verify references, execute or name the next step |
| `/mission status` | Report current state from the record (or conversation before the first gate) |
| `/mission handoff` | Generate a handoff prompt at the current boundary |
| `/mission done` | Close a mission once all PRs are merged |

## Scope classification

Walk this tree in order. Wayfinder is for uncertainty, not size.

```text
Is something broken?
├── Yes → Bug
└── No
    ├── Is the destination or a key decision unknown?
    │   ├── Yes → Fog
    │   └── No
    │       ├── Does the work span more than one session or ticket?
    │       │   ├── Yes → Feature
    │       │   └── No
    │       │       ├── Is it one obvious edit?
    │       │       │   ├── Yes → Trivial
    │       │       │   └── No  → Change
```

| Scope | Entry skills | Path | Gates | Exit |
| --- | --- | --- | --- | --- |
| **Fog** | `wayfinder`, `grilling`, `domain-modeling` | map, decision gates, `to-spec` draft, scope and spec gate, `to-tickets`, build | Decisions, Scope and spec, Tickets, PR | One PR per ticket, stacked by edge |
| **Feature** | `grilling`, `domain-modeling` | grill, `to-spec` draft, scope and spec gate, `to-tickets`, build | Scope and spec, Tickets, PR | One PR per ticket, stacked by edge |
| **Change** | `grilling`, `domain-modeling` | grill, scope and understanding gate, `implement` | Scope and understanding, PR | One PR |
| **Bug** | `diagnosing-bugs`, `grilling`, `domain-modeling` | repro + grill, scope and understanding gate, `implement` | Scope and understanding, PR | One PR |
| **Trivial** | `grilling` (short) | short grill, scope and understanding gate, `implement` | Scope and understanding, PR | One PR |

Any gate that does not belong to the scope is marked `not used`, never `skipped`. When the owner explicitly chooses one PR for multi-session work, record that choice and stay on the Change path; never silently grow a PR.

Optional detours: `research` (missing facts), `improve-codebase-architecture` (full architecture pass, run before the grill and carry its plan/index in), `prototype` (question needs runnable code).

## Start procedure

1. **Orient.** Read `AGENTS.md` and the tracker doc. Check the configured tracker for an existing matching issue.
2. **Classify** with the scope tree above. Do **not** create or update a mission record yet. The one exception is a Fog path, where `wayfinder` creates its map before decision gates.
3. **Grill.** Load `grilling` and `domain-modeling` (plus `diagnosing-bugs` for a Bug, or `improve-codebase-architecture` for a full architecture pass). Even when a spec or issue already exists, run a short grill to confirm the question frontier is empty.
4. **Draft design (Feature / Fog).**
   - On Fog: load `wayfinder` and resolve every decision ticket first; the map is the record.
   - Load `to-spec` and draft the spec in conversation as a proposal. Do not publish it yet.
5. **Present the first gate and stop.**
   - Change / Bug / Trivial: present the problem, constraints, rule changes, file scope (list for small changes, pattern plus exceptions for large ones), flow, and what implementation unlocks.
   - Feature / Fog: present the scope together with the spec draft (solution, user stories, implementation decisions, testing seams, out of scope).
   - Wait for the owner's words. An understanding that does not exist yet cannot be approved, and cutting tickets from an unapproved spec multiplies unapproved decisions.
6. **Write the record after approval.** Use `./mission-template.md`.
   - One record per mission: the work item issue itself (the bug/change issue, the published spec on a Feature, or the map on a Fog with the published spec linked from it; a Trivial may use its issue or the PR). Never create a separate `Mission:` issue.
   - When claiming an existing issue, append the record sections without overwriting the original report.
7. **Route the build.**
   - Change, Bug, Trivial, or a 1-ticket frontier: load `implement`.
   - Feature or Fog after `to-tickets` and the Tickets gate, with 2+ ready tickets: load `implement-spec` (mission session acts as crew chief, spawns up to 10 subagent workers stacked by blocking edge, reviews each PR, reports bottom-up).

## Phase contracts

| Phase | Skill | Produces | Feeds gate |
| --- | --- | --- | --- |
| Classify | `mission` | Scope and flow | Scope and understanding |
| Map | `wayfinder` | Decision map | Decision gates |
| Architecture survey | `improve-codebase-architecture` | Plan and candidate index | Scope and understanding |
| Research | `research` | Cited markdown | Scope and understanding |
| Grill | `grilling`, `domain-modeling` | Shared understanding, glossary, ADRs | Scope and understanding |
| Prototype | `prototype` | Answer to a runnable question | Scope and understanding |
| Spec | `to-spec` | Spec draft (published after approval) | Scope and spec |
| Tickets | `to-tickets` | Ticket graph with surface ownership and edges | Tickets |
| Build | `implement` (1) or `implement-spec` (2+) | Code and PRs, one per ticket, stacked by edge | PR |
| Review | `code-review` | Standards and Spec findings | PR |
| PR | `pr` | PR body, evidence, merge danger | PR |
| Handoff | `handoff` | Next-session chat prompt | Current gate |

## Gates and recovery

- **Owner words only.** A decision gate opens only on the owner's clear words in the current conversation. The PR gate opens on merge. Never infer approval from a handoff prompt, mission record, tracker status, or agent summary; the agent writes those records, so they cannot authorize the agent.
- **No quotes, no decider names, no history.** In every artifact (record, issues, comments, specs, tickets, ADRs, PR bodies, commits, handoffs, reviews), state decisions in neutral, general language and current state only. Quoting or naming who decided turns one message into durable authority; carrying history invites later sessions to re-litigate settled work.
- **Skipped-gate recovery.** If a gate was bypassed, stop building immediately. Remove any unapproved status from the record, downgrade premature artifacts to drafts/proposals, rebuild the fact base, ask the open question frontier once, and wait at the gate. Never ask "should I continue?" and never apologize and keep going.

## Record hygiene and references

- **Snapshot at boundaries only.** Update the record at a gate, at a handoff, on a scope change, or to fix a false record. Never post per-decision comments; the PR carries its own status.
- **Frontier cap.** Default concurrency cap is 10 ready tickets per wave. Never queue a ready ticket behind an unmerged PR when the graph allows it to run or stack. Record any owner-chosen cap override in Decisions.
- **References.** Track every load-bearing path or URL (code, vendor source, API docs, ADRs, research, architecture plans) in the record's References table with reason and phase. Verify each entry at session start and mark broken ones `stale: <what changed>`.
- **Scope changes.** Reclassify cleanly when fog appears, collapses, or grows past one session. Rewrite the record's scope, gates, frontier, and next step to the new current state without narrating the old scope.

## Session boundaries and handoffs

A session is a context boundary, not a phase boundary. Stay in the same session across phases; `implement-spec` workers already isolate parallel ticket contexts. Hand off via `handoff` only when:

- the context is nearly full;
- a side task needs its own context;
- work moves to another directory or harness;
- the owner asks for a fresh session.

At a handoff boundary: update the record (if it exists), deliver the prompt in chat via `handoff` (never in the record), and stop editing.

## Output contract and handback

- **Answer first.** Name the work in plain words. Never open with a status block, progress trail, mission header, or bare tracking key (show keys only if asked; link tracker titles instead).
- **One action line.** When the owner must act, end with one plain sentence: `Next step: <action>`.
- **Missing rationale.** When the why behind a step is missing from the record, spec, ticket, and code, stop and ask instead of inventing one.
- **PR and stack handback.** Report each PR's URL, base (for stacks), check state, what changed, what it unlocks, and merge danger. Report stacks bottom-up in merge order, and name the next frontier in plain words. Keep head SHAs in the PR. If asked to merge, use a merge commit.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
