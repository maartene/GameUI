# Upstream Changes — progress-bar (DESIGN → DISCUSS)

For review by the product owner (`nw-product-owner`). One acceptance criterion is factually
unsatisfiable as written and has been corrected in `feature-delta.md`.

---

## UC-01 — AC-03 asserts "zero children" on a node that structurally has one

**Original (DISCUSS, `docs/feature/progress-bar/feature-delta.md`, US-01):**

> **AC-03** A `ProgressBar` inside `.frame(width: 200, height: 20)`, laid out in constraints `400 × 300`, produces a root layout node with `frame.size == Size(width: 200, height: 20)` and zero children.

**Why it is wrong:**

`LayoutEngine.layoutNode` handles `.frame(...)` via the `HasFrameSize` branch at
`Sources/GameUI/LayoutEngine.swift:38-45`:

```
let childNode = layoutNode(framed.framedContent, in: childConstraints, origin: origin)
return LayoutNode(frame: Rect(origin: origin, size: size), children: [childNode])
```

The frame-modifier node **always** carries exactly one child — the node for the content it wraps.
A root with `frame.size == 200 × 20` and zero children cannot be produced by any `.frame(...)`
declaration. The two halves of AC-03 contradict each other.

The "zero children" property is real, but it belongs to a different node: the `ProgressBar`'s own
node, which reaches the fill-constraints default at `LayoutEngine.swift:68` and is constructed with
no `children:` argument.

**New (DESIGN):**

> **AC-03** A `ProgressBar` inside `.frame(width: 200, height: 20)`, laid out in constraints `400 × 300`, produces a root layout node with `frame.size == Size(width: 200, height: 20)` and exactly one child. That child is the `ProgressBar`'s own node: `frame.size == Size(width: 200, height: 20)` and zero children of its own.

**Rationale:** the corrected AC still tests everything the original intended — that `.frame(...)`
sizes a `ProgressBar` and that `ProgressBar` is a childless leaf — but distributes the two claims
onto the nodes that actually hold them. It additionally pins the parent→child size propagation,
which the original silently omitted.

**Impact:** none on scope, effort, or slice boundaries. AC-03 remains in US-01 / Slice 01.
No other AC is affected — AC-04 (bare `ProgressBar`, no `.frame`) is correct as written, because
there the `ProgressBar` node *is* the root and does have zero children.

**Status:** applied to `feature-delta.md`. No product-owner action required unless the PO disagrees
with the reading of the layout dispatch.
