---
name: research
description: Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo. Use when the owner wants a topic researched, docs or API facts gathered, reading legwork delegated to a background agent, or several independent questions fanned out together.
---

# Research

Investigate a question against primary sources and save a cited Markdown file in the repo.

## Roles

- **Worker (`openrouter/deepseek/deepseek-v4.1-flash-1017#max`, `general` subagent)**: always does the research in the background. Reads lockfiles, installed/vendored/upstream source, and official docs; writes the cited Markdown file; returns a compact summary (under 300 words) listing the answer, status, conflicts, gaps, and file path.
- **Orchestrator (`opencode-go/kimi-k3.1-pro`)**: frames the exact question, spawns one worker per independent question (parallel fan-out, staying within the mission cap of 10), critiques the worker's return, and presents the clean takeaway to the owner.
- **Critique loop**: if the worker cites secondary blog posts as facts, skips pinned source code, glosses over a conflict, or guesses past a missing fact, send a follow-up to the **same worker `sessionID`** naming the gap and have it re-check primary sources before presenting to the owner.

If the harness cannot run background subagents, run questions one at a time and say so.

## Worker procedure

Include these instructions in the worker prompt:

### 1. Code before web (for software questions)

1. **Check disk first.** Read the manifest and lockfile for the exact pinned version. Inspect repo code, docs, examples, installed dependency source, vendored copies, or a path the owner named. Docs sites describe latest; pinned source is what actually runs.
2. **Fetch upstream if disk source is missing or minified.** Clone or fetch the upstream repo at the pinned tag or commit.
3. **Trace the actual execution path.** Start at the entry point and read the implementation, types, tests (which capture edge cases prose omits), and changelog (which dates behavior changes).
4. **Cite file, line, and version/commit** for every claim so a later session can open the exact proof.

For non-code questions (pricing, hosted API terms, quotas), use official first-party documentation and state that the answer rests on prose rather than code. Treat secondary write-ups as leads to find primary sources, never as proof.

### 2. Write the findings file

Save to the repo's existing research directory, or `docs/research/<slug>.md` if none exists. One file per question on a fan-out so references stay separable.

Rules for the file:

- **Neutral current state only.** Never quote conversation words, name who decided, or log prior attempts/sessions.
- **One claim, one citation.** Exact URL or file path, plus section or line, plus version/commit. Whole-site links are rejected.
- **Name conflicts explicitly.** When two primary sources disagree, report both, name the conflict, and state which one the repo follows and why. Never pick silently.
- **Name missing facts explicitly.** When sources do not answer the question, state what was checked and leave it unanswered. Never invent a plausible fill-in.
- **Label secondary-only evidence.** If no primary source exists, mark the claim `secondary` and note what it cites.
- **Redact secrets.** Strip credentials, tokens, and PII before writing.

### Output shape

```markdown
# <question>

Date: <YYYY-MM-DD>
Status: answered | partial | conflict

## Answer

<Shortest direct answer, with confidence and scope.>

## Evidence

- <claim>: <path or URL>, <section or line>, <version or commit>

## Conflicts

- <source A> says <X>; <source B> says <Y>. Repo follows <X> because <reason>. (Omit if none.)

## Not found

- <gap>: checked <sources>; no answer. (Omit if none.)

## References

- <source>: <path or URL>, <why it matters>
```

## Orchestrator check before delivering

Verify from the worker's summary (inspecting the file only if something looks weak):

- [ ] Every claim carries a file/line or URL/section citation plus date and version.
- [ ] Pinned source code was read for code claims, or its absence is stated.
- [ ] Conflicts and missing facts are surfaced, never smoothed over.
- [ ] On a fan-out, every question produced its own file before any gate opens.

Present the concise answer, conflicts, and file path(s) to the owner.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
