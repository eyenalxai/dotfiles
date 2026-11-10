# Domain docs

How the skills consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`GLOSSARY.md`** at the repo root, or
- **`GLOSSARY-MAP.md`** at the repo root when it exists. It points at one `GLOSSARY.md` per context. Read each one relevant to the topic.
- **`docs/adr/`**: read the ADRs that touch the area you are about to work in. In multi-context repos, also check `src/<context>/docs/adr/` for context-scoped decisions.

If any of these files does not exist, proceed silently. Do not flag the absence or suggest creating them upfront. The `domain-modeling` skill (reached through `grill-with-docs` and `mission`) creates them lazily when terms or decisions are resolved.

## File structure

Single-context repo (most repos):

```
/
├── GLOSSARY.md
├── docs/adr/
│   ├── 0001-event-sourced-orders.md
│   └── 0002-postgres-for-write-model.md
└── src/
```

Multi-context repo (presence of `GLOSSARY-MAP.md` at the root):

```
/
├── GLOSSARY-MAP.md
├── docs/adr/                          system-wide decisions
└── src/
    ├── ordering/
    │   ├── GLOSSARY.md
    │   └── docs/adr/                  context-specific decisions
    └── billing/
        ├── GLOSSARY.md
        └── docs/adr/
```

## Use the glossary's vocabulary

When output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term defined in `GLOSSARY.md`. Do not drift to synonyms the glossary avoids. Why: one term per concept keeps issues, specs, and tests aligned.

If the concept is not in the glossary yet, that is a signal: either it is invented language the project does not use (reconsider), or there is a real gap (note it for `domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly instead of silently overriding it:

> _Contradicts ADR-0007 (event-sourced orders), but worth reopening because..._
