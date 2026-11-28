# Test policy

Keep three categories of behavior test and delete the rest. During `improve-codebase-architecture`, the planner inventories every behavior test in the scan area and records deletions in the plan; `implement` executes deletions only after the owner approves the gate.

A test earns its place only when it can fail on real behavior the code cannot self-check: logic output, an adapter contract, or cross-module wiring. Everything else is a change-detector that breaks on refactors without catching bugs.

## The three kept categories

1. **Algorithmic logic**: pure or in-memory behavior with no IO (calculations, parsers, validators, reducers, schedulers, state transitions). Drives the public interface and asserts against an independent expected value (literal, worked example, spec). Never mocks internal collaborators.
2. **Boundary IO**: one adapter's contract at an edge (HTTP handler, DB repository, filesystem, queue, external client, serialization). Runs the real adapter against a local stand-in (PGlite, in-memory FS, fake HTTP server) or contract test. Asserts request/response shape, schema, and error mapping, not downstream business logic.
3. **Integration flow**: a real path across 2+ modules or a full user journey (checkout, signup, webhook-to-DB, CLI run). Uses real internal wiring with fakes only at the outermost edge, asserting observable outcomes.

## Classification decision tree

Walk in order; when a test matches more than one level, the **highest** level wins (it protects the widest path):

```text
Does it exercise a real path across 2+ modules or a full user journey?
├── Yes → integration flow
└── No
    ├── Does it test one adapter's edge contract against a local stand-in/fake?
    │   ├── Yes → boundary IO
    │   └── No
    │       ├── Does it test IO-free logic through its public interface with an independent expected value?
    │       │   ├── Yes → algorithmic logic
    │       │   └── No  → delete (including ambiguous tests; record reason)
```

## Delete list

- Component/UI tests mounting internals to assert props, local state, or snapshots.
- Single-module component tests asserting a user-visible contract without crossing a module boundary -> move the assertion into a page-level **integration flow**.
- Private-method tests, internal-collaborator mock tests, call-count/call-order assertions.
- Tests reaching past the interface to query the DB or read files directly.
- Tautological tests recomputing expected values with the implementation's own formula (see [tdd/tests.md](../tdd/tests.md)).
- Tests of constants, generated code, or framework internals.

**Out of scope (never deleted by this policy):** benchmarks, load tests, security scans, and accessibility audits. List them as out of scope in the report.

## Inventory table

Classify every test in the scan area:

| File | Test | Category | Keep or delete | Reason | Replacement |
| --- | --- | --- | --- | --- | --- |

Write `none` in Replacement when no real behavior coverage is lost; otherwise name the kept test or category covering that behavior. Summarize counts by category plus keep/delete totals in the report's Coverage table.

## Test sweep candidate

- **Cross-module deletions** (2+ modules, or deletions with no matching module candidate): bundle into one `test` sweep candidate, sequenced **first**.
- **Single-module deletions** tied to a deepening/state/invariant candidate: include inside that candidate's `tests_deleted` steps.

Test sweep candidate fields:
- **Evidence**: inventory delete count and test files.
- **Problem**: N tests fall outside the three categories, duplicating coverage and breaking on refactors.
- **Solution**: delete them; kept suite covers algorithmic logic, boundary IO, and integration flows.
- **Interface change**: none.
- **Deletion test**: not applicable.
- **Plan / Tests deleted**: files and cases removed, paired with replacement or `none`.
- **Acceptance test**: kept suite passes and out-of-policy delete count is zero.
- **Unslop check**: `emil-unslop-code` clean on deletion diff (no production edits).
- **Rank & Strength**: impact, confidence, effort, risk (specifically any temporary coverage gap before replacements land); `strong`, `worth exploring`, or `speculative`.
- **Blocked by**: `none`.

## Acceptance tests for all other candidates

Every non-sweep candidate must name one concrete test in one of the three categories:

- `algorithmic logic: path/to/test.ts: sums the line items`
- `boundary IO: path/to/repo.test.ts: rejects a duplicate email`
- `integration flow: path/to/checkout.e2e.ts: checkout with a valid cart`
