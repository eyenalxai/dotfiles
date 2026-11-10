# Design it twice

Use this parallel subagent pattern when the owner wants to explore alternative interfaces for a chosen deepening candidate. It comes from "Design It Twice" (Ousterhout): a first idea is rarely the strongest.

This file uses the vocabulary in [SKILL.md](SKILL.md): **module**, **interface**, **seam**, **adapter**, **leverage**.

## Process

### 1. Frame the problem space

Before spawning subagents, write an explanation of the problem space for the chosen candidate that the owner can read:

- The constraints any new interface must satisfy.
- The dependencies it relies on, and their category in [DEEPENING.md](DEEPENING.md).
- A rough code sketch that grounds the constraints. It is not a proposal; it makes the constraints concrete.

Show it to the owner, then continue to step 2. The owner reads and thinks while the subagents work in parallel. Why: the explanation gives the owner a frame for the comparison, and the subagents do not wait on it.

### 2. Spawn subagents

Spawn three or more subagents in parallel. Each must produce a **radically different** interface for the deepened module.

Prompt each subagent with a separate technical brief: file paths, coupling details, dependency category from [DEEPENING.md](DEEPENING.md), and what sits behind the seam. The brief is independent of the owner-facing explanation in step 1. Give each agent a different design constraint:

- Agent 1: "Minimize the interface: one to three entry points. Maximize leverage per entry point."
- Agent 2: "Maximize flexibility: support many use cases and extension."
- Agent 3: "Optimize for the most common caller: make the default case trivial."
- Agent 4, when applicable: "Design around ports and adapters for cross-seam dependencies."

Include both [SKILL.md](SKILL.md) vocabulary and `GLOSSARY.md` vocabulary in the brief, so each subagent names things consistently with the architecture language and the project's domain language.

Each subagent outputs:

1. Interface: types, methods, parameters, plus invariants, ordering, and error modes.
2. A usage example that shows how callers use it.
3. What the implementation hides behind the seam.
4. Dependency strategy and adapters. See [DEEPENING.md](DEEPENING.md).
5. Trade-offs: where leverage is high and where it is thin.

### 3. Present and compare

Present designs sequentially so the owner can absorb each one, then compare them in prose. Contrast by **depth** (leverage at the interface), **locality** (where change concentrates), and **seam placement**. Why: a side-by-side dump invites skimming, and the comparison is the point.

After comparing, recommend one design: name the strongest and why. If elements from different designs combine well, propose a hybrid. The owner wants a strong read, not a menu.
