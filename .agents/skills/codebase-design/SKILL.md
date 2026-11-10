---
name: codebase-design
description: Shared vocabulary for designing deep modules. Use when the owner wants to design or improve a module's interface, find deepening opportunities, decide where a seam goes, make code testable or AI-navigable, or when another skill needs the deep-module vocabulary.
---

# Codebase design

Design **deep modules**: a lot of behavior behind a small interface, at a clean seam, testable through that interface. Use this language and these principles wherever code is designed or restructured. The aim is leverage for callers and locality for maintainers, tested through the interface.

## When to use

Use this vocabulary when a module's interface is in question: a seam, a test surface, a deepening. Do not use it for naming or style; it is about depth and leverage. Why: the terms are precise, and using them for unrelated decisions dilutes them.

## Glossary

Use these terms exactly. Never substitute "component," "service," "API," or "boundary." Why: consistent language is the whole point.

**Module**: anything with an interface and an implementation. Deliberately scale-agnostic: a function, class, package, or tier-spanning slice. _Avoid_: unit, component, service.

**Interface**: everything a caller must know to use the module as intended: the type signature plus invariants, ordering constraints, error modes, required configuration, and performance characteristics. _Avoid_: API, signature (too narrow, they refer only to the type-level surface).

**Implementation**: the code inside a module. Distinct from **Adapter**: a thing can be a small adapter with a large implementation (a Postgres repository) or a large adapter with a small implementation (an in-memory fake). Use "adapter" when the seam is the topic; use "implementation" otherwise.

**Depth**: leverage at the interface. The amount of behavior a caller or test can exercise per unit of interface they learn. A module is **deep** when a large amount of behavior sits behind a small interface, and **shallow** when the interface is nearly as complex as the implementation.

**Seam** _(Michael Feathers)_: a place where you can alter behavior without editing in that place; the location at which a module's interface lives. Where to put the seam is its own design decision, distinct from what goes behind it. _Avoid_: boundary (overloaded with DDD's bounded context).

**Adapter**: a concrete thing that satisfies an interface at a seam. It describes a role (what slot it fills), not substance (what is inside).

**Leverage**: what callers get from depth: more capability per unit of interface they learn. One implementation pays back across N call sites and M tests.

**Locality**: what maintainers get from depth: change, bugs, knowledge, and verification concentrate in one place rather than spreading across callers. Fix once, fixed everywhere.

## Deep vs shallow

A **deep module** has a small interface over a large implementation:

```
┌───────────────────────┐
│  Small interface      │  few methods, simple params
├───────────────────────┤
│  Deep implementation  │  complex logic hidden
└───────────────────────┘
```

A **shallow module** has a large interface over a thin implementation. Avoid it:

```
┌───────────────────────────────┐
│  Large interface              │  many methods, complex params
├───────────────────────────────┤
│  Thin implementation          │  passes through
└───────────────────────────────┘
```

When designing an interface, ask:

- Can I reduce the number of methods?
- Can I simplify the parameters?
- Can I hide more complexity inside?

## Principles

- **Depth is a property of the interface, not the implementation.** A deep module can be composed internally of small, mockable, swappable parts; those parts are not part of the interface. A module can have **internal seams** (private to its implementation, used by its own tests) and an **external seam** at its interface.
- **The deletion test.** Imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep.
- **The interface is the test surface.** Callers and tests cross the same seam. If you want to test past the interface, the module is probably the wrong shape. Why: a test that reaches inside the module turns every internal change into a test change.
- **One adapter means a hypothetical seam. Two adapters means a real one.** Do not introduce a seam unless something actually varies across it.

## Designing for testability

Design interfaces that make testing natural:

1. **Accept dependencies, do not create them.**

   ```typescript
   // Testable
   function processOrder(order, paymentGateway) {}

   // Hard to test
   function processOrder(order) {
     const gateway = new StripeGateway();
   }
   ```

2. **Return results, do not produce side effects.**

   ```typescript
   // Testable
   function calculateDiscount(cart): Discount {}

   // Hard to test
   function applyDiscount(cart): void {
     cart.total -= discount;
   }
   ```

3. **Keep the surface small.** Fewer methods means fewer tests. Fewer parameters means simpler setup.

## Relationships

- A **module** has exactly one **interface**.
- **Depth** is a property of a **module**, measured against its **interface**.
- A **seam** is where a **module**'s **interface** lives.
- An **adapter** sits at a **seam** and satisfies the **interface**.
- **Depth** produces **leverage** for callers and **locality** for maintainers.

## Rejected framings

- **Depth as the ratio of implementation lines to interface lines** (Ousterhout) rewards padding the implementation. This skill measures depth as leverage.
- **Interface as the TypeScript `interface` keyword or a class's public methods** is too narrow. Interface here includes every fact a caller must know.
- **Boundary** is overloaded with DDD's bounded context. Say **seam** or **interface**.

## Going deeper

- **Survey a codebase for deepening candidates**: [improve-codebase-architecture](../improve-codebase-architecture/SKILL.md). A planning pass that deepens modules, simplifies interfaces, finds implicit state machines and unenforced invariants, then returns an executable plan with steps, tests, and dependency order.
- **Deepen a cluster given its dependencies**: [DEEPENING.md](DEEPENING.md). Dependency categories, seam discipline, and tests that replace rather than layer.
- **Explore alternative interfaces**: [DESIGN-IT-TWICE.md](DESIGN-IT-TWICE.md). Run parallel subagents that design the interface several different ways, then compare depth, locality, and seam placement.

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
