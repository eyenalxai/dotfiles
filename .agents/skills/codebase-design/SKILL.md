---
name: codebase-design
description: Shared vocabulary for designing deep modules. Use when the owner wants to design or improve a module's interface, find deepening opportunities, decide where a seam goes, make code testable or AI-navigable, or when another skill needs the deep-module vocabulary.
---

# Codebase design

Shared vocabulary for designing **deep modules**: substantial behavior hidden behind a small interface, at a clean seam, tested through that interface. Consult this whenever an interface, seam, test surface, or deepening is in question. Do not apply it to naming or style debates; diluting the terms weakens them.

## Vocabulary (use exact terms)

Never substitute "component", "service", "unit", "API", or "boundary" for these words:

- **Module**: anything with an interface and an implementation (function, class, package, or vertical slice). *Avoid: unit, component, service.*
- **Interface**: everything a caller must know to use the module correctly: types, invariants, ordering rules, error modes, required config, and performance traits. *Avoid: API, signature (too narrow).*
- **Implementation**: code hidden inside a module. Distinct from **Adapter**: a Postgres repo can be a small adapter over a large implementation; an in-memory fake can be a large adapter over a small implementation.
- **Depth**: leverage at the interface (behavior a caller or test exercises per unit of interface learned), **not** raw line-count ratio (which rewards padding). Deep = small interface, big hidden behavior. Shallow = interface nearly as complex as implementation.
- **Seam** *(Michael Feathers)*: the place where behavior can be swapped without editing call sites; where a module's interface lives. *Avoid: boundary (collides with DDD bounded contexts).*
- **Adapter**: a concrete implementation filling a role at a seam.
- **Leverage**: caller payoff from depth (one implementation serving N callers and M tests).
- **Locality**: maintainer payoff from depth (bugs, rules, and changes concentrate in one module; fix once, fixed everywhere).

## Core principles

- **Depth belongs to the interface, not the internals.** A deep module can use small internal seams and helpers inside; callers never see them.
- **The deletion test.** Imagine deleting the module. If complexity disappears, it was a shallow pass-through (collapse it). If complexity spills across N callers, it earns its keep.
- **The interface is the test surface.** Tests cross the same seam callers cross. Reaching inside turns internal refactors into broken tests.
- **Two adapters make a real seam.** One adapter is a hypothetical seam; skip the indirection until something actually varies across it.

## Interface checklist for testability

1. **Inject dependencies** instead of instantiating them inside (`processOrder(order, gateway)` over `new StripeGateway()` inside).
2. **Return values** instead of mutating inputs or causing side effects (`calculateDiscount(cart): Discount` over mutating `cart.total`).
3. **Shrink the surface.** Fewer methods and fewer parameters mean fewer tests and higher leverage.

## Companion references

- **Survey a repo for candidates:** [improve-codebase-architecture](../improve-codebase-architecture/SKILL.md)
- **Deepen a cluster by dependency class:** [DEEPENING.md](DEEPENING.md)
- **Compare radically different interfaces:** [DESIGN-IT-TWICE.md](DESIGN-IT-TWICE.md) (runs parallel subagents to explore competing designs, then compares depth, locality, and seam placement)

When the owner challenges a finding, a recommendation, or a fact, load `pushback` before you reply.
