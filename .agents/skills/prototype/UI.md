# UI prototype

Generate **several radically different UI variations** on a single route, switchable from a floating bottom bar. The owner flips between variants in the browser, picks one (or steals bits from each), then throws the rest away.

If the question is about logic or state rather than appearance, this is the wrong branch. Use [LOGIC.md](LOGIC.md).

## When this is the right shape

- "What does this page look like?"
- "I want to see a few options for this dashboard before committing."
- "Show a different layout for the settings screen."
- A choice the owner would otherwise make between three vague mockups in their head.

## Two sub-shapes

A UI prototype is easier to judge when it sits against the rest of the app: real header, real sidebar, real data, real density. A throwaway route is a vacuum: every variant looks fine in isolation.

### Sub-shape A: adjustment to an existing page (default)

The route already exists. Variants render **on the same route**, gated by a `?variant=` URL search param. Existing data fetching, params, and auth stay. Only the rendering swaps. Use this shape whenever an existing page can host the variants.

If the prototype is for something that has no page yet but naturally lives inside one (a new dashboard section, a new settings card, a new step in an existing flow), it is still sub-shape A. Mount the variants inside the host page.

### Sub-shape B: a new page (last resort)

Use this shape only when the thing being prototyped has no existing page to live inside, such as an entirely new top-level surface or a flow with no host page.

Create a **throwaway route** following the routing convention the project already uses. Never invent a new top-level structure. Why: a new top-level structure is a production decision the prototype has not earned. Name it so it reads as a prototype (include `prototype` in the path or filename). Why: a stray merge must be obvious to a reader. Use the same `?variant=` pattern.

Before you commit to sub-shape B, check again: no existing page can host this? An empty route hides design problems that a populated one exposes.

In both sub-shapes the floating bottom bar is identical.

## Process

### 1. State the question and pick N

Default to **3 variants**. Cap at 5, because more stops being radically different and starts being noise.

Write down the plan in one line, in the prototype's location or a top-of-file comment:

> "Three variants of the settings page, switchable via `?variant=`, on the existing `/settings` route."

This works whether the owner is here to push back or not. Why: the question stays checkable later.

### 2. Generate radically different variants

Draft each variant. Hold each one to:

- The page's purpose and the data it can access.
- The project's component library and styling system (TailwindCSS, shadcn, MUI, plain CSS).
- A clear exported component name, e.g. `VariantA`, `VariantB`, `VariantC`.

Variants must be **structurally different**: different layout, different information hierarchy, different primary affordance, not different colors. Three slightly tweaked card grids are wallpaper, not a UI prototype. If two drafts come out too similar, redo one with explicit "do not use a card grid" guidance.

### 3. Wire them together

Create a single switcher component on the route:

```tsx
// pseudo-code, adapt to the project's framework
const variant = searchParams.get('variant') ?? 'A';
return (
  <>
    {variant === 'A' && <VariantA {...data} />}
    {variant === 'B' && <VariantB {...data} />}
    {variant === 'C' && <VariantC {...data} />}
    <PrototypeSwitcher variants={['A','B','C']} current={variant} />
  </>
);
```

For sub-shape A, keep all existing data fetching above the switcher; only the rendered subtree changes per variant.

For sub-shape B, the throwaway route under `/prototype/<name>` mounts the same switcher.

### 4. Build the floating switcher

A small fixed-position bar at the bottom center of the screen with three pieces:

- **Left arrow**: cycles to the previous variant (wraps around).
- **Variant label**: shows the current variant key and, when the variant exports a name, that name too, e.g. `B (Sidebar layout)`.
- **Right arrow**: cycles forward (wraps around).

Behavior:

- Clicking an arrow updates the URL search param (use the framework's router, e.g. `router.replace` on Next, `navigate` on React Router) so the variant is shareable and reload-stable.
- Keyboard: `←` and `→` also cycle. Do not intercept arrow keys when an `<input>`, `<textarea>`, or `[contenteditable]` is focused.
- Make it visually distinct from the page (a high-contrast pill, subtle shadow) so it does not read as part of the design being evaluated.
- Hide it in production builds: gate on `process.env.NODE_ENV !== 'production'` or an equivalent check, so a stray prototype merge cannot ship the bar to users.

Put the switcher in a single shared component so both sub-shapes reuse it. Locate it where shared UI lives in the project.

### 5. Hand it over

Surface the URL and the `?variant=` keys. The owner flips through when they get to it. Useful feedback sounds like "I want the header from B with the sidebar from C", which is the design they want.

### 6. Capture the answer and clean up

Once a variant wins, capture the answer (which variant and why), then capture the prototype the way the [SKILL](SKILL.md) describes. Fold the winner into the real code and move the rest to the throwaway branch, not main:

- **Sub-shape A**: fold the winner into the existing page; drop the losing variants and the switcher from main.
- **Sub-shape B**: promote the winning variant to a real route; drop the throwaway route and the switcher from main.

The full set of variants is the primary source, so it lands on the throwaway branch, not the bin. Variant components and the switcher left in main rot fast and confuse the next reader.

## Anti-patterns

- **Variants that differ only in color or copy.** That is a tweak, not a prototype. Real variants disagree about structure.
- **Sharing too much code between variants.** A shared `<Header>` is fine; a shared `<Layout>` defeats the point. Each variant is free to throw out the layout.
- **Wiring variants to real mutations.** Read-only prototypes are fine. If a variant needs to mutate, point it at a stub: the question is "what does this look like", not "does the backend work".
- **Promoting the prototype directly to production.** The variant code was written under prototype constraints (no tests, minimal error handling). Rewrite it when you fold it in.
