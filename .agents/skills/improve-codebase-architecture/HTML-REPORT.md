# HTML report format

Specification for the single-file owner HTML report written by `improve-codebase-architecture`. Saved to the OS temp directory alongside the JSON candidate index.

Uses Tailwind and Mermaid from CDNs (requires network when opened). Mix Mermaid for graph/state diagrams with hand-built HTML/SVG for mass diagrams and cross-sections so the report reads like a deliberate architectural brief rather than generic auto-diagrams.

## Scaffold

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Architecture review for {{repo name}}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script type="module">
      import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
      mermaid.initialize({ startOnLoad: true, theme: "neutral", securityLevel: "loose" });
    </script>
    <style>
      .seam { stroke-dasharray: 4 4; }
      .leak { stroke: #dc2626; }
      .deep { background: linear-gradient(135deg, #0f172a, #1e293b); }
    </style>
  </head>
  <body class="bg-stone-50 text-slate-900 font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header>...</header>
      <section id="coverage">...</section>
      <section id="state-machines" class="space-y-10">...</section>
      <section id="invariants">...</section>
      <section id="test-suite" class="space-y-10">...</section>
      <section id="candidates" class="space-y-10">...</section>
      <section id="top-recommendation">...</section>
    </main>
  </body>
</html>
```

## Sections (in exact order)

1. **Header**: repo name, date, and compact visual legend (solid box = module, dashed line = seam, red arrow = leakage, thick dark box = deep module, rounded box = state, dashed edge = unknown transition). Skip introductory prose.
2. **Coverage**: completeness table (area, lifecycles audited, invariants audited, not audited, why), followed by the test inventory summary (category, count, files, keep/delete, plus non-functional checks noted out of scope).
3. **State machines**: one `<article id="state-NN">` card per lifecycle:
   - Title + badges (`Strong` emerald, `Worth exploring` amber, `Speculative` slate; plus `implicit` or `partly explicit`).
   - Compact transition table (decision-bearing transitions only) + `file:line` evidence.
   - Side-by-side before/after Mermaid `stateDiagram-v2` (dashed edges for unknown/unenforced transitions).
   - One-sentence Problem, Recommended form (naming removed illegal states/transitions + acceptance test category), one-line Interface change, Plan block, and Wins bullets (6 words max each).
4. **Invariants**: single table using [MODEL-AUDIT.md](MODEL-AUDIT.md) columns plus `Rank` (`high / high / M / LOW`). Badge current enforcement (`none` in red). Group by family only when >8 rows exist, omitting empty families. Render each invariant's Plan block below the table rather than turning rows into cards.
5. **Test suite**: if no deletions, write one line (`No tests outside the policy.`). Otherwise render one `<article id="test-01">` sweep card when deletions cross modules or have no carrying candidate: title, badges (`test`), evidence, before/after counts (`120 -> 40`), one-sentence Problem and Solution, Plan block with deletions grouped by module + replacements, and short Wins bullets.
6. **Deepening candidates**: one `<article id="deepening-NN">` card per candidate:
   - Title + strength badge + dependency category tag (`in-process`, `local-substitutable`, `ports & adapters`, `mock`).
   - `file:line` evidence (`font-mono text-sm`), side-by-side before/after diagram, one-sentence Problem, one-sentence Solution, one-line Interface change, one-line Deletion test, Plan block, Wins bullets (<=6 words each), and amber ADR callout if applicable.
   - Zero explanatory paragraphs: if a diagram needs a paragraph, redraw the diagram.
7. **Top recommendation**: one larger card naming the #1 verdict and why, full execution sequence (#1 expanded, #2 and #3 named, blockers noted), anchor link matching card `id`, and a before/after interface sketch (entry points, invariants, ordering, error modes, internals hidden behind the seam).

## Plan block

Compact bordered block under each finding carrying the [candidate format](MODEL-AUDIT.md#candidate-format) action fields plus rank on one row: files, seam-level steps (no implementation code), `tests_deleted` grouped by module with replacements, acceptance test with category (or zero-delete check for sweeps), `emil-unslop-code` check, and `blocked_by`.

## Diagram patterns (mix across cards)

- **Mermaid `flowchart` / `sequenceDiagram`**: tangled call chains or multi-hop round trips. Always quote edge labels in pipe form (`-->|"label"|`, `-.->|"leak"|`) so periods do not break parsing. Color leakage red (`#dc2626`) and deep modules dark.
- **Mermaid `stateDiagram-v2`**: lifecycles (before with illegal edges vs. after explicit machine).
- **Hand-built boxes + inline SVG arrows**: thick-bordered deep module absorbing faded internals.
- **Cross-section (`h-12 border-l-4`)**: six thin pass-through bands collapsing into one consolidated band.
- **Mass diagram**: interface-height vs. implementation-height rectangles showing shallow -> deep shift.
- **Call-graph collapse**: nested call tree folding into one module with internal calls dimmed.

## Visual and prose rules

- **Layout**: single column (`py-12` sections, `space-y-10` cards), `font-serif` headings, `font-sans` body, no sidebar/dashboard chrome. Static HTML beyond Tailwind CDN + Mermaid ESM.
- **Palette**: emerald accent, red for leakage/`none`, amber for warnings/`Worth exploring`. No extra hues.
- **Diagrams**: ~320px height so before/after sit side by side without scrolling; `text-xs uppercase tracking-wider` schematic labels.
- **Exact vocabulary**: use only `module`, `interface`, `implementation`, `depth`, `deep`, `shallow`, `seam`, `adapter`, `leverage`, `locality` (plus model terms `state`, `state machine`, `lifecycle`, `transition`, `invariant`, and test terms `test suite`, `test sweep`, `algorithmic logic`, `boundary IO`, `integration flow`). Never substitute `component`, `service`, `unit`, `API`, or `boundary`.
- **Specificity**: name the actual module and glossary gain in every sentence (`locality: bugs concentrate in OrderIntake`, never "easier to maintain"). Delete any sentence that would survive find-and-replace on the repo name.
