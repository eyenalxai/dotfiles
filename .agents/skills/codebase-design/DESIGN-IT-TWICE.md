# Design it twice

Parallel subagent pattern for comparing competing interfaces on a chosen deepening candidate (Ousterhout's "Design It Twice": the first interface is rarely the deepest). Uses the exact vocabulary in [SKILL.md](SKILL.md): **module**, **interface**, **seam**, **adapter**, **leverage**, **locality**.

## Process

### 1. Frame the problem for the owner

Write a concise problem-space brief the owner can read while subagents run:
- Constraints any valid interface must satisfy.
- Dependencies and their category from [DEEPENING.md](DEEPENING.md).
- A rough code sketch grounding the constraints (not a proposal).

### 2. Spawn competing subagents in parallel

Launch 3 (or 4) subagents simultaneously. Give every subagent the technical pointers (file paths, coupling, dependency category, what sits behind the seam), plus both [SKILL.md](SKILL.md) and `GLOSSARY.md` vocabulary. Assign each a distinct constraint:

- **Agent 1:** Minimize the interface (1 to 3 entry points; maximize leverage per entry point).
- **Agent 2:** Maximize flexibility and extension across callers.
- **Agent 3:** Optimize for the 80% caller so the default call is trivial.
- **Agent 4 (when cross-seam IO applies):** Design around explicit ports and adapters.

Require each subagent to return:
1. Interface: types, methods, parameters, invariants, ordering rules, error modes.
2. Realistic caller usage example.
3. Complexity hidden behind the seam.
4. Dependency/adapter strategy ([DEEPENING.md](DEEPENING.md)).
5. Honest tradeoffs (where leverage is high vs. thin).

### 3. Present and recommend

Present the viable designs sequentially in prose (side-by-side tables invite skimming), contrast them by **depth**, **locality**, and **seam placement**, and end with **one concrete recommendation** (or hybrid) and why. Never hand the owner an unranked menu.
