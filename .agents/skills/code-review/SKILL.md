---
name: code-review
description: "Review the changes since a fixed point (commit, branch, tag, or merge-base) along two axes: Standards (does the code follow this repo's documented coding standards?) and Spec (does the code match what the originating issue/spec asked for?). Runs the reviews as parallel sub-agents when both sources exist and reports them side by side. Use when the owner wants to review a branch, a PR, work-in-progress changes, or asks to \"review since X\"."
---

# Code review

Two-axis review of the diff between `HEAD` and a fixed point the owner supplies:

- **Standards**: does the code conform to this repo's documented coding standards?
- **Spec**: does the code implement the originating issue or spec?

Both axes run as parallel sub-agents so they do not pollute each other's context; this skill aggregates their findings.

The issue tracker must be available to you. If it is missing, ask the owner for the tracker.

## Process

### 0. Check the authorizing gate

Read the mission document and the gate decision. If the gate is pending, say the
diff is a proposal and this review is not the PR gate. If the gate is approved,
state that the gate is approved. Never reproduce the owner's words or name the
person who decided. State the current finding only, with no history of
the issue or mission. The review does not grant the gate; the merge does. Why: a review is
evidence, and only the merge decision approves.

### 1. Pin the fixed point

Whatever the owner said is the fixed point: a commit SHA, branch name, tag,
`main`, or `HEAD~5`. If the owner named none, ask for it.

For a stacked ticket, the fixed point is the PR's base branch, so the diff is the ticket's layer, not the whole stack. Why: the layer is the change under review, and the blocker's diff was reviewed below it.

Capture the diff command once: `git diff <fixed-point>...HEAD` (three-dot, so the comparison is against the merge-base). Note the commit list with `git log <fixed-point>..HEAD --oneline`.

Before going further, confirm the fixed point resolves (`git rev-parse <fixed-point>`) and the diff is non-empty. An invalid ref or an empty diff must fail here, not inside two parallel sub-agents.

### 2. Identify the spec source

Look for the originating spec, in this order:

1. Issue references in the commit messages (`#123`, `Closes #45`, GitLab `!67`), fetched with the workflow in the tracker doc.
2. A path the owner passed as an argument.
3. A spec file under `docs/`, `specs/`, or `.scratch/` matching the branch name or feature.
4. For a change or bug, the mission document is the spec source. Use its
   problem, constraints, rule changes, and file scope.
5. For a feature ticket, the ticket is the spec source. Use its body and
   acceptance criteria; the parent spec is context.
6. If nothing is found, ask the owner where the spec is. If the owner says there is none, the **Spec** sub-agent skips and reports "no spec available".

### 3. Identify the standards sources

Search the repo for every file that documents how code is written. When `CODING_STANDARDS.md` or `CONTRIBUTING.md` exists, it must be on the list.

For a skill change, the standards sources are `AGENTS.md`, the
`emil-writing-skills` standard, the `emil-unslop-writing` standard, and the
repository's other skill files for cross-reference and terminology. Check every
rule for its why, every line for whether it changes what the agent does, and the
skill for a single focus. A skill that lists rules without reasons is a Standards
finding. Why: the repo's product is the process, so a skill diff is code and the
skill-writing standard is its coding standard.

On top of whatever the repo documents, the Standards axis always carries the **smell baseline** below: a fixed set of Fowler code smells (_Refactoring_, ch. 3) that applies even when a repo documents nothing. Two rules bind it:

- **The repo overrides.** A documented repo standard always wins; where it endorses something the baseline flags, suppress the smell. Why: the documented standard is the contract, and the baseline is only a fallback.
- **Always a judgment call.** Each smell is a labeled heuristic ("possible Feature Envy"), never a hard violation. Like any standard here, skip anything tooling already enforces.

Each smell names what it is and how to fix it. Match it against the diff:

- **Mysterious Name**: a function, variable, or type whose name does not reveal what it does or holds. → rename it; if no honest name comes, the design is murky.
- **Duplicated Code**: the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy**: a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps**: the same few fields or params keep traveling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession**: a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches**: the same `switch` or `if` cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery**: one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change**: one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality**: abstraction, parameters, or hooks added for needs the spec does not have. → delete it; inline back until a real need shows.
- **Message Chains**: long `a.b().c().d()` navigation the caller must not depend on. → hide the walk behind one method on the first object.
- **Middle Man**: a class or function that mostly delegates onward. → cut it, call the real target direct.
- **Refused Bequest**: a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

### 4. Spawn both sub-agents in parallel

Issue both sub-agent calls together, in the foreground, and aggregate the reports they return.

The **Standards sub-agent prompt** must include:

- The full diff command and commit list.
- The list of standards-source files found in step 3, **plus the smell baseline from step 3** pasted in full (the sub-agent has no other access to it).
- The brief: "Report, per file or hunk where relevant, (a) every place the diff violates a documented standard: cite the standard (file and rule); and (b) any baseline smell you spot: name it and cite the hunk by file and line. Distinguish hard violations from judgment calls: documented-standard breaches can be hard, but baseline smells are always judgment calls, and a documented repo standard overrides the baseline. Skip anything tooling enforces. Use neutral language and no history. Under 400 words."

The **Spec sub-agent prompt** must include:

- The diff command and commit list.
- The path or fetched contents of the spec.
- The brief: "Report: (a) requirements the spec asked for that are missing or partial; (b) behavior in the diff that was not asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Cite the spec line for each finding. Use neutral language and no history. Under 400 words."

If the spec is missing, skip the Spec sub-agent and note this in the final report.

The 400-word cap keeps the two reports readable side by side.

### 5. Aggregate

Present the two reports under `## Standards` and `## Spec` headings, verbatim or lightly cleaned. Do not merge or rerank findings. Why: a change can pass one axis and fail the other, and a merged report lets one axis mask the other.

End with a one-line summary: total findings per axis and the worst issue within each axis, if any. Never pick a single winner across axes; that is the reranking the separation prevents.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
