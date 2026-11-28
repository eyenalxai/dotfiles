---
name: code-review
description: "Review the changes since a fixed point (commit, branch, tag, or merge-base) along two axes: Standards (does the code follow this repo's documented coding standards?) and Spec (does the code match what the originating issue/spec asked for?). Runs the reviews as parallel sub-agents when both sources exist and reports them side by side. Use when the owner wants to review a branch, a PR, work-in-progress changes, or asks to \"review since X\"."
---

# Code review

Two-axis review of `HEAD` against a fixed point, run in two parallel subagents so neither axis biases the other:

- **Standards**: conforms to documented repo standards plus the Fowler smell baseline.
- **Spec**: implements the originating issue, ticket, or spec without gaps or scope creep.

The configured issue tracker must be available; if missing, ask the owner.

## Process

### 0. Check the authorizing gate

Read the mission record if one exists. State neutrally whether the authorizing gate is approved or pending (never quote conversation words, name deciders, or log history). If pending, label the diff a **proposal**. A review is evidence; only merge approves the PR gate.

### 1. Pin the fixed point

Use the owner's ref (commit SHA, branch, tag, `main`, or `HEAD~5`). For a stacked ticket, use the PR's base branch so only this layer's diff is reviewed. If none was named, ask.

Confirm `git rev-parse <fixed-point>` succeeds and `git diff <fixed-point>...HEAD` is non-empty before spawning subagents. Capture `git log <fixed-point>..HEAD --oneline`.

### 2. Locate the spec source (first match wins)

1. Issue ref in commit messages (`#123`, `Closes #45`, `!67`), fetched via the tracker doc.
2. Path passed as an argument.
3. Matching spec file under `docs/`, `specs/`, or `.scratch/`.
4. Mission document (for Change or Bug: problem, constraints, rule changes, file scope).
5. Ticket body and acceptance criteria (for a Feature ticket; parent spec is context).
6. If none exists, ask the owner. If they confirm there is no spec, skip the Spec subagent and report `no spec available`.

### 3. Locate standards sources and attach the smell baseline

Find every repo file documenting coding conventions (`CODING_STANDARDS.md`, `CONTRIBUTING.md`, `AGENTS.md`, etc.).

For a **skill change**, standards sources are `AGENTS.md`, `emil-writing-skills`, `emil-unslop-writing`, and sibling skills for terminology consistency. A skill that lists bare rules without reasoning or leaves filler lines that do not steer behavior is a Standards finding.

Always paste this **Fowler smell baseline** into the Standards subagent prompt. Two rules bind it: (1) any documented repo standard overrides the baseline; (2) every smell is a labeled judgment call ("possible Feature Envy"), never a hard breach. Skip anything linters or typecheckers already enforce.

- **Mysterious Name**: name hides what it does or holds -> rename; if no clear name fits, the design is murky.
- **Duplicated Code**: same logic shape repeated across hunks/files -> extract and share.
- **Feature Envy**: method reaches into another object's data more than its own -> move it to that object.
- **Data Clumps**: same fields/params always travel together -> bundle into one type.
- **Primitive Obsession**: raw primitive/string standing in for a domain concept -> give it a small type.
- **Repeated Switches**: same type switch or `if` cascade recurs -> replace with polymorphism or one shared map.
- **Shotgun Surgery**: one logical change scatters edits across many files -> gather cohesive logic into one module.
- **Divergent Change**: one module edits for unrelated reasons -> split by reason to change.
- **Speculative Generality**: abstractions/hooks/params added for unasked needs -> delete and inline.
- **Message Chains**: deep `a.b().c().d()` caller navigation -> expose one method on the first object.
- **Middle Man**: wrapper that mostly delegates onward -> remove and call the real target.
- **Refused Bequest**: subclass ignores most of what it inherits -> replace inheritance with composition.

### 4. Spawn both subagents in parallel

Spawn both subagents together and wait for their reports:

- **Standards subagent prompt**: diff command (`git diff <fixed-point>...HEAD`), commit list, standards-source file paths, full smell baseline pasted verbatim, and brief:
  > Report per file/hunk: (a) violations of documented standards (cite file and rule); (b) baseline smells (name smell and `file:line`). Separate hard documented breaches from judgment-call smells; documented standards override the baseline. Skip linter/typechecker issues. Neutral language, no history, under 400 words.
- **Spec subagent prompt**: diff command, commit list, spec path or contents, and brief:
  > Report: (a) missing or partial spec requirements; (b) unasked behavior (scope creep); (c) requirements implemented incorrectly. Cite the spec line and diff `file:line` for each finding. Neutral language, no history, under 400 words.

### 5. Aggregate

Present `## Standards` and `## Spec` side by side, verbatim or lightly cleaned. Never merge or cross-rank findings across axes; a change can pass one and fail the other, and merging hides that.

End with a one-line summary: total findings per axis and the worst issue within each axis (never pick one winner across axes).

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
