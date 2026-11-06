<!--
This is the work item issue, not a separate mission issue. Create or claim it
after the scope gate.

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
Exit: PR for review and merge

## Problem

<the failure or the need in plain terms. Link the source. Do not restate the whole report. Do not add history.>

## Flow

- [ ] grill: <rounds, ledger, source>
- [ ] map: <url>
- [ ] decisions: <adr or issue>
- [ ] spec: <issue or URL>
- [ ] tickets: <urls>
- [ ] implement <ticket>: <PR url>
- [ ] code-review <PR>: <findings>
- [ ] merge <PR>: <commit>

## Gates

The gates depend on the scope. Use `not used` for a gate the scope does not have.
Never use `skipped`.

| Gate | Method | Document | Status | Date |
| --- | --- | --- | --- | --- |
| Scope and understanding | <grill method> | <notes or map> | pending | |
| Spec | decision | <spec or issue> | <pending or not used> | |
| Tickets | decision | <tickets or issue> | <pending or not used> | |
| PR | code-review | <PR> | pending | |

`Status` is `pending`, `approved`, or `not used`. Set the spec and ticket gates
to `pending` for a feature and `not used` for every other scope. Record the date
of the decision. Never reproduce the words or name who decided. Why: the merge
is the approval, and the agent writes the record, so a record can only check the
agent against itself.

## Session plan

| Session | Work | Why | Exit |
| --- | --- | --- | --- |
| 1 | classify, grill, choose the path, present the gate | the scope and the frontier decide the path | the gate decision |
| 2 | implement the approved rule changes and file scope, review, PR | the gate is approved | PR for review and merge |

Replan when the scope changes. The whole flow and the handoff points are visible
before the work starts. Do not narrate the old scope.

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
