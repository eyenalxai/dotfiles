---
name: prototype
description: Build a throwaway prototype to answer a design question. Use when the owner wants to sanity-check whether a state model or logic feels right, or explore what a UI looks like.
---

# Prototype

Build throwaway code that answers one concrete design question fast.

## 1. Pick a branch

```text
What question is the prototype answering?
├── "Does this logic or state model feel right?" → Read LOGIC.md (single shareable HTML file with free-play controls + guided walkthroughs)
└── "What does this UI look like?"              → Read UI.md (several distinct variations on one route, switchable via URL param + floating bottom bar)
```

If ambiguous and the owner is unavailable, match the surrounding code (backend module -> `LOGIC.md`; page/component -> `UI.md`) and state the assumption at the top of the prototype.

## 2. Rules for both branches

1. **Clearly marked throwaway.** Place near the module or page it prototypes (following existing routing conventions for UI; never invent top-level structure) and name it unmistakably as a prototype so it never slips into production.
2. **One command or double-click to run.** UI starts via one existing task-runner command (`pnpm <name>`, `bun <path>`, `python <path>`); logic opens as one standalone HTML file. Friction keeps prototypes unrun.
3. **In-memory state only.** Persistence is usually what you are checking, not what you should set up. If a DB is part of the question, use a scratch DB or file clearly named `PROTOTYPE-wipe-me`.
4. **Skip polish.** Zero tests, zero abstractions, only the error handling needed to run.
5. **Always render full state.** After every logic action or UI variant switch, display the relevant state directly so the owner can judge without guessing.
6. **Capture the verdict and archive.** Once the question is answered, fold only the validated decision into real code/specs. Commit the prototype to a throwaway branch (never `main`) and record a pointer to that branch plus the verdict on the implementation issue.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
