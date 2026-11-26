---
name: domain-modeling
description: Build and sharpen a project's domain model. Use when discussing codebase terminology, writing or editing a GLOSSARY.md, or recording or editing an ADR.
---

# Domain modeling

Sharpen domain language as decisions land and record durable terms and architectural tradeoffs in `GLOSSARY.md` and `docs/adr/`. Reading the glossary is a habit any skill performs; this skill is for changing the model.

## Roles

- **Orchestrator (`opencode-go/kimi-k3.1-pro`)**: challenges fuzzy or conflicting terms in conversation, invents concrete edge-case scenarios, and writes `GLOSSARY.md` and ADRs directly (owner-read durable docs).
- **Worker (`openrouter/deepseek/deepseek-v4.1-flash-1017#max`, `explore` subagent)**: checks the codebase to verify whether existing code contradicts a claim made in conversation, returning `file:line` evidence in under 250 words.

## Decide what to write

```text
Is a term fuzzy or in conflict with GLOSSARY.md?
├── Yes → Sharpen it and update GLOSSARY.md immediately (GLOSSARY-FORMAT.md).
└── No  → Write nothing to GLOSSARY.md.

Is a decision (1) hard to reverse, AND (2) surprising without context, AND (3) a real tradeoff among genuine alternatives?
├── All 3 → Offer and write an ADR (ADR-FORMAT.md).
└── Any missing → Skip the ADR; documenting obvious or reversible choices adds noise.
```

Create `GLOSSARY.md` and `docs/adr/` lazily when the first entry earns its place. If `GLOSSARY-MAP.md` exists at the root, follow it to the active context's `GLOSSARY.md` and `docs/adr/` (system-wide ADRs stay in root `docs/adr/`).

Write every glossary entry and ADR in neutral current state only: never quote the conversation, name who decided, or include history of how the decision was reached.

## Active habits during design

- **Challenge glossary conflicts immediately.** "The glossary defines 'cancellation' as X, but this sounds like Y. Which one is it?"
- **Split overloaded terms.** "Are we talking about Customer or Account? Those are distinct concepts."
- **Probe with concrete scenarios.** Test boundaries with edge cases until the model handles them cleanly.
- **Verify against code via worker.** When someone claims "orders can be partially canceled", have an `explore` worker check the actual code path and surface contradictions immediately.
- **Keep `GLOSSARY.md` pure.** Update inline as terms settle, never batched. Store zero implementation details, specs, or scratch notes; implementation details go stale.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
