---
name: diagnosing-bugs
description: Diagnosis loop for hard bugs and performance regressions. Use when the owner says "diagnose"/"debug this", or reports something broken/throwing/failing/slow.
---

# Diagnosing bugs

A discipline for hard bugs. Skip a phase only when the reason is explicit. Why: a skipped phase hides the gap until the fix fails.

When exploring the codebase, read `GLOSSARY.md` (if it exists) to get a clear mental model of the relevant modules, and check ADRs in the area you touch.

## Redact

This skill shows commands, outputs, and captured artifacts. **Redact every secret first**: write `<REDACTED>` in its place. Why: output shown here lands in the transcript and the handoff. Build loops against env vars, so the credential stays in the environment rather than in what you show. Captured artifacts carry auth headers: quote only the lines that carry the signal.

If the redacted output is not enough to diagnose the bug, say so and ask the owner.

## Phase 1: Build a feedback loop

**This phase decides the diagnosis.** The other phases are mechanical. A **tight** pass/fail signal for the bug, one that goes red on _this_ bug, finds the cause; bisection, hypothesis testing, and instrumentation consume it. Without a loop, reading code is guesswork.

Spend disproportionate effort here.

### Ways to construct a loop, in this order

1. **Failing test** at the seam that reaches the bug: unit, integration, or e2e.
2. **Curl or HTTP script** against a running dev server.
3. **CLI invocation** with a fixture input, diffing stdout against a known-correct snapshot.
4. **Headless browser script** (Playwright or Puppeteer) that drives the UI and asserts on DOM, console, or network.
5. **Replay a captured trace.** Save a real network request, payload, or event log to disk, then replay it through the code path in isolation.
6. **Throwaway harness.** Spin up the minimal subset of the system (one service, mocked dependencies) that exercises the bug code path with a single function call.
7. **Property or fuzz loop.** For a sometimes-wrong output, run 1000 random inputs and look for the failure mode.
8. **Bisection harness.** For a bug that appeared between two known states (commit, dataset, version), automate boot at state X, check, and repeat, so `git bisect run` can drive it.
9. **Differential loop.** Run the same input through the old version and the new version, or through two configs, and diff the outputs.
10. **HITL bash script.** Last resort. When a person must click, drive the person with `scripts/hitl-loop.template.sh` so the loop stays structured. Captured output feeds back to you.

### Tighten the loop

Treat the loop as a product. Once you have a loop, tighten it:

- Make it faster: cache setup, skip unrelated init, narrow the test scope.
- Make the signal sharper: assert on the specific symptom, not "did not crash".
- Make it deterministic: pin time, seed the RNG, isolate the filesystem, freeze the network.

A 2-second deterministic loop is tight. A 30-second flaky loop is close to no loop.

### Non-deterministic bugs

Aim for a higher reproduction rate; a clean repro is optional. Loop the trigger 100 times, parallelize, add stress, narrow timing windows, and inject sleeps. A 50% flake is debuggable; a 1% flake is not, so keep raising the rate until it is debuggable.

### When you cannot build a loop

Stop and say so explicitly. List what you tried. Ask the owner for (a) access to the environment that reproduces it, (b) a redacted captured artifact (HAR file, log dump, core dump, screen recording with timestamps), or (c) permission to add temporary production instrumentation. Do not hypothesize without a loop.

### Completion criterion: a tight loop that goes red

Phase 1 is done when the loop is **tight** and **red-capable**: you can name **one command** (a script path, a test invocation, a curl) that you have **already run at least once** (show the invocation and its output, redacted), and that is:

- [ ] **Red-capable**: it drives the actual bug code path and asserts the **exact symptom from the report**, so it can go red on this bug and green once fixed. Not "runs without erroring"; it must be able to _catch this specific bug_.
- [ ] **Deterministic**: same verdict every run (for flaky bugs, a pinned, high reproduction rate, per above).
- [ ] **Fast**: seconds, not minutes.
- [ ] **Agent-runnable**: you can run it unattended; a person in the loop only via `scripts/hitl-loop.template.sh`.

If you catch yourself reading code to build a theory before this command exists, **stop: jumping straight to a hypothesis is the exact failure this skill prevents.** No red-capable command, no Phase 2.

## Phase 2: Reproduce and minimize

Run the loop. Watch it go red as the bug appears.

Confirm:

- [ ] The loop produces the failure mode the **report** described, not a different nearby failure. Wrong bug, wrong fix.
- [ ] The failure is reproducible across multiple runs (for a non-deterministic bug, reproducible at a rate high enough to debug against).
- [ ] You captured the exact symptom (error message, wrong output, slow timing) so later phases can verify the fix addresses it.

### Minimize

Once the bug is red, shrink the repro to the **smallest scenario that still goes red**. Cut inputs, callers, config, data, and steps **one at a time**, re-run the loop after each cut, and keep only what is load-bearing for the failure.

Why: a minimal repro shrinks the hypothesis space in Phase 3 and becomes the clean regression test in Phase 5.

Done when **every remaining element is load-bearing**: removing any one of them makes the loop go green.

Do not proceed until you have reproduced **and** minimized.

## Phase 3: Hypothesize

Generate **3 to 5 ranked hypotheses** before testing any of them. Single-hypothesis generation anchors on the first plausible idea.

Each hypothesis must be **falsifiable**: state the prediction it makes.

> Format: "If <X> is the cause, then <changing Y> will make the bug disappear, or <changing Z> will make it worse."

If you cannot state the prediction, the hypothesis is a guess: discard or sharpen it.

**Show the ranked list to the owner before testing.** The owner can re-rank it with domain knowledge ("we just deployed a change to #3") or name hypotheses already ruled out. This checkpoint is cheap and saves time. Do not block on it; proceed with your ranking if the owner is away.

## Phase 4: Instrument

Each probe must map to a specific prediction from Phase 3. **Change one variable at a time.** Why: two changes at once leave the result ambiguous.

Tool preference:

1. **Debugger or REPL inspection** when the environment supports it. One breakpoint beats ten logs.
2. **Targeted logs** at the boundaries that distinguish hypotheses.
3. Never "log everything and grep".

**Tag every debug log** with a unique prefix, e.g. `[DEBUG-a4f2]`. Cleanup at the end becomes a single grep. Untagged logs survive; tagged logs die.

**Perf branch.** For a performance regression, logs are the wrong tool. Establish a baseline measurement (timing harness, `performance.now()`, profiler, query plan), then bisect. Measure first, fix second.

## Phase 5: Fix and regression test

Before the fix, read the issue and the gate decision. The bug path has the
scope and understanding gate: the repro and the fix direction. If the mission
record does not exist yet, the conversation holds the gate. If the gate is
pending, stop and ask. A diagnosis is not an approval. Why: the gate owns the fix
direction, and a diagnosis cannot substitute for it.

Write the regression test **before the fix**, but only when a **correct seam** exists. Why: a test written after the fix can pass for the wrong reason.

A correct seam is one where the test exercises the **real bug pattern** as it occurs at the call site. If the only available seam is too shallow (a single-caller test when the bug needs multiple callers, a unit test that cannot replicate the chain that triggered the bug), a regression test there gives false confidence.

**If no correct seam exists, that is the finding.** Note it. The codebase architecture is preventing the bug from being locked down. Flag this for the next phase.

If a correct seam exists:

1. Turn the minimized repro into a failing test at that seam.
2. Watch it fail. If you forced the red by mutating code or a fixture, `diff` against a pristine copy to prove the mutation landed before you trust it.
3. Apply the fix.
4. Watch it pass.
5. Re-run the Phase 1 feedback loop against the original, unminimized scenario.

## Phase 6: Cleanup

Required before declaring done:

- [ ] The original repro no longer reproduces (re-run the Phase 1 loop).
- [ ] The regression test passes, or the absence of a seam is documented.
- [ ] All `[DEBUG-...]` instrumentation is removed (`grep` the prefix).
- [ ] Throwaway prototypes are deleted, or moved to a marked debug location.
- [ ] The hypothesis that turned out correct is stated in the commit or PR message, so the next debugger learns.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
