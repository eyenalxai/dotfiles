# Logic prototype

A single, self-contained HTML file (a **shareable demo**) that lets anyone drive a state model by clicking buttons. Use this when the question is about **business logic, state transitions, or data shape**: the kind of thing that looks reasonable on paper but only feels wrong once you push it through real cases.

Because it is one file with nothing to install, you can hand it to a non-developer (a designer, a PM, a domain expert) and let them feel the model for themselves. Write it in their language, not the code's.

## When this is the right shape

- "I am not sure if this state machine handles the edge case where X then Y."
- "Does this data model actually let me represent the case where..."
- "I want to feel out what the API looks like before writing it."
- Anything where someone wants to **press buttons and watch state change**.

If the question is "what does this look like," this is the wrong branch. Use [UI.md](UI.md).

## Process

### 1. State the question

Before writing code, write down the state model and the question you are prototyping. Put one paragraph at the top of the demo in a visible intro rather than a code comment. A logic prototype that answers the wrong question is waste, so make the question explicit and checkable later, whether the owner is watching now or returning to it AFK.

### 2. Isolate the logic in a portable module

Put the logic that answers the question in a single `<script>` block written as a small, pure module that could be lifted out and dropped into the real codebase later. The page around it is throwaway; the module is not.

The shape depends on the question:

- **A pure reducer**: `(state, action) => state`. Use it when actions are discrete events and state is a single value.
- **A state machine**: explicit states and transitions. Use it when "which actions are legal right now" is part of the question.
- **A small set of pure functions** over a plain data type. Use it when there is no implicit current state, only transformations.
- **A class or module with a clear method surface**. Use it when the logic owns ongoing internal state.

Pick the shape that fits the question, not the one easiest to wire to a page. Keep it pure: no DOM, no `document`, no button handlers reaching inside it. The page calls into it; nothing flows the other direction. This makes the prototype useful past its own lifetime: once the question is answered, the validated reducer, machine, or function set lifts into the real module on its own.

### 3. Build the shareable HTML file

One file, plain HTML/CSS/JS: no framework, no bundler, no server, everything inline so it opens by double-click and survives being emailed around. Anyone can run it by opening it.

Write it for a non-developer. Every label uses **domain language**, not code: buttons and state read like the business, not the reducer. Explain in plain words what is happening.

Lay it out with a clean hierarchy, top to bottom:

1. **Title and one-line explanation** of what this demo lets you explore (the question from step 1).
2. **Current state**: the full relevant state as a readable panel with labeled fields, not a raw JSON dump, re-rendered after every click so the change is visible. Call out what changed where it helps a non-developer follow.
3. **Free-play buttons**: one button per action, always available, so anyone can poke at the model in any order. Each click dispatches its action and re-renders the state.
4. **Guided walkthroughs**: a set of **scenarios**, one per tab. Each tab holds a short plain-language description of the scenario (the situation it sets up and what to watch for) and underneath it, the ordered **buttons to press** for that scenario. Each step is a real button: clicking it performs that action and moves to the next step. Starting a walkthrough resets to a known initial state so the scenario runs the same way every time.

Choose scenarios that show the awkward cases, the ones hard to reason about on paper: the happy path, a tricky edge case, an attempt at something illegal.

Keep it restrained: clean typography, generous spacing, one accent color. No animations, no gimmicks: nothing competes with the state and the buttons.

### 4. Hand it over

Send the file, or open it for them. They click through the walkthroughs and free-play when they get to it; the interesting moments are when they say "wait, that cannot be possible" or "huh, I assumed X would be different". Those are the bugs in the _idea_, which is the point. If they want new actions or a new scenario, add them. Prototypes evolve.

### 5. Capture the answer and the prototype

Once the prototype has answered its question, capture the answer, then capture the prototype the way the [SKILL](SKILL.md) describes. The logic-specific mapping: the validated reducer, machine, or function set lifts into the real module as the absorbed decision; the HTML shell rides along to the throwaway branch that keeps the prototype as a primary source, and as one self-contained file it stays trivially re-runnable there.

## Anti-patterns

- **Do not add tests.** A prototype that needs tests is no longer a prototype.
- **Do not wire it to the real database.** Use in-memory state unless the question is specifically about persistence.
- **Do not generalize.** No "what if we wanted to support X later." The prototype answers one question.
- **Do not blur the logic and the page.** If the pure module references the DOM, `document`, or button handlers, it is no longer liftable. Keep the page as a thin shell over a pure module.
- **Do not reach for a framework, bundler, or server.** One file the recipient double-clicks; a React app or a dev server defeats "shareable".
- **Do not ship the HTML shell into production.** The page is optimized for being clicked through by hand. The logic module behind it is the part worth keeping.
