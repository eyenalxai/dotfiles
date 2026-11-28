<!--
Work item issue (mission document). Create or claim only after the first gate.
Exception: on a Fog path, wayfinder creates the map before decision gates and
that map becomes the record; add gate status and next step to the map body.

Rules:
- Neutral language only: never quote conversation words or name who decided.
- Current state only: no history, prior attempts, prior sessions, or handoff log.
- Snapshot only: update at gates, handoffs, scope changes, or to fix errors.
-->

# <title>

Status: active
Scope: fog | feature | change | bug | trivial
Phase: classify
Goal: <one sentence>
Exit: PRs for review and merge

## Problem

<The failure or need in plain terms. Link the source. No history.>

## Flow

- [ ] grill: <rounds, source>
- [ ] map: <url>
- [ ] decisions: <adr or issue>
- [ ] spec: <issue or url>
- [ ] tickets: <urls>
- [ ] implement <ticket or frontier>: <PR urls>
- [ ] code-review <PR or stack>: <findings summary>
- [ ] merge <PR or stack>: <commit>

## Gates

Keep only the rows for this scope (mark any excluded gate `not used` if shown, never `skipped`). Status is `pending`, `approved`, or `not used`.

| Scope | Gate | Method | Document | Status | Date |
| --- | --- | --- | --- | --- | --- |
| Fog | Decisions | wayfinder | <map> | pending | |
| Fog | Scope and spec | grill and spec draft | <spec> | pending | |
| Fog | Tickets | ticket graph review | <tickets> | pending | |
| Fog | PR | code-review and merge | <PR> | pending | |
| Feature | Scope and spec | grill and spec draft | <spec> | pending | |
| Feature | Tickets | ticket graph review | <tickets> | pending | |
| Feature | PR | code-review and merge | <PR> | pending | |
| Change | Scope and understanding | grill | <issue> | pending | |
| Change | PR | code-review and merge | <PR> | pending | |
| Bug | Scope and understanding | grill and repro | <issue> | pending | |
| Bug | PR | code-review and merge | <PR> | pending | |
| Trivial | Scope and understanding | short grill and issue | <issue> | pending | |
| Trivial | PR | code-review and merge | <PR> | pending | |

## Session plan

| Session | Work | Exit |
| --- | --- | --- |
| 1 | Classify, grill, draft spec and cut tickets (Feature/Fog), present gate | Gate decision |
| 2 | Implement the frontier (cap 10, stacked by edge), review each PR | Stack PRs open for bottom-up merge |
| 3 | (Only if context cannot carry next frontier) Run next unblocked frontier | Next stack PRs open |

Default concurrency cap is 10. Record any override in Decisions. For Change, Bug, or Trivial, session 1 stops at the scope and understanding gate and there is no spec or ticket step.

## References

| Reference | Why | Path or URL | Phase |
| --- | --- | --- | --- |

Verify at session start; mark broken entries `stale: <what changed>`.

## Decisions

Settled decisions only (grill ledger stays in chat until the gate).

- <decision>. Why: <reason>. Alternative: <rejected option, or "no alternative: <reason>">. Status: settled. Record: <ADR or issue>.

## Rejected options

- <option>: <reason>. Do not re-offer.

## Outputs

- spec: <issue or url>
- tickets: <urls>
- PRs: <urls>

## Follow-ups

- <next mission or none: why>

## Next step

- Skill to load: <skill>
- Gate: <gate>
- Method: <method>
- Why: <why this step is next>
- Unlocks: <what it makes possible>
- Command: <exact command>
- Produce: <output>
