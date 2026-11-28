---
name: grilling
description: Grill the owner relentlessly about a plan, decision, or idea. Use when the owner wants to stress-test their thinking.
---

# Grilling

Interview the owner until you share the same understanding. Model the conversation as a **design tree**: every settled decision unlocks the dependent decisions below it.

## 1. Build the fact base before round 1

Before asking anything, build two inventories from the codebase, mission record, tracker, `GLOSSARY.md`, `docs/adr/`, and earlier rounds:

1. **Surface inventory**: existing screens, routes, commands, files, modules, or APIs that touch the request, with paths or URLs.
2. **Prior-decisions inventory**: decisions already settled in this mission or referenced sessions, with sources, plus any rejected options and why.

Asking the owner about a surface that already exists wastes their time and signals you did not read the repo. Dispatch a subagent when the search is large, and **wait for every search to finish before asking any questions**. If a factual question comes up mid-grill and the environment can answer it, look it up instead of asking the owner.

## 2. Ask the whole question frontier per round

The **question frontier** is every open decision whose prerequisites are already settled. Put the entire frontier into one numbered round directly in your chat reply (never split a grilling round into a `question` widget), with a recommended answer for each, then stop and wait. Asking one question at a time hides how decisions couple; bundling lets the owner see the full shape.

Hold back any question that depends on an unanswered question in the current round.

### Round format

Start every round with the **ledger**, then the numbered questions:

```text
Settled:
- <decision>: <source>
Rejected:
- <option>: <reason>
Open:
- Q1, Q2, ...

Q1: <Short title>

<Question and concrete options, naming any existing surfaces found in the fact base.>

Why this question: <what it decides and what breaks if guessed>
Why I cannot answer it myself: <missing fact or owner preference>

Recommended answer: <concrete recommendation>

---

Q2: <Short title>
...
```

- Keep the ledger in the conversation. Never write it to the tracker before a gate; the record holds settled decisions, not interview transcripts.
- Word every question so "yes" accepts the recommended answer.
- If a round shrinks compared to the prior round, list each dropped question and the owner answer that settled it so nothing disappears silently.

## 3. Rules

- **Never re-offer a rejected option.** Keep it in the ledger's Rejected list with its reason so it stays dead.
- **Never ask for a findable fact.** Look it up and fold it into the question.
- **Never relabel an owner decision as engineering.** If the owner decided it, record it as settled. Label only your own defaults `engineering` so owner decisions stay visible at the gate.
- **Handle "I don't care" honestly.** Record `owner: no preference` and state the safe default with its reason. Permission to pick is not an owner mandate.

## 4. Finish

The grill ends when the question frontier is empty and no assumption remains unstated. Stop and wait for the owner to confirm shared understanding in their own words before acting. Do not demand a magic phrase; if the confirmation is ambiguous, ask. Never quote the owner's words or name who decided in any durable artifact.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
