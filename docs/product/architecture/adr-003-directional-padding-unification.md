# ADR-003: Directional Padding Protocol Unification

## Status

Proposed

---

## Context

The `padding-directional` feature introduces `padding(x:y:)` — a modifier that applies independent horizontal and vertical insets to any `View`. The DISCUSS wave proposed two parallel structures: `AnyPaddingModifier` (existing, uniform) and `AnyDirectionalPaddingModifier` (new, asymmetric), each with its own dispatch branch in `layoutNode` and `hitTestNode`.

During the DESIGN wave, the question was raised: *is uniform padding a special case of directional padding, as a square is a special case of a rectangle?*

In mutable OOP this analogy causes a Liskov Substitution Principle problem: a `Square.setWidth` that must also set height breaks the substitutability contract for any `Rectangle` client that calls `setWidth` expecting only width to change. The problem is mutation-induced.

In an immutable value-type system (Swift 6.2 structs, no mutation after init) the problem dissolves: `PaddingModifier(amount: a)` is factually equivalent to `DirectionalPaddingModifier(x: a, y: a)` — there is no operation that distinguishes them post-construction, and no invariant that can be violated because nothing can be written. The protocol unification is not just safe; it is the semantically precise encoding of the relationship.

The existing `AnyPaddingModifier` protocol has the following callers inside the library:
- One dispatch branch in `layoutNode`
- One traversal branch in `hitTestNode`

It has no callers in the public API signature surface (it is not a return type, parameter type, or stored property type in any `public` function or struct). External callers that reference `AnyPaddingModifier` by name would be implementing their own layout engine or hit-test traversal — a narrow use case.

---

## Decision

Unify at the protocol level (Option B from the architecture proposal), with a deprecation layer that preserves a migration path to Option C.

1. Declare `AnyDirectionalPaddingModifier` with three members: `paddingX: Float`, `paddingY: Float`, `paddingContent: any View`.
2. Extend `PaddingModifier` to conform: `var paddingX: Float { amount }`, `var paddingY: Float { amount }`.
3. **Deprecate** (do not yet remove) `AnyPaddingModifier` with `@available(*, deprecated, renamed: "AnyDirectionalPaddingModifier")`.
4. **Deprecate** (do not yet remove) `paddingAmount` on `PaddingModifier` with `@available(*, deprecated, message: "Use paddingX or paddingY via AnyDirectionalPaddingModifier")`.
5. Replace `layoutPaddingNode` with `layoutDirectionalPaddingNode(_ padded: any AnyDirectionalPaddingModifier, in constraints: LayoutConstraints, origin: Point) -> LayoutNode`.
6. Replace `outerSizeForPaddedContent(_ content: any View, amount: Float, constraints: LayoutConstraints) -> Size` with `outerSizeForDirectionalPaddedContent(_ content: any View, paddingX: Float, paddingY: Float, constraints: LayoutConstraints) -> Size`.
7. Replace the `AnyPaddingModifier` check in `layoutNode` with a single `AnyDirectionalPaddingModifier` check.
8. Replace the `AnyPaddingModifier` check in `hitTestNode` with a single `AnyDirectionalPaddingModifier` check.
9. Preserve `padding(_ amount:)` returning `PaddingModifier<Self>` — the concrete return type and call-site are unchanged.

`PaddingModifier` itself is intentionally **not** deprecated in this PR. It remains the return type of `padding(_ amount:)`. Its deprecation is deferred to a future Option C PR that will also change `padding(_ amount:)` to return `DirectionalPaddingModifier<Self>` directly.

---

## Alternatives Considered

### Option A: Two Types, Two Protocols (DISCUSS design — status quo)

Keep `AnyPaddingModifier` and `PaddingModifier` unchanged. Add `AnyDirectionalPaddingModifier` and `DirectionalPaddingModifier` as parallel structures. Two dispatch branches in both `layoutNode` and `hitTestNode` (with dispatch-order sensitivity between them — `AnyDirectionalPaddingModifier` must be checked first, per DISCUSS D6).

**Why rejected:** Encodes a false model (the two padding types appear unrelated). Dispatch-order sensitivity becomes a permanent maintenance liability — the DISCUSS D6 risk never closes. The parallelism survives indefinitely as structural debt with no corresponding benefit once the feature is stable.

### Option C: Subsume PaddingModifier Entirely

Change `padding(_ amount:)` to return `DirectionalPaddingModifier<Self>` directly. Remove `PaddingModifier` and `AnyPaddingModifier` entirely. Single type, single protocol, maximum DRY.

**Why rejected:** Removing `PaddingModifier` as a `public` concrete type breaks any external caller that names it (type annotations, pattern matches on the concrete type). The concrete-type break is a wider public API surface than the protocol-only break in Option B. Option B achieves the same dispatch unification with a narrower breaking footprint.

---

## Consequences

### Positive

- Single dispatch branch for all padding in `layoutNode` and `hitTestNode` — dispatch-order fragility (DISCUSS D6) is permanently eliminated.
- Protocol hierarchy encodes semantic reality: uniform padding is a degenerate case of directional padding.
- `outerSizeForPaddedContent` duplication (DISCUSS D5 risk) never arises — there is one implementation for both cases.
- `padding(_ amount:)` concrete return type (`PaddingModifier<Self>`) is preserved — zero call-site migration for existing game-developer code.
- `layoutDirectionalPaddingNode` handles the uniform case transparently: when `paddingX == paddingY`, the layout is identical to the former `layoutPaddingNode` output.

### Negative

- `AnyPaddingModifier` is removed from the public API — source-breaking for external callers that reference the protocol by name. Risk assessed as low: the protocol is not part of any public function signature, and the only use case for an external caller referencing it is a custom layout engine implementation.
- `paddingAmount` is removed from `PaddingModifier`'s public surface — source-breaking for callers that access it directly. Risk assessed as low: `paddingAmount` was always a protocol-requirement accessor, not an advertised feature of `PaddingModifier`.
- Two private functions in `LayoutEngine` (`layoutPaddingNode`, `outerSizeForPaddedContent`) are replaced — zero external risk (both are `private`).
