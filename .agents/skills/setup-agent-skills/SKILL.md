---
name: setup-agent-skills
description: "Configure this repo for the agent skills: set up its issue tracker, triage label vocabulary, and domain doc layout. Run once before first use of the other skills."
disable-model-invocation: true
---

# Setup agent skills

Scaffold the per-repo configuration that the agent skills assume:

- **Issue tracker**: where issues live, detected from the remote or chosen from GitHub, GitLab, local markdown, or another tracker.
- **Triage labels**: the strings used for the two category roles and the five state roles.
- **Domain docs**: where `GLOSSARY.md` and ADRs live, and the rules for reading them.

This is a prompt-driven skill, not a deterministic script. Explore, present what you found, confirm with the owner, then write. Why: the tracker and labels are owner decisions, and a script that guesses them writes a wrong config.

## Process

### 1. Explore

Look at the current repo and read what exists. Do not assume:

- `git remote -v` and `.git/config`: which host and repo does this clone point at?
- `AGENTS.md` at the repo root: does it exist? Does it already have an `## Agent skills` section?
- `GLOSSARY.md` and `GLOSSARY-MAP.md` at the repo root, plus the legacy `CONTEXT.md` and `CONTEXT-MAP.md`. If a legacy file exists, offer to `git mv` it to its GLOSSARY name and rewrite those names in `docs/agents/domain.md`.
- `docs/adr/` and any `src/*/docs/adr/` directories.
- `docs/agents/`: does this skill's prior output already exist?
- `.scratch/`: a sign that a local-markdown issue tracker convention is already in use.
- Is the `triage` skill installed? Look for a `triage` skill folder alongside this one, or `triage` in the available skills. This decides whether Section B runs.
- Monorepo signals: a `pnpm-workspace.yaml`, a `workspaces` field in `package.json`, or a populated `packages/*` with its own `src/`. These appear only in a large multi-package repo; their absence means single-context, which is almost every repo.

### 2. Present findings and ask

Summarize what is present and what is missing. Then take the sections in order. One section, one answer, then the next. Why: a batch of questions hides which answer changed the config.

Lead each section with the recommended answer so the owner can accept it in a word. Give a one-line explainer only when the choice branches. Skip the questions in a section when exploration already settled it: Section B when `triage` is not installed, Section C when there is no monorepo. Section C still writes the single-context default; Section B writes nothing when skipped.

**Section A: Issue tracker.**

> Explainer: The issue tracker is where issues live for this repo. Skills such as `mission`, `to-spec`, `to-tickets`, and `triage` read from and write to it. They need to know whether to call `gh issue create`, write a markdown file under `.scratch/`, or follow another workflow the owner describes. Pick the place where work is tracked for this repo.

Tracker precedence: detect the host from the remote, then offer the choices.

1. Run `git remote -v`. If a remote points at GitHub, propose GitHub. If it points at GitLab (`gitlab.com` or a self-hosted host), propose GitLab.
2. If no remote points at either host, or the owner declines the detected tracker, offer all four:
   - **GitHub**: issues live in the repo's GitHub Issues. Uses the `gh` CLI.
   - **GitLab**: issues live in the repo's GitLab Issues. Uses the [`glab`](https://gitlab.com/gitlab-org/cli) CLI.
   - **Local markdown**: issues live as files under `.scratch/<feature>/` in this repo. Fits solo projects or repos without a remote.
   - **Other** (Jira, Linear, and so on): ask the owner to describe the workflow in one paragraph; record it as freeform prose.

Record the choice in `docs/agents/issue-tracker.md`. The GitHub and GitLab templates carry a "PRs as a request surface" flag, defaulted **off**. Leave it off and do not raise it: an owner who wants external PRs in the triage queue can flip the flag in the file later.

A GitHub or GitLab tracker needs a reachable repo. When the owner picks one and no `git remote` points at that host, get the repo URL and wire it up (`git init` if needed, `git remote add origin <url>`) before going further. Done when `gh repo view` or `glab repo view` prints the project from inside this directory. If it cannot, stop and tell the owner what is missing.

**Section B: Triage label vocabulary.** Skip this section when the `triage` skill is not installed; an uninstalled skill needs no labels.

If it is installed, ask exactly one question:

> Do you want to keep the default triage labels? (recommended: **yes**)

The defaults are the two category roles and the five state roles, with each label string equal to its name: `bug`, `enhancement`, `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. On yes, write them as-is. Only when the owner says no, usually because the tracker already uses other names (for example `bug:triage` for `needs-triage`), collect the overrides so `triage` applies existing labels instead of creating duplicates.

**Section C: Domain docs.** Default to **single-context**: one `GLOSSARY.md` plus `docs/adr/` at the repo root. This fits almost every repo; write it without asking.

Offer **multi-context** (a root `GLOSSARY-MAP.md` pointing to per-context `GLOSSARY.md` files) only when exploration finds monorepo signals. Then confirm the layout with the owner.

### 3. Confirm and edit

Show the owner a draft of:

- The `## Agent skills` block to add to `AGENTS.md`.
- The contents of `docs/agents/issue-tracker.md`, `docs/agents/domain.md`, and `docs/agents/triage-labels.md` (the last only when `triage` is installed).

Let the owner edit before writing. Why: the config is durable, and the owner reads it later.

### 4. Write

**Edit `AGENTS.md`:**

- If `AGENTS.md` exists, edit it.
- If it does not exist, create it.
- If an `## Agent skills` block already exists, update its contents in place. Keep the surrounding edits.

The block:

```markdown
## Agent skills

### Issue tracker

[one-line summary of where issues are tracked]. See `docs/agents/issue-tracker.md`.

### Triage labels

[one-line summary of the label vocabulary]. See `docs/agents/triage-labels.md`.

### Domain docs

[one-line summary of layout: "single-context" or "multi-context"]. See `docs/agents/domain.md`.
```

Include the `### Triage labels` sub-block, and write `docs/agents/triage-labels.md`, only when `triage` is installed and Section B ran. Otherwise omit both.

When Section B ran on GitHub or GitLab, create each configured label the tracker lacks (`gh label create` or `glab label create`).

Then write the docs files from the seed templates in this skill folder:

- [issue-tracker-github.md](./issue-tracker-github.md): GitHub issue tracker
- [issue-tracker-gitlab.md](./issue-tracker-gitlab.md): GitLab issue tracker
- [issue-tracker-local.md](./issue-tracker-local.md): local-markdown issue tracker
- [triage-labels.md](./triage-labels.md): label mapping (only when `triage` is installed)
- [domain.md](./domain.md): domain doc consumer rules and layout

For other issue trackers, write `docs/agents/issue-tracker.md` from scratch using the owner's description.

### 5. Done

Tell the owner the setup is complete and which skills read from these files. Mention that the owner can edit `docs/agents/*.md` directly later; re-run this skill only to switch issue trackers or restart from scratch.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
