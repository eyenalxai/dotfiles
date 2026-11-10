---
name: to-questionnaire
description: Turn a decision the owner cannot answer alone into a questionnaire for one person to fill in.
disable-model-invocation: true
---

# To questionnaire

Turn a decision the owner cannot answer alone into a **questionnaire**: a Markdown document the owner hands to one person to fill in async, or fills out with them in a meeting. The recipient holds knowledge the owner lacks; the questionnaire pulls it out.

**Grill the send, not the subject.** Interview the owner only about the send, which they can always answer: who it goes to, and what they need back. The questions in the document then target the gap between what the recipient knows and what the owner needs. Why: guessing at the subject is what the questionnaire is for; the owner owns the send.

1. **Who is it going to?** Ask, in one exchange, the recipient's role, expertise, and relationship to the owner. This fixes the questionnaire's tone and how much context it must carry. Done when you know who the recipient is and what they know that the owner does not. Why: tone and context depend on who reads it.

2. **What do you need back?** Ask, in one exchange, the specific decisions or facts the owner cannot resolve alone and needs from this person. Done when you have a concrete list of what the owner must be able to do or decide afterward. Why: a question with no decision behind it is noise.

3. **Write the questionnaire.** Draft questions aimed at the gap from steps 1 and 2, following the document structure below. Write it to `to-questionnaire-<slug>.md` in the current directory, with the slug from the topic, and report the path. Done when the file exists and every item the owner named in step 2 has a question. Why: one idea per question is answerable; a compound question gets a partial answer.

## Document structure

Frame the document as a **discovery questionnaire**: the owner lacks context, the recipient holds it. Order questions most-important-first, since async means you may only get one pass. Group them under `##` headings by theme once there are more than five. Write it using the template below.

```markdown
# <Questionnaire title>

**Purpose:** why this questionnaire exists and the decision riding on it.

**From:** <the owner>, **To:** <the recipient>, **How your answers will be used:** <where they go>

## Context

One paragraph orienting a recipient who was not in the owner's head. Enough to answer well, not a page.

## How to answer

State the deadline and the estimated effort. Partial answers and "I don't know" are useful: flag anything you are unsure of rather than skipping it.

## <Theme heading>

One `##` section per theme. Under each, its questions, most-important-first. Every question is one idea, never compound, with an answer stub directly beneath, and a one-line _why this matters_ only where a question could be misread or invite a throwaway answer.

### What load is the system expected to handle at launch?

_Why this matters: it decides whether to provision for burst traffic now or defer it._

>

## Anything else?

A closing catch-all: anything we did not ask that we need to know?
```

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
