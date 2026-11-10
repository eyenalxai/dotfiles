---
name: prototype
description: Build a throwaway prototype to answer a design question. Use when the owner wants to sanity-check whether a state model or logic feels right, or explore what a UI looks like.
---

# Prototype

A prototype is **throwaway code that answers a question**. The question decides the shape.

## Pick a branch

Identify the question being answered, using the owner's prompt, the surrounding code, or a direct question when the owner is available:

- **"Does this logic or state model feel right?"** → [LOGIC.md](LOGIC.md). Build a single shareable HTML file (free-play buttons plus tabbed guided walkthroughs) that pushes the state machine through cases that are hard to reason about on paper, and that a non-developer can drive.
- **"What does this look like?"** → [UI.md](UI.md). Generate several radically different UI variations on a single route, switchable via a URL search param and a floating bottom bar.

The two branches produce different artifacts, so a wrong branch wastes the prototype. When the question is ambiguous and the owner is unreachable, default to the branch that matches the surrounding code: a backend module goes to logic; a page or component goes to UI. State the assumption at the top of the prototype.

## Rules that apply to both

1. **Throwaway from day one, and marked.** Locate the prototype code next to the module or page it prototypes so context is clear, and name it so a casual reader sees it is a prototype, not production. For throwaway UI routes, follow the routing convention the project already uses; never invent a new top-level structure. Why: a prototype that looks production gets kept, and unowned code outlives the question.
2. **Trivial to run.** A UI prototype starts from one command in the project's task runner: `pnpm <name>`, `python <path>`, `bun <path>`. A logic demo is a single HTML file the owner double-clicks. Starting it requires no thought. Why: friction stops the owner from running it, and an unrun prototype answers nothing.
3. **No persistence by default.** State lives in memory. Persistence is the thing the prototype is _checking_, not something it depends on. If the question involves a database, hit a scratch DB or a local file with a clear "PROTOTYPE, wipe me" name. Why: a database hides the state model behind setup, and the state model is the question.
4. **Skip the polish.** No tests, no error handling beyond what makes the prototype _runnable_, no abstractions. The point is to learn fast. Why: tests and error handling answer questions the prototype is not asking, and they slow the answer.
5. **Surface the state.** After every action (logic) or on every variant switch (UI), print or render the full relevant state so the owner sees what changed. Why: the state is the thing being judged; a hidden state makes the verdict a guess.
6. **Capture it when done.** Fold any validated decision into the real code, then capture the prototype as a **primary source**: commit it to a throwaway branch, out of main, and leave a context pointer to that branch on the implementation issue. Capture the answer too (the verdict and the question it settled) in the issue or a commit. Main keeps only the validated decision. Why: the decision is the durable output; the code is evidence that the decision was tested.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
