---
name: research
description: Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo. Use when the owner wants a topic researched, docs or API facts gathered, reading legwork delegated to a background agent, or several independent questions fanned out together.
---

# Research

Investigate a question against primary sources and save a cited Markdown file in the repo.

## Background execution and fan-out

Run the investigation in a background subagent so heavy reading does not bloat the main session. When two or more independent questions block a phase, fan out one background researcher per question (staying within the mission cap of 10), each writing its own file. Collect every file before the gate that depends on it. If the harness cannot run background agents, run questions sequentially and say so.

## Code before web (for software questions)

1. **Check disk first.** Read the manifest and lockfile for the exact pinned version. Inspect repo code, docs, examples, installed dependency source, vendored copies, or a path the owner named. Docs sites describe latest; pinned source is what actually runs.
2. **Fetch upstream if disk source is missing or minified.** Clone or fetch the upstream repo at the pinned tag or commit.
3. **Trace the actual execution path.** Start at the entry point and read the implementation, types, tests (which capture edge cases prose omits), and changelog (which dates behavior changes).
4. **Cite file, line, and version/commit** for every claim so a later session can open the exact proof.

For non-code questions (pricing, hosted API terms, quotas), use official first-party documentation and state that the answer rests on prose rather than code. Treat secondary write-ups as leads to find primary sources, never as proof.

## Write the findings file

Save to the repo's existing research directory, or `docs/research/<slug>.md` if none exists. One file per question on a fan-out so references stay separable.

Rules for the file:

- **Neutral current state only.** Never quote conversation words, name who decided, or log prior attempts/sessions.
- **One claim, one citation.** Exact URL or file path, plus section or line, plus version/commit. Whole-site links are rejected.
- **Name conflicts explicitly.** When two primary sources disagree, report both, name the conflict, and state which one the repo follows and why. Never pick silently.
- **Name missing facts explicitly.** When sources do not answer the question, state what was checked and leave it unanswered. Never invent a plausible fill-in.
- **Label secondary-only evidence.** If no primary source exists, mark the claim `secondary` and note what it cites.
- **Redact secrets.** Strip credentials, tokens, and PII before writing.

## Output shape

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

## Check before delivering

- [ ] Every claim carries a file/line or URL/section citation plus date and version.
- [ ] Pinned source code was read for code claims, or its absence is stated.
- [ ] Conflicts and missing facts are surfaced, never smoothed over.
- [ ] On a fan-out, every question produced its own file before any gate opens.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
