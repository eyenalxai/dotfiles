---
name: setup-agent-skills
description: "Configure this repo for the agent skills: set up its issue tracker, triage label vocabulary, and domain doc layout. Run once before first use of the other skills."
disable-model-invocation: true
---

# Setup agent skills

Scaffold the per-repo configuration the mission skills expect:

- **Issue tracker**: GitHub, GitLab, local markdown, or another tracker (`docs/agents/issue-tracker.md`).
- **Triage labels**: category and state role mapping (`docs/agents/triage-labels.md`, only when `triage` is installed).
- **Domain docs**: `GLOSSARY.md` and `docs/adr/` layout (`docs/agents/domain.md`).

Prompt-driven, not a blind script: explore first, confirm owner decisions, then write.

## Process

### 1. Explore

Inspect the repo directly; do not assume:

- `git remote -v` and `.git/config` (host and repo).
- `AGENTS.md` at repo root (exists? already has `## Agent skills`?).
- `GLOSSARY.md`, `GLOSSARY-MAP.md`, plus legacy `CONTEXT.md` / `CONTEXT-MAP.md` (if legacy files exist, offer to `git mv` them to GLOSSARY names and update `docs/agents/domain.md`).
- `docs/adr/`, `src/*/docs/adr/`, `docs/agents/`, `.scratch/`.
- Whether `triage` is installed alongside this skill or in available skills (decides whether Section B runs).
- Monorepo signals (`pnpm-workspace.yaml`, `package.json` `workspaces`, or populated `packages/*/src/`). Absence means single-context.

### 2. Present findings and ask (one section at a time)

Summarize what exists and what is missing. Walk sections A, B, and C sequentially (one answer before the next) so each choice stays clear. Lead every question with the recommended answer so the owner can accept in one word.

**Section A: Issue tracker.**
1. If `git remote -v` points at GitHub, recommend **GitHub** (`gh`). If GitLab (`gitlab.com` or self-hosted), recommend **GitLab** (`glab`).
2. Otherwise (or if declined), offer all four: **GitHub**, **GitLab**, **Local markdown** (`.scratch/<feature>/`), or **Other** (Jira, Linear, etc.; ask for a one-paragraph workflow description).
3. Keep the template's "PRs as a request surface" flag **off** without raising it; the owner can flip it later.
4. For GitHub/GitLab with no remote yet, wire up `git init` / `git remote add origin <url>` and confirm `gh repo view` or `glab repo view` succeeds before proceeding.

**Section B: Triage labels.** Skip entirely if `triage` is not installed (write nothing). Otherwise ask one question:
> Keep default triage labels (`bug`, `enhancement`, `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`)? (recommended: **yes**)

Only collect overrides when the owner says no, so `triage` maps to existing tracker labels instead of creating duplicates.

**Section C: Domain docs.** Default to **single-context** (`GLOSSARY.md` + `docs/adr/` at root) without asking unless monorepo signals appeared in step 1. Only on monorepos, offer **multi-context** (`GLOSSARY-MAP.md` pointing to per-context glossaries) and confirm.

### 3. Confirm before writing

Show drafts of the `## Agent skills` block for `AGENTS.md` and each `docs/agents/*.md` file to create. Let the owner edit before writing.

### 4. Write

Update or create `AGENTS.md` (editing `## Agent skills` in place while keeping surrounding content):

```markdown
## Agent skills

### Issue tracker

<one-line summary>. See `docs/agents/issue-tracker.md`.

### Triage labels

<one-line summary>. See `docs/agents/triage-labels.md`.

### Domain docs

<single-context or multi-context summary>. See `docs/agents/domain.md`.
```

Omit `### Triage labels` and `docs/agents/triage-labels.md` when Section B was skipped.

Write `docs/agents/*.md` from the templates in this folder:
- [issue-tracker-github.md](./issue-tracker-github.md)
- [issue-tracker-gitlab.md](./issue-tracker-gitlab.md)
- [issue-tracker-local.md](./issue-tracker-local.md)
- [triage-labels.md](./triage-labels.md)
- [domain.md](./domain.md)
- Or write `docs/agents/issue-tracker.md` from the owner's description for another tracker.

When Section B ran on GitHub or GitLab, create any missing labels with `gh label create` / `glab label create`.

### 5. Finish

Confirm setup is complete, list which skills consume the files, and note that `docs/agents/*.md` can be edited directly later (re-run this skill only to switch trackers or reset).

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
