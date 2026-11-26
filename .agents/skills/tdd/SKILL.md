---
name: tdd
description: Test-driven development. Use when the owner wants to build features or fix bugs test-first, mentions "red-green-refactor", or wants integration tests.
---

# Test-driven development

Strict red-to-green loop executed inside the implementation worker (`openrouter/deepseek/deepseek-v4.1-flash-1017#max`). Read before and during every cycle; checking test quality after the code is written cannot fix a wrong seam or tautological assertion.

## When to run

```text
Does this change have an approved code seam (spec Testing Decisions, ticket criteria, or gate)?
├── No (prose/markdown only) → Skip TDD; verify against the repo's writing standard.
├── Missing or ambiguous     → Stop and report to the orchestrator; never invent a seam.
└── Yes                      → Run the red-green loop at that seam.
```

Read `GLOSSARY.md` (if present) so test names match domain terms, and respect local ADRs. See [tests.md](tests.md) for concrete good/bad examples and [mocking.md](mocking.md) for mocking rules. If the seam's interface shape itself is unclear, consult `codebase-design`.

## What makes a test worth keeping

Tests exercise **public behavior through the approved seam**, never internal structure. If you refactor the internals without changing behavior, every test must still pass untouched.

Reject these three anti-patterns on sight:

- **Implementation-coupled:** mocks internal collaborators, calls private methods, or asserts on side channels (querying a DB directly instead of calling the interface). Breaks on refactors.
- **Tautological:** recomputes the expected result with the same formula as the code (`expect(add(a, b)).toBe(a + b)` or hand-mirrored snapshots). Expected values must come from an independent source: fixed literals, worked examples, or the spec.
- **Horizontal slicing:** writing all tests first, then all code. Bulk tests test imagined shapes instead of real behavior and lock in structure before you understand the problem.

## The loop

Work in **vertical slices**, one behavior at a time:

1. **Red.** Write one failing test at the approved seam for the next slice of behavior. Run it and confirm it fails for the right reason (a test that passes immediately proves nothing).
2. **Green.** Write the smallest implementation that makes that test pass. Do not anticipate later tests or add speculative abstractions.
3. **Repeat** for the next vertical slice until every acceptance criterion is green.
4. **Leave refactoring for review.** Do not mix refactoring into a red-green cycle; mixing behavior changes and structure changes hides which one broke a test. Structural cleanup happens in `code-review`.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
