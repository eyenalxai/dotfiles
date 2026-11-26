# Design it twice

Parallel worker pattern for comparing competing interfaces on a chosen deepening candidate (Ousterhout's "Design It Twice": the first interface is rarely the deepest). Uses the exact vocabulary in [SKILL.md](SKILL.md): **module**, **interface**, **seam**, **adapter**, **leverage**, **locality**.

## Roles

- **Orchestrator (`opencode-go/kimi-k3.1-pro`)**: frames the problem space for the owner, spawns competing DeepSeek workers in parallel, critiques their designs on depth, locality, and seam placement, and delivers one strong recommendation (or hybrid).
- **Workers (`openrouter/deepseek/deepseek-v4.1-flash-1017#max`, 3+ parallel `general` subagents)**: each designs one radically different interface under a distinct constraint and returns a compact proposal (under 400 words).

## Process

### 1. Frame the problem for the owner

Write a concise problem-space brief the owner can read while workers run:
- Constraints any valid interface must satisfy.
- Dependencies and their category from [DEEPENING.md](DEEPENING.md).
- A rough code sketch grounding the constraints (not a proposal).

### 2. Spawn competing workers in parallel

Launch 3 (or 4) `general` subagents simultaneously on `openrouter/deepseek/deepseek-v4.1-flash-1017#max`. Give every worker the technical pointers (file paths, coupling, dependency category, what sits behind the seam), plus both [SKILL.md](SKILL.md) and `GLOSSARY.md` vocabulary. Assign each a distinct constraint:

- **Worker 1:** Minimize the interface (1 to 3 entry points; maximize leverage per entry point).
- **Worker 2:** Maximize flexibility and extension across callers.
- **Worker 3:** Optimize for the 80% caller so the default call is trivial.
- **Worker 4 (when cross-seam IO applies):** Design around explicit ports and adapters.

Require each worker to return:
1. Interface: types, methods, parameters, invariants, ordering rules, error modes.
2. Realistic caller usage example.
3. Complexity hidden behind the seam.
4. Dependency/adapter strategy ([DEEPENING.md](DEEPENING.md)).
5. Honest tradeoffs (where leverage is high vs. thin).

### 3. Critique and recommend (orchestrator)

If a worker produced a shallow pass-through or ignored constraints, follow up on its `sessionID` or discard it. Present the viable designs sequentially in prose (side-by-side tables invite skimming), contrast them by **depth**, **locality**, and **seam placement**, and end with **one concrete recommendation** (or hybrid) and why. Never hand the owner an unranked menu.
