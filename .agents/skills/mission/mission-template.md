<!--
This is the work item issue, not a separate mission issue. Create or claim it
after the first gate. A fog map is created by `wayfinder` before its decision
gates and becomes the record; use the map body and add the gate status and next
step there.

Neutral language: never reproduce words directly, never mention the user, never
name who decided, and never add history. State decisions in neutral, general
language.

Update cadence: write at the gate, at a handoff, on a scope change, or when a
false record would mislead. Do not comment after each decision, session, or PR
state. The PR carries its own status.
-->

# <title>

Status: active
Scope: fog | feature | change | bug | trivial
Phase: classify
Goal: <one sentence>
Exit: PRs for review and merge

## Problem

<the failure or the need in plain terms. Link the source. Do not restate the whole report. Do not add history.>

## Flow

- [ ] grill: <rounds, ledger, source>
- [ ] map: <url>
- [ ] decisions: <adr or issue>
- [ ] spec: <issue or URL>
- [ ] tickets: <urls>
- [ ] implement <ticket or frontier>: <PR urls>
- [ ] code-review <PR or stack>: <findings>
- [ ] merge <PR or stack>: <commit>

## Gates

The gates depend on the scope. Use `not used` for a gate the scope does not have.
Never use `skipped`.

| Gate | Method | Document | Status | Date |
| --- | --- | --- | --- | --- |
| Decisions | wayfinder | <map> | <pending or not used> | |
| Scope and spec | <grill and spec draft> | <spec or notes> | pending | |
| Tickets | decision | <tickets or issue> | <pending or not used> | |
| PR | code-review | <PR> | pending | |

`Status` is `pending`, `approved`, or `not used`. Set the decisions gate to
`pending` for fog and `not used` for every other scope. For a fog, add one
Decisions row per decision gate, or record each gate in the map. On a feature or
fog path, the scope and spec gate is one row: the spec is the document, and the
scope and the written design are approved together. On a change, bug, or trivial, rename
that row to `Scope and understanding` and leave the spec out of the document. Set
the ticket gate to `pending` for a feature or fog and `not used` for every other
scope. Record the date of the decision. Never reproduce the words or name who
decided. Why: the merge is the approval, and the agent writes the record, so a
record can only check the agent against itself.

## Session plan

| Session | Work | Why | Exit |
| --- | --- | --- | --- |
| 1 | classify, grill, draft the spec and cut the tickets on a feature or fog, present the gate | the design gates decide the path | the gate decisions |
| 2 | implement the frontier as a stack (up to the cap), review each PR | the gates are approved | the stack's PRs are open; the owner merges |
| 3 | after merges unblock it, implement the next frontier | the merges unblocked it | the next stack's PRs are open |

For a change, bug, or trivial, the frontier is one ticket; use one implement
row, and stop session 1 at the scope and understanding gate. There is no spec or
ticket step. Row 3 is conditional: start a new session only when the current
context cannot carry the next frontier. A session is a context boundary, not a
phase boundary. The mission session runs the build with `implement` for one
ticket or `implement-spec` workers for a frontier. Hand off only when the context
is full, the work moves to a new directory or harness, a side task needs its own
context, or the owner asks. Replan when the scope changes. The whole flow and the
handoff points are visible before the work starts. Do not narrate the old scope.

## References

| Reference | Why | Path or URL | Phase |
| --- | --- | --- | --- |

Check each path or URL at session start. Mark a stale entry with `stale: <what
changed>`. Why: a missing reference costs the next session its first round.

## Decisions

Record the settled decisions only. The grill ledger and open questions stay in
the conversation until the gate. Why: a record written after every answer is a
diary, and it buries the state the next session needs.

- <decision>. Why: <why>. Alternative: <rejected alternative, or "no alternative: <reason>">. Status: settled. Record: <ADR or issue>.

State the decision, the reason, and the rejected alternative. Do not name who
decided. A decision without a clear answer is not recorded; it stays in the
conversation and keeps the gate open. Do not add the history of how the decision
was reached.

## Rejected options

- <option>: <reason>. Do not re-offer.

Why: a rejected option that is not written down comes back in the next round.

## Outputs

- spec: <issue or URL>
- tickets: <urls>
- PRs: <urls>

## Follow-ups

- <next mission or none. Why: it was requested, or the work is out of scope.>

## Next step

- Skill to load: <skill>
- Gate: <gate>
- Method: <method>
- Why: <why this step is next>
- Unlocks: <what it makes possible>
- Command: <exact command>
- Produce: <output>

The prompt is delivered in chat and never pasted into this document. This
record keeps no handoff log.
