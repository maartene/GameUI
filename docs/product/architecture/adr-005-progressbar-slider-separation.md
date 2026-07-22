# ADR-005: ProgressBar / Slider Separation and In-View Value Clamping

## Status

Accepted

---

## Context

The `progress-bar` feature adds a display-only horizontal bar:

```swift
public struct ProgressBar: View {
    public let value: Float
    public let label: String
    public let fillColor: Color
    public let trackColor: Color
    public var clampedValue: Float { ... }   // always in 0...1
}
```

The user framed the request as *"sort of like the slider, but without the 'drag handle'"*. That
framing raises two architectural questions that must be answered before implementation.

### Question 1 — Is `ProgressBar` a new type, or a mode of `Slider`?

`Slider` already exists and is structurally near-identical:

```swift
public struct Slider: View {
    public let value: Float
    public let label: String
    public let onTap: (@Sendable (Float) -> Void)?
}
```

This is exactly the situation ADR-003 addressed for padding, where the answer was *unify*:
uniform padding was found to be a genuine special case of directional padding, and the two were
collapsed behind one protocol. ADR-003's reasoning turns on a specific test:

> In an immutable value-type system (Swift 6.2 structs, no mutation after init) the problem
> dissolves: `PaddingModifier(amount: a)` is factually equivalent to
> `DirectionalPaddingModifier(x: a, y: a)` — **there is no operation that distinguishes them
> post-construction**, and no invariant that can be violated because nothing can be written.

Applying the same test to `ProgressBar` and `Slider` is the crux of this decision. Three options
were identified.

**Option A — Unify: add a mode flag to `Slider`.** `Slider(value:label:onTap:showsHandle:)`, with
`ProgressBar` as a factory or typealias for `showsHandle: false`.

**Option B — Extract a shared protocol.** Introduce `AnyFillableBar` with `value`/`label`, and have
both `Slider` and `ProgressBar` conform, in the shape of `AnyDirectionalPaddingModifier`.

**Option C — Separate types, no shared abstraction.** `ProgressBar` is a new leaf primitive in its
own file. `Slider` is not touched.

### Question 2 — Where does out-of-range clamping live?

`Slider` stores `value` with no guard. Live game state produces values outside `0…1` — a shield
recharge burst overshooting to `1.4`, damage applied before the frame's own clamp giving `-0.2`,
or a division by a destroyed hull's zero max-shield giving `NaN`. Unclamped, the renderer paints
fill past the end of the track.

Options: clamp in the view (single guarantee, every renderer benefits) or clamp in the renderer
(matches `Slider`'s current behaviour, but every renderer author must remember).

---

## Decision

### Decision 1 — Option C: separate types, no shared abstraction

`ProgressBar` is a new `public struct` in `Sources/GameUI/ProgressBar.swift`. `Slider` is not
generalised, not unified, and not modified.

**Rationale — ADR-003's own test fails here.**

ADR-003 unified padding because *no operation distinguished* the two types post-construction. For
`ProgressBar` and `Slider`, an operation plainly does: **invoking `onTap`**. A `Slider` with
`showsHandle: false` still carries a callback that a renderer or input layer can fire; a
`ProgressBar` categorically cannot be interacted with. That is an observable behavioural difference
surviving construction, which is exactly the condition ADR-003 required to be absent. The padding
precedent therefore argues *against* unification here rather than for it — the analogy holds only
until the test is actually applied.

The relationship is also inverted from the square/rectangle case. Uniform padding is a *narrowing*
of directional padding (fewer degrees of freedom, same operations). `ProgressBar` is not a narrowing
of `Slider`; `Slider` is `ProgressBar` **plus an affordance**. Unifying would mean the display-only
type inherits an interaction surface it must then be documented as never using — precisely the
outcome DISCUSS D5 forbids.

Option B (shared protocol) is rejected as premature. A protocol in this codebase earns its place by
serving a dispatch site — `AnyButton`, `ContainerView`, `AnyDirectionalPaddingModifier` each exist
because `layoutNode` or `hitTestNode` must branch on them. `AnyFillableBar` would have **zero**
dispatch sites: neither `Slider` nor `ProgressBar` has a `layoutNode` branch, and neither is
hit-tested. It would be an abstraction with no consumer, adding a protocol to the public surface
for the sake of expressing a resemblance.

The cost of Option C is two types that look alike. That cost is real but bounded: `ProgressBar` is
~20 lines and both types are frozen value shapes with no behaviour to drift.

### Decision 2 — Clamp inside `ProgressBar`, via a computed property

```swift
public var clampedValue: Float {
    if !(value > 0) { return 0 }   // negated comparison: NaN lands here
    if value > 1 { return 1 }
    return value
}
```

`value` remains readable verbatim; `clampedValue` is the renderer-facing accessor.

**Rationale.** This follows ADR-001's stated principle — *"I'd rather have the renderer as dumb as
possible"* — and the ADR-001/ADR-004 pattern of exposing a pure derived accessor
(`wrappedLines`, `clippedLines`) on the type that owns the data, so the rule lives in exactly one
place instead of once per renderer.

Computed rather than clamped-at-init: it satisfies the "`value` readable as declared" requirement
structurally rather than by discipline, adds no storage, and costs one or two comparisons on a read
that happens once per bar per frame.

**The `min`/`max` trap is why this is an ADR and not an implementation detail.** The obvious
`min(1, max(0, value))` is wrong: Swift's `min`/`max` propagate NaN, so a NaN input returns NaN and
the guarantee silently fails at the exact input it most needs to hold. The negated comparison
`!(value > 0)` is NaN-safe because every comparison against NaN is false, so NaN falls into the
zero branch. Verified across `0.65`, `0.0`, `1.0`, `1.4`, `-0.2`, `NaN`, `±infinity`.

---

## Consequences

**Positive.** Renderers get an unconditional `0…1` guarantee with no defensive code. `ProgressBar`
cannot be made interactive by accident — there is no callback to invoke. Zero existing source files
are modified, so no regression is structurally possible. `label` remains available for renderers
that draw a caption.

**Negative — accepted.** `Slider` and `ProgressBar` now differ in value safety: `Slider.value` is
still unguarded. This is a real inconsistency in the public API. It is accepted for this feature
because retrofitting `Slider` changes the behaviour of a shipped type and belongs in its own change
with its own acceptance criteria. Recorded as ODQ-PB-03; if `Slider` is later given the same
treatment, this ADR should be superseded by one covering both.

**Negative — accepted.** Two structurally similar types invite the question "why not one?" for any
future reader. This ADR is the answer, and is the reason the reasoning is recorded at length rather
than as a one-line verdict.

**Constraint created.** `ProgressBar` must never conform to `AnyButton`, `ContainerView`,
`ZStackView`, `HasFrameSize`, or `AnyDirectionalPaddingModifier`. Each conformance silently
redirects both `layoutNode` and `hitTestNode` and would break the childless-node and
never-hit-tested guarantees that the renderer contract depends on.

---

## Alternatives Considered

### Option A — Mode flag on `Slider`

**Evaluation.** Produces a type with two meanings governed by a boolean, where roughly half the
property set is meaningless in each mode (`onTap` is dead when `showsHandle` is false). Every
renderer must branch on the flag, and the flag's default silently decides whether existing `Slider`
call sites keep their handle. Rejected: it fails ADR-003's distinguishing-operation test and
violates DISCUSS D5.

**Quality attribute impact.** Violates Safety (#1) — a display-only widget would carry a live,
invocable callback. Violates Maintainability (#3) — renderer authors must learn a mode matrix
rather than one cast per type.

### Option B — Shared `AnyFillableBar` protocol

**Evaluation.** Adds a public protocol with no dispatch site, since neither type appears in
`layoutNode` or `hitTestNode`. Every existing protocol in this codebase exists to serve a branch;
this one would exist only to express a resemblance. Rejected as premature abstraction. If a third
bar-like type appears **and** a dispatch site materialises, this is the option to revisit.

**Quality attribute impact.** Neutral on Safety and Correctness; negative on Maintainability by
enlarging the public surface without a consumer.

### Clamping in the renderer

**Evaluation.** Matches `Slider`'s current behaviour and keeps `ProgressBar` a pure data holder.
Rejected because it distributes a safety rule across every renderer implementation, where a single
omission reproduces exactly the overflow bug JOB-06 exists to eliminate. Directly contradicts
ADR-001's renderer-dumbness principle.

**Quality attribute impact.** Violates Safety (#1), the project's top-ranked attribute.

---

*Supersedes nothing. Related: ADR-001 (renderer dumbness, pure derived accessors), ADR-003
(immutable-value unification test), ADR-004 (pure accessor as renderer contract).*
