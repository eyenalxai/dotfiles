# Writing agent briefs

An agent brief is a structured comment posted on a GitHub issue or PR when it moves to `ready-for-agent`. It is the authoritative specification an AFK agent works from. The original body and discussion are context; the brief is the contract.

The brief states what the agent does, on both surfaces: for an issue, build the change from nothing; for a PR, finish the existing diff, close gaps, and address review points. The principles are the same on both surfaces.

## Principles

### Durability over precision

The issue may sit in `ready-for-agent` for days or weeks, and the codebase changes in the meantime. Write the brief so it stays useful when files are renamed, moved, or refactored. Why: a path or line number describes today's tree, and the brief outlives it.

- Do describe interfaces, types, and behavioral contracts.
- Do name specific types, function signatures, or config shapes the agent looks for or modifies.
- Do not reference file paths: they go stale.
- Do not reference line numbers.
- Do not assume the current implementation structure stays the same.

### Behavioral, not procedural

Describe what the system does, not how to implement it. The agent explores the codebase fresh and makes its own implementation decisions.

- Do: "The `SkillConfig` type accepts an optional `schedule` field of type `CronExpression`."
- Do not: "Open src/types/skill.ts and add a schedule field on line 42."
- Do: "When the owner runs `/triage` with no arguments, they see a summary of issues needing attention."
- Do not: "Add a switch statement in the main handler function."

### Complete acceptance criteria

The agent needs to know when it is done. Every agent brief carries concrete, testable acceptance criteria. Each criterion is independently verifiable.

- Do: "Running `gh issue list --label needs-triage` returns issues that have been through initial classification."
- Do not: "Triage works correctly."

### Explicit scope boundaries

State what is out of scope. This stops the agent from gold-plating or assuming adjacent features.

## Template

```markdown
## Agent Brief

**Category:** bug / enhancement
**Summary:** one-line description of what needs to happen

**Current behavior:**
Describe what happens now. For bugs, this is the broken behavior.
For enhancements, this is the status quo the feature builds on.

**Desired behavior:**
Describe what happens after the agent's work is complete.
Name the edge cases and error conditions.

**Key interfaces:**
- `TypeName`: what changes and why
- `functionName()` return type: what it returns now and what it returns after the change
- Config shape: any new configuration options

**Acceptance criteria:**
- [ ] Specific, testable criterion 1
- [ ] Specific, testable criterion 2
- [ ] Specific, testable criterion 3

**Out of scope:**
- Thing that must not be changed or addressed in this issue
- Adjacent feature that might seem related but is separate
```

See [AGENT-BRIEF-EXAMPLES.md](AGENT-BRIEF-EXAMPLES.md) for worked bug, enhancement, and PR briefs, plus a counterexample.
