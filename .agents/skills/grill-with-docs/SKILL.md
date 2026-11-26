---
name: grill-with-docs
description: Sharpen a plan or design with the grill, and write the glossary and ADRs as decisions land.
disable-model-invocation: true
---

# Grill with docs

Load `grilling` and `domain-modeling` with the Skill tool and run them together in the orchestrator session (`opencode-go/kimi-k3.1-pro`), delegating codebase fact-gathering to an `explore` worker (`openrouter/deepseek/deepseek-v4.1-flash-1017#max`). Loading both keeps the interview and the written domain model in sync without duplicating either procedure.

Use this inside a repo; use `grill-me` when there is no repo.
