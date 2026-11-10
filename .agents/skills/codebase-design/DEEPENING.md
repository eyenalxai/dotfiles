# Deepening

How to deepen a cluster of shallow modules safely, given its dependencies. This file assumes the vocabulary in [SKILL.md](SKILL.md): **module**, **interface**, **seam**, **adapter**.

## Dependency categories

Classify a candidate's dependencies before choosing the test strategy. The category decides how the deepened module is tested across its seam.

### 1. In-process

Pure computation, in-memory state, no I/O. Merge the modules and test through the new interface directly. Needs no adapter. This category is always deepenable.

### 2. Local-substitutable

Dependencies with a local test stand-in: PGLite for Postgres, an in-memory filesystem. Deepen the module when the stand-in exists. Run the stand-in in the test suite and test the deepened module through its interface. The seam is internal; add no port at the module's external interface.

### 3. Remote but owned (ports and adapters)

Own services across a network: microservices, internal APIs. Define a **port** (interface) at the seam. The deep module owns the logic; inject the transport as an **adapter**. Tests use an in-memory adapter. Production uses an HTTP, gRPC, or queue adapter.

Recommendation shape: *Define a port at the seam, implement an HTTP adapter for production and an in-memory adapter for testing, so the logic sits in one deep module even though it is deployed across a network.*

### 4. True external (mock)

Third-party services you do not control: Stripe, Twilio. The deepened module takes the external dependency as an injected port; tests provide a mock adapter.

## Seam discipline

- **One adapter means a hypothetical seam. Two adapters means a real one.** Introduce a port only when at least two adapters are justified, typically production and test. Why: a single-adapter seam is indirection with nothing to vary.
- **Keep internal seams internal.** A deep module can have internal seams, private to its implementation and used by its own tests. Do not expose an internal seam through the interface because a test uses it. Why: an exposed internal seam becomes a caller obligation.

## Testing strategy: replace, do not layer

- Delete old unit tests on shallow modules once tests at the deepened module's interface exist. Why: two test layers describe the same behavior, and the shallow layer tests code that may move.
- Write new tests at the deepened module's interface. The **interface is the test surface**.
- Assert on observable outcomes through the interface, not internal state.
- Tests must survive internal refactors because they describe behavior, not implementation. If a test has to change when the implementation changes, it is testing past the interface.
