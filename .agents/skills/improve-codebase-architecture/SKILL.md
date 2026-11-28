---
name: improve-codebase-architecture
description: Deepen modules, simplify interfaces, find implicit state machines, find every invariant the code relies on but does not enforce, and prune the test suite to algorithmic logic, boundary IO, and integration flows; rank the changes and produce an executable plan with steps, acceptance tests, and dependency order, then feed the plan to a mission or a standalone decision. Use when the owner asks to audit architecture, deepen modules, find state machines or invariants, prune a test suite, or run an architecture improvement pass.
disable-model-invocation: true
---

# Improve codebase architecture

Read-only planning pass with four jobs: deepen shallow modules and shrink interfaces, surface every implicit state machine, uncover every unenforced invariant, and prune the test suite to algorithmic logic, boundary IO, and integration flows. Outputs a ranked, executable plan for `mission` or a standalone decision.

Never edit audited production source during this pass; `implement` performs code and test deletions after the gate.

Load `codebase-design` before evaluating candidates and use its exact terms: **module**, **interface**, **implementation**, **depth**, **seam**, **adapter**, **leverage**, **locality**. Read `GLOSSARY.md` and local ADRs first so domain terms stay consistent and settled decisions are not reopened.

## Process

### 1. Scope

Decide what is in and what is out before scanning. YAGNI: deepening pays off where code actually changes.

- Use the owner's direction if given; otherwise inspect churn hot spots via `git log --name-only --oneline`.
- State and invariant passes claim completeness over their declared scope. If the repo is too large for one pass, declare the audited packages and list skipped packages with reasons in the coverage table so a sample never masquerades as "all".

### 2. Model and scan

Read [MODEL-AUDIT.md](MODEL-AUDIT.md) and [TEST-POLICY.md](TEST-POLICY.md) first, then walk the fixed scan order (churn -> state -> invariants -> seams -> tests -> structural slop) and build four inventories with `file:line` evidence:

- **Lifecycles**: every stateful entity (status fields, boolean clusters, phase timestamps, queues, sessions, subscriptions) with states, events, guards, side effects, persistence, and `unknown` edges.
- **Invariants**: every assumed-but-unenforced rule across uniqueness, cardinality, ordering, tenancy, balances, temporal, referential, idempotency, concurrency, and immutability.
- **Abstractions and seams**: missing, premature, or leaking abstractions; deletion-test verdicts; dependency categories from [DEEPENING.md](../codebase-design/DEEPENING.md).
- **Test suite**: every behavior test classified via [TEST-POLICY.md](TEST-POLICY.md) (`algorithmic logic`, `boundary IO`, `integration flow`, or `delete` with reason and replacement).

Reject any candidate lacking `file:line` evidence, a concrete failure mode, or a passing deletion test (for deepenings). Never invent states or invariants; mark unknown edges `unknown` and unenforced rules `none`. Cross-module or standalone test deletions become one `test` sweep candidate sequenced first; deletions inside a single module with a candidate belong to that candidate's steps.

### 3. Rank and sequence

Rank every surviving candidate on impact, confidence, effort, risk, and dependencies using the scales in [MODEL-AUDIT.md](MODEL-AUDIT.md). Order by blocking edges first, then impact -> effort -> risk. Pick **one top recommendation** (expanded) and name the next two candidates. Never hand the owner an unranked menu.

### 4. Write the outputs

Resolve the OS temp directory (`$TMPDIR`, fallback `/tmp`; `%TEMP%` on Windows) and write two files with one shared run timestamp:

1. `<tmpdir>/architecture-review-<timestamp>.html`: owner report following [HTML-REPORT.md](HTML-REPORT.md), with sections in order: Coverage (including test inventory summary), State machines, Invariants, Test suite, Deepening candidates, and Top recommendation/sequence.
2. `<tmpdir>/architecture-review-<timestamp>.json`: compact candidate index for `mission`:

```json
{
  "run": { "repo": "", "commit": "", "timestamp": "", "report": "" },
  "coverage": [{ "area": "", "lifecycles": [], "invariants": [], "not_audited": [], "why": "" }],
  "sequence": ["deepening-01"],
  "candidates": [
    {
      "id": "deepening-01",
      "kind": "deepening",
      "title": "",
      "strength": "strong",
      "impact": "high",
      "confidence": "high",
      "effort": "M",
      "risk": "LOW",
      "evidence": ["path/file.ts:123"],
      "interface_change": "",
      "action": {
        "files": ["path/file.ts"],
        "steps": ["..."],
        "tests_deleted": ["path/test.ts"],
        "acceptance_test": "algorithmic logic: path/test.ts: sums the line items",
        "unslop_check": "emil-unslop-code clean on diff",
        "blocked_by": []
      },
      "anchor": "#deepening-01"
    }
  ]
}
```

Field values: `kind` in `state | invariant | deepening | test`; `strength` in `strong | worth exploring | speculative`; `impact`/`confidence` in `high | med | low`; `effort` in `S | M | L`; `risk` in `LOW | MED | HIGH`. Every non-sweep candidate's `acceptance_test` names one of the three test categories; a `test` sweep asserts zero remaining out-of-policy tests.

Open the HTML report (`xdg-open`, `open`, or `start`), share both absolute paths, and stop before proposing full code interfaces.

### 5. Compose with mission or standalone

Ask whether this is a mission pass or standalone if not already stated:

- **Mission**: feed the plan and JSON index into the mission grill; the gate approves the top candidate or sequence before creating the work item record. Change routes to `implement`; Feature/Fog routes through `to-spec` -> `to-tickets` -> `implement`/`implement-spec`.
- **Standalone**: load `grilling` on the chosen candidate, run [DESIGN-IT-TWICE.md](../codebase-design/DESIGN-IT-TWICE.md) when multiple credible interfaces or callers exist, and record new terms or lasting rejections via `domain-modeling`.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
