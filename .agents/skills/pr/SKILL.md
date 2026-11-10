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

## The authorizing gate

Before writing the body, read the mission document and the gate decision. On a
feature or fog path, the authorizing gates are the scope and spec gate and the
ticket gate. On a fog path, the decision gates also authorize the build. On a
change, bug, or trivial, the authorizing gate is the scope and understanding.
State each decision, or say which are pending.

- If every authorizing gate is approved, state the decisions in neutral, general
  language. Never reproduce the owner's words or name the person who decided.
  The merge approves the PR gate.
- If an authorizing gate is pending, open the PR as a draft and say it is a
  proposal, not a decision. Do not write "approved" anywhere.
- If the scope is a rule plus a file pattern, the body names the rule and the
  pattern, not a per-file list. Why: the rule is the decision; the file list is
  the current instance.
- State the current problem, the route, and the alternative rejected. Do not
  carry history of the issue or mission.

Why: the body cannot grant a gate; it can only make the decision visible.

Use this template for the PR body:

```markdown
## Why

<the problem, the route taken, and the alternative rejected. State the authorizing gates and the decisions in neutral language, or say which gates are pending and that this is a proposal. Never quote the owner's words or name the person who decided. Do not add history.>

## Summary

<diagram, diff-sketch, or tree>

## Evidence

- **Before:** <screenshot/output/failing test run>
  **After:** <screenshot/output/passing test run>

## What this unlocks

<the next capability or decision this makes possible>

## Merge Danger

**Door:** <one-way or two-way>

<optional: description>

**Blast Radius:** <one-word description>

<optional: potential ramifications of merge>
```

## Sections

Skip all preambles and keep prose brief. Use the project's domain language from `GLOSSARY.md` when it exists.

### Why

State the problem in plain terms, the route taken, and the alternative
rejected. When there was no real alternative, write `no alternative: <reason>`
in one clause. Link the originating issue or mission document. State the
authorizing gates and the decisions in neutral language, or say which gates are
pending and that the PR is a proposal. Never quote the owner's words or name
the person who decided. Do not add history.

### Summary

Pick the smallest view that makes the key point clear. See [VISUALS.md](VISUALS.md) for the diagram, tree, and diff shapes.

### Evidence

Show a before and after. When the change is visual and the environment supports it, use a screenshot. Otherwise show execution output: test results, console output, or the exact test that failed before and passes after, shown as pseudocode.

### What this unlocks

Name the next capability, ticket, or decision this makes possible. Keep it
concrete.

### Merge danger

State whether the door is one-way or two-way. You can walk back through a two-way door; you cannot walk back through a one-way door. A PR that is cheap to roll back is lower risk. Destructive actions and hard-to-reverse decisions are one-way doors.

The blast radius is the impact or scope of the change: layout shift, breakage for consumers, mobile responsiveness, and similar.

State the gate risk in the merge danger. If any authorizing gate is pending, the
merge is a decision, not a review. If every authorizing gate is approved, the
merge is the second approval. Why: the owner reads the merge danger to decide,
and a hidden pending gate turns a review into an unapproved build.

## Handback

Report the PR URL, the check state, what changed, what it unlocks, and the merge
danger. The head SHA stays in the PR. Why: the SHA is for the machine; the
owner's decision is the merge.

Use `Closes <issue>` in the body when the PR completes the issue. Use `Refs
<issue>` when the issue stays open.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
