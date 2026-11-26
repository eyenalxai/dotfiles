---
name: diagnosing-bugs
description: Diagnosis loop for hard bugs and performance regressions. Use when the owner says "diagnose"/"debug this", or reports something broken/throwing/failing/slow.
---

# Diagnosing bugs

Build a tight, red-capable feedback loop before theorizing. Guessing from code without a repro is the exact failure this skill prevents. Skip a phase only for an explicit reason.

## Roles

- **Worker (`openrouter/deepseek/deepseek-v4.1-flash-1017#max`, `general` subagent)**: runs all tree-level legwork in Phases 1, 2, 4, 5, and 6 (building/tightening the loop, reproducing and minimizing, running probes/profilers, writing the regression test and fix after the gate, and stripping `[DEBUG-...]` logs). Returns compact, redacted reports (under 400 words).
- **Orchestrator (`opencode-go/kimi-k3.1-pro`)**: critiques the worker's loop and evidence (sending follow-ups to the same worker `sessionID` if the loop is flaky, slow, or not testing the real symptom), shapes and ranks the 3 to 5 falsifiable hypotheses with the owner (Phase 3), holds the gate before Phase 5, and writes the final explanation/PR.

## Redact every secret

Before showing any command, output, or artifact, replace secrets, credentials, and auth headers with `<REDACTED>`. Drive scripts from environment variables and quote only signal lines from captured traces. If redacted output is insufficient to diagnose, stop and ask the owner.

## Phase 1: build a tight feedback loop

**This phase decides the diagnosis.** Dispatch the worker (`openrouter/deepseek/deepseek-v4.1-flash-1017#max`) with `GLOSSARY.md` and relevant ADRs to build a fast, deterministic, red-capable command, trying these shapes in order:

1. Failing test at the bug's seam (unit, integration, or e2e).
2. Curl/HTTP script against a local dev server.
3. CLI invocation on a fixture diffed against expected stdout.
4. Headless browser script asserting on DOM, console, or network.
5. Replay of a captured trace/request/event log in isolation.
6. Minimal throwaway harness calling the buggy path directly.
7. Property/fuzz loop (1,000 random inputs) for intermittent wrong output.
8. Bisection script for `git bisect run` when a regression appeared between two known states.
9. Differential loop comparing old vs. new versions or two configs.
10. HITL bash script (`scripts/hitl-loop.template.sh`) only when a human must click.

**Tighten it:** cache setup, assert on the exact reported symptom (never "did not crash"), pin time/RNG/filesystem/network. Target seconds, not minutes. For flaky bugs, amplify until reproducible (loop 100x, add concurrency/stress, narrow timing windows); a 50% flake is debuggable, a 1% flake is not.

**Cannot build a loop?** Stop. List what the worker tried and ask the owner for (a) repro environment access, (b) a redacted artifact (HAR, logs, core dump, timestamped video), or (c) permission for temporary production instrumentation. Never theorize without a loop.

**Exit check (orchestrator verifies):** one command already executed at least once (redacted output shown) that is red-capable on the exact symptom, deterministic, fast, and runnable unattended. If weak, send the worker back on its `sessionID` before Phase 2.

## Phase 2: reproduce and minimize

Have the worker confirm the loop reproduces the **exact reported symptom** across runs, then shrink inputs, callers, config, and steps one at a time until removing any remaining element turns the loop green. A minimal repro shrinks the hypothesis space and becomes the regression test. Do not enter Phase 3 until both reproduced and minimized.

## Phase 3: hypothesize (orchestrator + owner)

Generate **3 to 5 ranked, falsifiable hypotheses** before running probes (one hypothesis anchors on your first guess). Each must state a concrete prediction:

> "If `<cause>` is responsible, then `<change Y>` will eliminate the symptom or `<change Z>` will make it worse."

Discard any guess that cannot state a prediction. Show the ranked list to the owner so they can re-rank or rule items out with domain knowledge; proceed with your ranking if the owner is away.

## Phase 4: instrument

Send one hypothesis at a time to the worker (`sessionID` follow-up). Change one variable per probe so results stay unambiguous.

- **Tool order:** debugger/REPL breakpoint first, targeted boundary logs second, never "log everything and grep".
- **Tag every debug log** with a unique prefix (`[DEBUG-a4f2]`) so cleanup is one grep.
- **Performance regressions:** skip logs. Establish a baseline measurement (timing harness, profiler, query plan) and bisect. Measure first, fix second.

## Phase 5: fix and regression test

**Gate check first.** Read the mission record or conversation. A Bug path requires the **scope and understanding gate** (repro + fix direction) before editing production code. A diagnosis is not approval; if pending, stop and ask.

Dispatch the fix to the worker (`sessionID` follow-up). Write the regression test **before** the fix, but only if a **correct seam** exists (one that exercises the real call-site failure chain). If the architecture lacks a honest seam, do not fake a shallow unit test; record the missing seam as a finding.

When a seam exists:
1. Turn the minimized repro into a failing test at that seam and watch it fail (if mutating code/fixtures to prove red, diff against pristine to confirm the mutation landed).
2. Apply the fix and watch it pass.
3. Re-run the Phase 1 loop against the original, unminimized scenario.

Critique the worker's fix at the forest level, run `code-review`, and write the PR via `pr`.

## Phase 6: cleanup checklist

Verify via the worker before declaring done:

- [ ] Original Phase 1 repro passes cleanly.
- [ ] Regression test passes (or missing seam is documented).
- [ ] Zero `[DEBUG-...]` logs remain (`grep` verified).
- [ ] Throwaway prototypes deleted or moved to a marked debug location.
- [ ] Winning hypothesis stated in the commit or PR body for future debuggers.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
