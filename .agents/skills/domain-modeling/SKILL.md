---
name: domain-modeling
description: Build and sharpen a project's domain model. Use when discussing codebase terminology, writing or editing a GLOSSARY.md, or recording or editing an ADR.
---

# Domain modeling

Build and sharpen the project's domain model as you design. This is the active discipline: challenge terms, invent edge-case scenarios, and write the glossary and decisions down the moment they crystallize. Reading `GLOSSARY.md` for vocabulary is a one-line habit any skill can perform; this skill is for changing the model.

## Decide what to write

Ask two questions:

1. Is the term fuzzy, or in conflict with the glossary? If yes, sharpen it and write it in `GLOSSARY.md`.
2. Is the decision hard to reverse, surprising without context, and a real tradeoff among genuine alternatives? If all three, write an ADR.

When neither applies, write nothing. Why: a glossary of guesses and ADRs for reversible choices add noise, and the next session cannot tell which entries are settled.

Write the glossary and the ADR in neutral language. Never quote the conversation or name the person who decided. The entry is current state only: no prior attempts, sessions, issues, or versions. Why: an ADR records the decision, not the conversation that produced it.

## File structure

Most repos have a single context:

```
/
├── GLOSSARY.md
├── docs/
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

If a `GLOSSARY-MAP.md` exists at the root, the repo has multiple contexts. The map points to where each context lives:

```
/
├── GLOSSARY-MAP.md
├── docs/
│   └── adr/                          system-wide decisions
├── src/
│   ├── ordering/
│   │   ├── GLOSSARY.md
│   │   └── docs/adr/                 context-specific decisions
│   └── billing/
│       ├── GLOSSARY.md
│       └── docs/adr/
```

Create files lazily: only when you have something to write. If no `GLOSSARY.md` exists, create one when the first term is resolved. If no `docs/adr/` exists, create it when the first ADR is needed.

## During the session

### Challenge against the glossary

When the owner uses a term that conflicts with the existing language in `GLOSSARY.md`, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y. Which is it?"

### Sharpen fuzzy language

When the owner uses a vague or overloaded term, propose a precise canonical term. "You're saying 'account': do you mean the Customer or the Account? Those are different things."

### Discuss concrete scenarios

When domain relationships are under discussion, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the owner to state the boundaries between concepts.

### Cross-reference with code

When the owner states how something works, check whether the code agrees. Surface a contradiction: "Your code cancels entire Orders, but you just said partial cancellation is possible. Which is right?"

### Update GLOSSARY.md inline

When a term is resolved, update `GLOSSARY.md` at once. Do not batch these updates; capture them as they happen. Use the format in [GLOSSARY-FORMAT.md](./GLOSSARY-FORMAT.md).

`GLOSSARY.md` holds no implementation details. Do not treat it as a spec, a scratch pad, or a store for implementation decisions. It is a glossary and nothing else. Why: implementation details change, and a definition that carries them goes stale.

### Offer ADRs sparingly

Offer an ADR only when all three are true:

1. **Hard to reverse**: changing the decision later costs real work.
2. **Surprising without context**: a future reader will ask why the code does it this way.
3. **The result of a real tradeoff**: genuine alternatives existed, and the decision picked one for specific reasons.

If any of the three is missing, skip the ADR. Why: the record then documents an obvious or reversible choice, which adds noise. Use the format in [ADR-FORMAT.md](./ADR-FORMAT.md).

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
