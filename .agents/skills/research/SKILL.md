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
   it. A secondary write-up is a lead, not a source. Why: a secondary source
   copies the primary one and adds its own errors; the citation must point at the
   owner of the fact.

2. Write the findings to a single Markdown file, citing each claim's source.
   Save it where the repo already keeps such notes; match the existing
   convention. If there is none, save it to `docs/research/<slug>.md` and say
   where. Why: a file the next session cannot find is not a reference.

3. Record the date, the version or commit of each source, and the question the
   research answers. Why: a fact without a date and version is stale on arrival,
   and the next session cannot tell whether it still holds.

## Rules for the findings

- **No user words.** Never reproduce the user's words, mention the user, or name
  who decided. State the decision in neutral language. The notes are current
  state only: no prior attempts, sessions, issues, or versions. Why: the notes
  are a durable reference, and a quote ties the reference to one message.
- **One claim, one citation.** Each claim carries the exact URL, file path, or
  commit, and the section or line. Why: a citation to a whole site does not let
  the next session check the claim.
- **A conflict is a finding.** When two primary sources disagree, report both,
  name the conflict, and say which one the repo or the task should follow and
  why. Do not pick one silently. Why: a silent pick hides the decision the owner
  may need to make.
- **A missing fact is a finding.** When the source does not answer the question,
  say so and name what you checked. Do not fill the gap with a plausible answer.
  Why: an invented fact is worse than a known gap, because the next session
  cannot tell it is invented.
- **A secondary source is labelled.** When a secondary source is the only
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

Why: the research is a reference the next phase loads. A reference with an
uncited claim is a lead, not a fact, and the next session cannot tell the
difference.

## Pushback

When the owner challenges a finding, a recommendation, or a fact, name the claim
and its check before you reply. A claim about the owner's position points to the
owner's message; no source, no claim. A check is evidence that can fail: a
command, a test, a doc line, a repro, or a measurement against an agreed
threshold. A failed check stops the work: show it, keep the finding, and say what
would change it, because an instruction cannot make a failing check pass. A
direct instruction does not resolve a failed check. No check means a preference
or a reversible judgment, and the owner decides it: state the tradeoff once, then
follow the instruction, because the owner owns the decision and the agent owns
the facts. When the challenge adds a new fact, change the position and name what
changed it; keep the parts that were right. Never open with agreement or an
apology; agreement needs a reason, and tone is not evidence.

Why: a model reads disagreement as evidence and folds, which turns the owner's
first guess into the final answer.
