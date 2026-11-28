# Model audit

Procedures, finding catalog, scan order, ranking scales, and candidate format for `improve-codebase-architecture`. Uses exact terms from [codebase-design](../codebase-design/SKILL.md) (**module**, **interface**, **seam**, **adapter**, **depth**, **leverage**, **locality**) plus model terms (**state**, **state machine**, **lifecycle**, **transition**, **invariant**).

Build the conceptual model before judging structure. A file-level scan spots style; a lifecycle and invariant model spots real bugs across files (unconstrained status columns, check-then-insert races, split totals).

## 1. Lifecycles (state machines)

Scan for entities with states and transition rules:
- `status`, `state`, `phase`, `stage`, `step` columns, fields, or enums
- boolean clusters with illegal combinations (`isActive`, `isVerified`, `isDeleted`)
- phase-implying timestamps (`createdAt`, `paidAt`, `shippedAt`, `expiresAt`)
- queues, jobs, sessions, subscriptions, orders, payments, invitations, drafts
- reducers, webhooks, cron jobs, and event handlers mutating records

For each entity, reconstruct:

| State | Event | Guard | Next state | Side effects | Persistence | Evidence |
| --- | --- | --- | --- | --- | --- | --- |

Answer: implicit states, external vs. internal events, where guards live, whether side effects run inside or after transitions, persistence shape, representable illegal transitions, unreachable legal transitions, and retry/concurrency/out-of-order behavior. Mark undecided edges `unknown`; never invent plausible transitions.

Render one compact Mermaid `stateDiagram-v2` per entity (dashed edges for unknown/unenforced transitions).

Recommend the smallest representation that eliminates illegal states:
1. **Typed state union + pure `transition(state, event)`**: default for in-process logic.
2. **Data transition table + reducer**: when many states exist or the product inspects transitions.
3. **Persisted status + DB check constraint + transaction**: when state lives in a database and transitions carry side effects.
4. **Workflow engine / statechart library**: only for parallel regions, history states, or durable timers.

Every recommendation must name the illegal states removed, illegal transitions rejected, and an acceptance test in one of the three test categories.

## 2. Invariants (assumed facts)

Audit across all ten families: **uniqueness**, **cardinality**, **ordering**, **ownership/tenancy**, **balance/totals**, **temporal**, **referential**, **idempotency**, **concurrency**, **immutability**.

Record every gap:

| Invariant | Where assumed | Current enforcement | Failure mode | Recommended enforcement | Interface change | Evidence |
| --- | --- | --- | --- | --- | --- | --- |

- `Current enforcement`: `type`, `schema`, `database constraint`, `transaction`, `runtime guard`, `test`, `documentation`, or `none`. UI-only checks count as `none` (jobs, webhooks, and other clients bypass UI).
- `Failure mode`: concrete corruption or wrong result, never vague "data inconsistency".
- `Recommended enforcement`: pick the earliest layer that can enforce it, in order: (1) **type** (branded ID, non-empty list, union), (2) **schema** at the API edge, (3) **database constraint** (unique/FK/check/exclusion; app-only checks lose under concurrency), (4) **transaction** (atomic read-modify-write + side effects), (5) **runtime guard**, (6) **test** (detects, does not block production writes).
- If an ADR deliberately accepts a gap, cite the ADR and note the tradeoff rather than flagging a violation. Never invent invariants the code does not assume.

## 3. Abstractions and seams

Check three structural failures using `GLOSSARY.md` terms:
- **Missing**: one concept duplicated across modules that change in lockstep -> consolidate into one deep module.
- **Premature**: interface with one adapter and one caller -> delete the indirection and inline until a second real adapter exists.
- **Leaking**: invariants checked by callers outside the module -> pull enforcement behind the seam.

Resolve glossary mismatches first (two glossary terms mapping to one module, or one term scattered across three shallow modules).

## 4. Finding catalog

Every smell is a heuristic, not an automatic ticket. Promote to a candidate **only** with `file:line` evidence, a concrete failure mode, and a concrete fix (deletion test for deepening, enforcement layer for invariant, transition table for state, inventory for tests):

| Smell | Signal | Cost | Fix shape |
| --- | --- | --- | --- |
| Shallow module | One-call wrappers, pass-through params, single caller | Callers learn wrapper + callee | Collapse into callee or deepen interface |
| Duplicated concept | Repeated validation, permissions, formatting, transitions | Copies drift on change | Single module owns the concept |
| Leaked invariant | Precondition checks at call sites, callers reading flags | New callers bypass the rule | Enforce behind seam at boundary |
| Implicit state machine | Boolean clusters, scattered status comparisons | Illegal states representable; missed side effects | Typed states + pure transition or DB constraint |
| Unenforced invariant | Check-then-act, unconstrained uniques, split totals | Concurrency/caller corruption | Earliest layer: type -> schema -> DB -> tx -> guard |
| Speculative abstraction | Single impl, unused options/hooks | Readers parse dead flexibility | Inline until a second real need |
| Dead module | Unreferenced code, permanently off flags | Maintained dead weight | Delete (git keeps history) |
| Versioned replacement | `V2`/`New` alongside old impl, compat shims | Split behavior; old code rots | Migrate callers, delete old, reclaim name |
| Hidden failure | Silent fallback, swallowed errors | Broken primary path stays green | Fail at boundary or expose degraded state |
| Test gap at seam | Internal mocks, tests bypassing interface | Refactors break tests; public behavior unverified | Test through seam in one of 3 categories |
| Test outside policy | Component snapshots, private-method/call-count tests | Brittle change-detectors | Delete or rewrite to 3 categories |
| Slop mask | Redundant comments, impossible-state checks, `as any` | Hides structural gaps | Fix underlying gap, then run `emil-unslop-code` |

Keep non-structural style issues (naming, comments, logs) out of this report so architectural ranking stays clean.

## 5. Fixed scan order

Walk the codebase in this order on every run so findings are reproducible:

1. **Churn and hot spots:** `git log --name-only --oneline` frequency, import fan-in/fan-out, file size.
2. **State:** lifecycles (section 1).
3. **Invariants:** assumed facts (section 2).
4. **Seams:** shallow/missing/premature/leaking abstractions + deletion test (section 3).
5. **Tests:** full inventory under [TEST-POLICY.md](TEST-POLICY.md).
6. **Structural slop:** only patterns pointing to a module, seam, or invariant.
7. **Rank and sequence:** section 6.

## 6. Ranking and sequencing

Score every candidate on five explicit axes (never collapse into one score that hides risk or blockers):

- **Impact**: `high` | `med` | `low` (call sites collapsed, complexity hidden, test surface unlocked).
- **Confidence**: `high` (verified in code) | `med` (strong signal) | `low` (needs investigation).
- **Effort**: `S` (hours) | `M` (a day) | `L` (multi-day), tests included.
- **Risk**: `LOW` | `MED` | `HIGH` + one-line reason.
- **Dependency**: blocking candidate IDs or `none`.

Sequence by `blocked_by` first, then `impact` (high -> low), `effort` (S -> L), `risk` (LOW -> HIGH). Defer `HIGH`-risk items unless they block other candidates. Expand #1 as the top recommendation and name #2 and #3.

## Coverage table

| Area | Lifecycles audited | Invariants audited | Not audited | Why |
| --- | --- | --- | --- | --- |

Pair with the test inventory summary from [TEST-POLICY.md](TEST-POLICY.md).

## Candidate format

Every state, invariant, and deepening candidate uses this shape (test sweeps use [TEST-POLICY.md](TEST-POLICY.md)):

### [KIND-NN] Short imperative title

- **Evidence**: `path/file.ts:123` (strongest sites).
- **Failure mode**: concrete corruption, stuck state, or wrong result.
- **Current enforcement**: `type | schema | database constraint | transaction | runtime guard | test | documentation | none`.
- **Recommended form**: explicit state representation or enforcement layer.
- **Interface change**: what callers stop knowing.
- **Deletion test**: what happens if deleted (`not applicable` for state/invariant).
- **Plan**: files, seam-level steps, callers to migrate (no exact code; specs own implementation detail).
- **Tests deleted**: files/cases removed and their replacement (`none` if none).
- **Acceptance test**: `<category>: <test file>: <case>` (`algorithmic logic`, `boundary IO`, or `integration flow`).
- **Unslop check**: diff passes `emil-unslop-code` before PR.
- **Rank**: `impact / confidence / effort / risk (<why>)`.
- **Strength**: `strong` | `worth exploring` | `speculative`.
- **Blocked by**: candidate IDs or `none`.
