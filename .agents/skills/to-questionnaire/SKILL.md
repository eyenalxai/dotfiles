---
name: to-questionnaire
description: Turn a decision the owner cannot answer alone into a questionnaire for one person to fill in.
disable-model-invocation: true
---

# To questionnaire

Turn a decision the owner cannot make alone into a **questionnaire**: a Markdown file the owner sends to one person to fill out async, or walks through live.

**Grill the send, not the subject.** Only ask the owner about who gets the document and what decisions depend on the answers. Guessing at the subject is what the questionnaire is for.

## Procedure

1. **Who is it going to?** Ask in one exchange for the recipient's role, expertise, and relationship to the owner. This sets the tone and how much background the document needs.
2. **What do you need back?** Ask in one exchange for the exact decisions or facts the owner needs from this person. Every question must tie back to a decision; questions without one are noise.
3. **Write the file.** Save to `to-questionnaire-<slug>.md` in the current directory and report the path. Confirm every item from step 2 maps to at least one question.

## Document structure

Order questions most-important-first because async often gives you one shot. Group under `##` theme headings when there are more than five questions. Keep every question to one idea; compound questions come back half-answered.

```markdown
# <Questionnaire title>

**Purpose:** why this exists and what decision rides on it.

**From:** <owner> | **To:** <recipient> | **How answers will be used:** <destination>

## Context

One short paragraph for a reader who is not in the owner's head. Enough to answer well, never a full spec.

## How to answer

Deadline and estimated time. Note that partial answers and "I don't know" are useful: flag uncertainty instead of skipping.

## <Theme heading>

### What peak traffic should launch support?

_Why this matters: decides whether to provision burst capacity now or defer it._

>

## Anything else?

Anything we did not ask that we should know?
```

Add `_Why this matters:_` only when a question could be misread or invite a throwaway answer.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
