---
name: grilling
description: Grill the owner relentlessly about a plan, decision, or idea. Use when the owner wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

# Grilling

Interview the owner relentlessly until you reach a shared understanding. Map
this as a **design tree**: every decision branches into the decisions that hang
off it.

## Build the fact base before the first round

Before the first round on a product or UI question, produce two inventories:

1. **Surface inventory**: every existing screen, button, route, command, file,
   or API that could be the thing the owner is asking about. Search the code,
   the mission document, the issue, the ADRs, and the earlier rounds. Name the
   path or URL for each.
2. **Prior-decisions inventory**: every decision the owner already made in this
   mission or in the referenced session, with the message or record that carries
   it as the source. Include rejected options and the reason.

Why: a question about a surface that already exists wastes the owner's time and
signals the agent did not read the code. The prior analytics session asked where
to put an export when the existing export button was already on the table page.

If a fact is in the environment, find it yourself. Dispatch a sub-agent when the
search is large. Do not ask the owner for a fact you can look up. The owner's
decisions are the only thing you put to them.

## Work the tree in rounds

The **frontier** is every decision whose prerequisites are already settled: the
questions you can ask now without guessing at answers you have not heard yet.
Ask the whole frontier in one round: number each question and give your
recommended answer. Then wait for the owner's answers before the next round. Why:
one question at a time hides the shape of the decision and lets the round shrink
without anyone noticing.

A question whose answer depends on another question still open in this round
belongs to a later round, not this one.

## The round ledger

Before the questions, write the ledger:

```text
Settled:
- <decision>: <source>
Rejected:
- <option>: <reason>
Open:
- Q1, Q2, ...
```

The ledger lives in the conversation. Do not write it to the tracker before the
gate. When the record is written, it carries the settled decisions, not the
ledger. Why: the record is a snapshot of current state, not a transcript of the
grill.

Every round carries the ledger. Why: the ledger is the memory of the tree. It
shows what is already decided, what is out, and what is left, so the agent does
not re-open a settled decision or re-offer a rejected option.

When a round shrinks, name every question that left and the owner answer that
removed it. Why: a round that silently drops questions looks complete while the
frontier is still open. The prior session collapsed six questions into one and
did not say which five left.

## Format a round

```text
❓ **Q1** - **<question title>**: <question body, including the options>

Why this question: <the decision it settles and what breaks without it>
Why I cannot answer it myself: <the missing fact, or why the choice is the owner's>

➡️ <your recommended answer>

---

❓ **Q2** - **<question title>**: <question body, including the options>

Why this question: <the decision it settles and what breaks without it>
Why I cannot answer it myself: <the missing fact, or why the choice is the owner's>

➡️ <your recommended answer>
```

Word each question so "yes" accepts your recommended answer. Every question
carries both why lines. If the answer is a fact you can find, find it. If it is
the owner's decision, say why it cannot be answered from the environment.

## Rules for the questions

- Never offer an option the owner already rejected. If it must appear, put it in
  the ledger as rejected with the reason. Why: re-offering a rejected option
  tells the owner their answer did not land.
- Never ask the owner to find a surface that already exists. Put the surface in
  the question. Why: that is the agent's search, not the owner's decision.
- Never ask a question whose answer is in the code, the mission, the issue, or
  the ADRs. Find it and put it in the fact base. Why: a question with a findable
  answer is a reading failure dressed as a decision.
- Never classify an owner decision as an engineering choice. If the owner said
  it, it is settled. If the agent chose it, label it `engineering` in the ledger.
  Why: relabelling an owner decision as engineering removes it from the gate.
- If the owner says they do not care, do not turn that into a decision. Record
  `owner: no preference` and choose the safe default with the reason. Why: "I do
  not care" is permission to decide, not a decision the agent can record later.

## The end

The session is done when the frontier is empty: every branch of the design tree
visited, nothing left silently assumed. Do not act on it until the owner
confirms you have reached a shared understanding. Why: the gate is the owner's
words, and a full ledger is not a substitute for their confirmation.

The confirmation is a clear decision in the conversation. If the decision is
ambiguous, ask. Do not demand a template sentence; the gate is the decision, not
a password. Do not reproduce the words or name who decided in any artifact.
