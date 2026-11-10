# GLOSSARY.md format

## Structure

```md
# {Context Name}

{One or two sentences that describe what this context is and why it exists.}

## Language

**Order**:
{A description of the term in one or two sentences.}
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request

**Customer**:
A person or organization that places orders.
_Avoid_: Client, buyer, account
```

## Rules

- **Be opinionated.** When several words exist for one concept, pick one and list the others under `_Avoid_`. Why: one term per concept keeps specs, issues, and code aligned.
- **Keep definitions tight.** One or two sentences, maximum. Define what the term is, not what it does. Why: a definition of behavior turns the glossary into a spec.
- **Include only terms specific to this project's context.** General programming concepts such as timeouts, error types, and utility patterns do not belong, even when the project uses them heavily. Before adding a term, ask whether it is unique to this context or general. Only the former belongs. Why: general terms say nothing about this project.
- **Group terms under subheadings when clusters emerge.** A flat list is fine when every term belongs to one area.

## Single vs multi-context repos

**Single context (most repos):** one `GLOSSARY.md` at the repo root.

**Multiple contexts:** a `GLOSSARY-MAP.md` at the repo root lists the contexts, where they live, and how they relate:

```md
# Glossary Map

## Contexts

- [Ordering](./src/ordering/GLOSSARY.md): receives and tracks customer orders
- [Billing](./src/billing/GLOSSARY.md): generates invoices and processes payments
- [Fulfillment](./src/fulfillment/GLOSSARY.md): manages warehouse picking and shipping

## Relationships

- **Ordering → Fulfillment**: Ordering emits `OrderPlaced` events; Fulfillment consumes them to start picking
- **Fulfillment → Billing**: Fulfillment emits `ShipmentDispatched` events; Billing consumes them to generate invoices
- **Ordering ↔ Billing**: Shared types for `CustomerId` and `Money`
```

Use this rule to infer which structure applies:

- If `GLOSSARY-MAP.md` exists, read it to find the contexts.
- If only a root `GLOSSARY.md` exists, the repo is single-context.
- If neither exists, create a root `GLOSSARY.md` lazily when the first term is resolved.

When multiple contexts exist, infer which one the current topic relates to. If the context is unclear, ask the owner.
