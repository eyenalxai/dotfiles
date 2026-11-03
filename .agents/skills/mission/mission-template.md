# Mission: <title>

Status: active
Scope: fog | feature | change | bug | trivial
Phase: classify
Goal: <one sentence>
Exit: PR for owner review and merge

## Problem

<the failure or the need in the owner's terms. Link the source. Do not restate the whole report.>

## Flow

- [ ] grill: <rounds, ledger, source>
- [ ] map: <url>
- [ ] decisions: <adr or issue>
- [ ] spec: <issue or URL>
- [ ] tickets: <urls>
- [ ] implement <ticket>: <PR url>
- [ ] code-review <PR>: <findings>
- [ ] owner merge <PR>: <commit>

## Gates

The gates depend on the scope. Use `not used` for a gate the scope does not have.
Never use `skipped`.

| Gate | Method | Document | Status | Approved by | Date | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| Scope and understanding | <grill method> | <notes or map> | pending | | | |
| Spec | owner review | <spec or issue> | <pending or not used> | | | |
| Tickets | owner review | <tickets or issue> | <pending or not used> | | | |
| PR | code-review | <PR> | pending | | | |

`Status` is `pending`, `approved`, or `not used`. Set the spec and ticket gates
to `pending` for a feature and `not used` for every other scope. `Evidence` holds
the owner's exact words and the decision they answered. A quote is a log, not
proof; the owner's merge is the approval. Why: the agent writes the record, so a
record can only check the agent against itself.

## Session plan

| Session | Work | Why | Exit |
| --- | --- | --- | --- |
| 1 | classify, grill, choose the path, present the gate | the scope and the frontier decide the path | the owner's words at the gate |
| 2 | implement the approved rule changes and file scope, review, PR | the gate is approved | PR for owner review and merge |

Replan when the scope changes. The owner sees the whole flow and where the
handoffs fall before the work starts.

## References

| Reference | Why | Path or URL | Phase |
| --- | --- | --- | --- |

Check each path or URL at session start. Mark a stale entry with `stale: <what
changed>`. Why: a missing reference costs the next session its first round.

## Decisions

Record every decision with its source and its status.

- <decision>. Why: <why>. Alternative: <rejected alternative, or "no alternative: <reason>">. Decided by: owner | engineering | pending. Status: settled | proposed. Record: <ADR or issue>.

A decision the owner made is `owner` and is settled. A decision the agent made
inside the approved scope is `engineering`. A decision the owner has not answered
is `pending` and keeps the gate open. Why: the prior record labelled agent
choices as owner decisions, and the gate looked approved.

## Rejected options

- <option>: <reason>. Do not re-offer.

Why: a rejected option that is not written down comes back in the next round.

## Open questions

- <question>: <the decision it settles>. Recommendation: <answer>. Status: open | answered.

## Outputs

- spec: <issue or URL>
- tickets: <urls>
- PRs: <urls>

## Follow-ups

- <next mission or none. Why: the owner asked for it, or the work is out of scope.>

## Next step

- Skill to load: <skill>
- Gate: <gate>
- Method: <method>
- Why: <why this step is next>
- Unlocks: <what it makes possible>
- Command: <exact command>
- Produce: <output>

## Handoff log

- <date and time>: <session>, <phase>, <gate>, <method>, PR <url>, head <sha>, prompt delivered in chat

Never paste the prompt anywhere in this document. The prompt is delivered in
chat.
