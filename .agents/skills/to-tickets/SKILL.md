---
name: to-tickets
description: Break a plan, spec, or the current conversation into tracer-bullet tickets, each declaring its blocking edges, and publish them to the configured tracker.
disable-model-invocation: true
---

# To tickets

Cut an approved spec into tracer-bullet vertical slices, each declaring the surface it owns and its blocking edges, then publish to the configured tracker.

## Roles

- **Orchestrator (`opencode-go/kimi-k3.1-pro`)**: designs the slice breakdown, blocking graph, and surface ownership; quizzes the owner at the Tickets gate; writes every ticket body; publishes after approval.
- **Worker (`openrouter/deepseek/deepseek-v4.1-flash-1017#max`)**: explores affected surfaces, call-site blast radius (for wide refactors), and prefactoring opportunities via `explore` so the orchestrator does not scan the repo directly.

Read the tracker doc and triage-label mapping first. If missing, ask the owner.

## Gate check

- **Inside a mission:** runs only on Feature or Fog, **after** the scope and spec gate is approved (plus Fog decision gates). If pending, stop and ask. Cutting tickets from an unapproved spec multiplies unapproved work. Change, Bug, and Trivial never use `to-tickets`.
- **Standalone:** the owner's request is the approval; the published spec is the source.

## Process

### 1. Gather context and surfaces

Work from the conversation or fetch the named spec/issue. If affected surfaces are not yet mapped, dispatch an `explore` worker (`openrouter/deepseek/deepseek-v4.1-flash-1017#max`) to list the modules, routes, schemas, commands, and prefactoring seams involved (under 400 words). Use `GLOSSARY.md` terms and respect ADRs.

### 2. Cut the slices

Follow these rules unless the work is a wide refactor:

- **Vertical, never horizontal.** Each slice cuts a thin, working path across all layers (schema, logic, API/UI, tests) so it is demoable and verifiable on its own.
- **One fresh worker context.** Size each ticket so one worker session can build, test, and verify it cleanly.
- **Disjoint surface ownership.** Name the module, route, schema, or command each ticket owns. If two ready tickets edit the same surface, add a blocking edge and stack them; parallel edits to one surface create merge conflicts.
- **Prefactor first.** Put enabling refactors in an earlier blocking ticket so behavior changes stay legible.
- **Honest blocking edges.** Add an edge only when one ticket genuinely needs another's interface or surface. A ticket with one blocker stacks on the blocker's branch; a ticket with multiple blockers waits until all but one merge, then stacks on the last. Stack order equals merge order.

**Exception: wide refactors.** When one mechanical change (renaming a column, retyping a shared symbol) breaks too many call sites for any vertical slice to stay green, use **expand, migrate, contract**:

1. **Expand**: add the new form beside the old so CI stays green.
2. **Migrate**: move callers in batches sized by blast radius (package or directory), each ticket blocked by Expand.
3. **Contract**: delete the old form once zero callers remain, blocked by every Migrate batch.

If batches cannot stay green individually, share one integration branch blocking a final integrate-and-verify ticket.

### 3. Present the graph (Tickets gate)

Show the owner a numbered list with:
- **Title**: short plain name
- **Surface owned**: module, route, schema, or command
- **Blocked by**: prerequisites (or none)
- **Delivers**: end-to-end verifiable behavior

Ask whether granularity, blocking edges, surface splits, and stack/merge order look right. Iterate until the owner approves the graph. Record the approval date and neutral decision in the mission record's Tickets gate (never quote words, name deciders, or add history).

### 4. Publish

Publish in dependency order (blockers first) so real IDs exist before wiring edges. Never modify or close the parent spec issue.

- **Local markdown tracker:** one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md` (never one combined file).
- **Issue tracker (Linear, GitHub, GitLab):** create each ticket as a child/sub-issue of the spec with `ready-for-agent` (unless instructed otherwise), wiring native blocking edges where supported.

Never include specific file paths or code snippets in ticket bodies (they go stale). One exception: a trimmed prototype snippet capturing a decision sharper than prose, marked as coming from a prototype.

### Templates

**Local file:**

```markdown
# <NN>: <Ticket title>

**What to build:** <end-to-end behavior from the owner's perspective>
**Surface owned:** <module, route, schema, or command>
**Blocked by:** <numbers/titles, or "None (can start immediately)">
**Status:** ready-for-agent

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2
```

**Tracker issue:**

```markdown
## Parent

<Link to parent spec issue; omit if standalone.>

## What to build

<End-to-end behavior from the owner's perspective.>

## Surface owned

<Module, route, schema, or command.>

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

<Blocking ticket refs, or "None (can start immediately)". Omit when native blocking edges are set.>
```

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
