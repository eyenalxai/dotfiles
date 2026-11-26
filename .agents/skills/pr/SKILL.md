---
name: pr
description: "Shape a PR body with the authorizing gate, evidence, unlock, and merge danger."
metadata:
  credits:
    skill: show-me
    author: Dex Horthy
    organization: Humanlayer
    url: "https://github.com/humanlayer/skills/blob/main/plugins/show-me/skills/show-me/SKILL.md"
---

# PR

Write a crisp, high-signal PR body that lets the owner review and decide the merge fast.

## Roles

- **Orchestrator (`opencode-go/kimi-k3.1-pro`)**: always writes the PR body and owner handback. The owner reads the PR directly to decide the merge, so it must carry orchestrator-grade clarity.
- **Worker (`openrouter/deepseek/deepseek-v4.1-flash-1017#max`)**: if diff stats, test outputs, screenshots, or check states need gathering, have a worker collect them and return a compact summary.

## Check the authorizing gate first

Read the mission document (if one exists) and determine which gates authorize this change:

- **Feature / Fog**: Scope and spec gate + Tickets gate (+ Fog decision gates).
- **Change / Bug / Trivial**: Scope and understanding gate.

Branch on status:
- **All authorizing gates approved:** state the decisions neutrally in `## Why`. Merge approves the PR gate.
- **Any authorizing gate pending:** open the PR as a **draft**, label it a **proposal** in `## Why`, never write "approved", and note in Merge Danger that merging acts as a decision rather than a second approval.

Rules for every PR body:
- Neutral current state only: never quote conversation words, name deciders, or carry issue/mission history.
- For large changes governed by a rule plus file pattern, state the rule and pattern rather than a per-file list.
- Use `GLOSSARY.md` terms. Skip preambles.
- End with `Closes <issue>` if the PR finishes the issue, or `Refs <issue>` if it stays open.

## Template

```markdown
## Why

<Problem in plain terms, route taken, alternative rejected (or `no alternative: <reason>`), link to issue/mission, and neutral gate status.>

## Summary

<Smallest visual that makes the change obvious: diagram, tree, or diff sketch. See VISUALS.md.>

## Evidence

- **Before:** <screenshot, command output, or failing test>
- **After:** <screenshot, command output, or passing test>

## What this unlocks

<Concrete next capability, ticket, or decision.>

## Merge Danger

**Door:** <one-way | two-way>
<Optional one-line note on rollback cost.>

**Blast Radius:** <one-word scope, e.g. Local | API | Schema | Consumers>
<Potential ramifications plus gate risk: second approval vs unapproved decision.>
```

See [VISUALS.md](VISUALS.md) for diagram, tree, and diff-sketch shapes.

- **Evidence:** use screenshots for visual changes when supported; otherwise paste concise execution output or before/after test results.
- **Door:** two-way = cheap to revert; one-way = destructive, schema/data migration, or hard-to-reverse contract change.

## Owner handback

Report in chat: PR URL, check state, what changed, what it unlocks, and merge danger. Keep head SHAs in the PR; the owner decides the merge, not the SHA.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
