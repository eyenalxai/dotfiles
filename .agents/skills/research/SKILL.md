---
name: research
description: Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo. Use when the owner wants a topic researched, docs or API facts gathered, reading legwork delegated to a background agent, or several independent questions fanned out together.
---

# Research

Spin up a **background agent** to do the research, so the main session keeps
working while it reads. Why: research is I/O-bound; blocking the main session on
it wastes the context window.

## Fan out

When two or more independent questions block the phase, start one background
researcher per question. Inside a mission, stay within the mission's cap. Each
researcher writes its own file. Collect the files before the gate that needs
them. Why: independent questions do not wait on each other, and one file per
question keeps the references separable. If the harness cannot run background
agents, run the questions one at a time and say so.

## The agent's job

1. Investigate the question against **primary sources**: official docs, source
   code, specs, first-party APIs. Follow every claim back to the source that owns
   it. Treat a secondary write-up as a lead, not a source. Why: a secondary source
   copies the primary one and adds its own errors; the citation must point at the
   owner of the fact.

2. Write the findings to a single Markdown file, citing each claim's source.
   Save it where the repo already keeps such notes and match the existing
   convention. If there is none, save it to `docs/research/<slug>.md` and say
   where. Why: the next session must find and load the file.

3. Record the date, the version or commit of each source, and the question the
   research answers. Why: a fact without a date and version is stale on arrival,
   and the next session cannot tell whether it still holds.

## Rules for the findings

- **No owner words.** Never reproduce the owner's words or name the person who
  decided. State the decision in neutral language. The notes are current
  state only: no prior attempts, sessions, issues, or versions. Why: the notes
  are a durable reference, and a quote ties the reference to one message.
- **One claim, one citation.** Each claim carries the exact URL, file path, or
  commit, plus the section or line. Why: a citation to a whole site does not let
  the next session check the claim.
- **A conflict is a finding.** When two primary sources disagree, report both,
  name the conflict, and say which one the repo or the task follows and why.
  Never pick one silently. Why: a silent pick hides a decision the owner may need
  to make.
- **A missing fact is a finding.** When the source does not answer the question,
  say so and name what you checked. Never fill the gap with a plausible answer.
  Why: an invented fact is worse than a known gap, because the next session
  cannot tell it is invented.
- **A secondary source is labeled.** When a secondary source is the only
  available evidence, label it `secondary` and say what it cites. Why: the
  owner can judge the trust level only if the label is visible.
- **No secrets.** Redact credentials, tokens, and personal data. Why: the notes
  are committed or shared.

## Output shape

```markdown
# <question>

Date: <YYYY-MM-DD>
Status: answered | partial | conflict

## Answer

<the shortest answer, with the confidence and the scope>

## Evidence

- <claim>: <source URL or path>, <section or line>, <version or commit>
- <claim>: <source>, <section or line>, <version or commit>

## Conflicts

- <source A> says <X>; <source B> says <Y>. The repo follows <X> because <reason>.

## Not found

- <question>: checked <sources>; no answer.

## References

- <source>: <URL or path>, <why it matters>
```

## Check before delivering

- Every claim has a citation.
- Every conflict is named, with a recommendation and a reason.
- Every missing fact is named, with what was checked.
- The date and source versions are present.
- The file is where the repo keeps research notes, or the location is stated.
- For a fan-out, every question has its own file and the main session has
  collected all files before the gate.

Why: the research is a reference the next phase loads. An uncited claim is a lead,
not a fact, and the next session cannot tell the difference.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
