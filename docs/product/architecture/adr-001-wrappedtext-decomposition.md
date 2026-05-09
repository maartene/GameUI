# ADR-001: WrappedText Line Decomposition Strategy (ODQ-01)

## Status

Accepted

---

## Context

`LayoutNode` carries no string payload — it stores only geometry (`Rect`, children). This is deliberate: the layout tree is pure frame data and must not encode view-type-specific state.

This creates a coordination problem. The layout engine must know how many lines to produce (to set the root frame height). The renderer must know what string to draw in each line (to emit one draw call per line). Both parties need the same decomposition of a wrapped string into lines, but neither can read it from `LayoutNode`.

Three resolution strategies were identified:

**Option A — Atomic node (renderer handles multi-line internally)**
The layout engine produces a single `LayoutNode` with the full string payload stored somewhere. The renderer performs its own line-splitting when it encounters a wrapped-text node. No children in the layout tree.

**Option B — Renderer re-splits independently**
The layout engine splits lines during layout and produces synthetic child nodes. The renderer independently re-splits the same string using its own (duplicated) algorithm. Both sides produce lines, but the algorithm lives in two places.

**Option C — Pure `wrappedLines` method, called by both sides**
`WrappedText` exposes a pure method `wrappedLines(measurer:maxWidth:) -> [String]`. The layout engine calls it once to produce synthetic child `LayoutNode` entries. The renderer calls it again to retrieve the line strings. The algorithm lives in exactly one place on the type that owns the data.

The product decision additionally required: no mutation, no reference types, no new protocols, no changes to `LayoutNode`/`LayoutTree`/`LayoutEngine` public API.

---

## Decision

**Option C**: `WrappedText` exposes a pure method `wrappedLines(measurer:maxWidth:) -> [String]`. This method is the single source of truth for line splitting. Both the layout engine (`layoutWrappedTextNode` branch) and the renderer (`renderNode` branch) call it independently.

The layout engine uses the return value to determine `lineCount` (for root frame height) and to produce one synthetic `Text` child node per line. The renderer uses the return value to retrieve the line strings and zip them with the child nodes from the layout tree.

Root frame dimensions:
- `width = constraints.maxWidth`
- `height = lineCount × fontSize` (where `fontSize` is `WrappedText.fontSize`)

The rationale in the user's own words: *"I'd rather have the renderer as dumb as possible."*

---

## Alternatives Considered

### Option A — Atomic node, renderer handles multi-line

**Evaluation**: The renderer must contain the line-splitting algorithm. This makes the renderer non-trivial to implement and couples splitting logic to rendering logic. Every renderer author must implement wrapping correctly. Rejected because it maximises renderer complexity and places algorithm responsibility outside the owning type.

**Quality attribute impact**: Violates Maintainability (#3 priority). A renderer author cannot add support in under 15 minutes if they must implement wrapping themselves.

### Option B — Renderer re-splits independently (algorithm duplicated outside the type)

**Evaluation**: The layout engine and renderer each implement their own splitting. If they diverge (different fallback, different rounding), child node count and line count become inconsistent, causing index-out-of-bounds or blank lines. The algorithm lives outside `WrappedText`, meaning a change to wrapping logic requires two coordinated edits. Rejected as fragile.

**Quality attribute impact**: Violates Correctness (#2 priority) under divergence. Violates Maintainability (#3 priority) by splitting responsibility.

### Mutation / reference type approach

**Evaluation**: Storing computed lines as mutable state on `WrappedText` (or a reference-type wrapper) would avoid double computation but breaks the value-type model of the entire library. Every existing view type is a struct with `body: Never`. Introducing a reference type or mutation at this boundary would be inconsistent and potentially break `Sendable` conformance requirements. Rejected.

**Quality attribute impact**: Violates Purity (#4 priority). Inconsistent with existing codebase paradigm.

---

## Consequences

### Positive

- Algorithm ownership is clear: `WrappedText.wrappedLines` is the single place to fix a wrapping bug.
- Renderer branch is as simple as possible: cast, call, zip, draw.
- No changes to `LayoutNode`, `LayoutTree`, or `LayoutEngine` public API.
- `WrappedText` is fully testable in isolation (pure function, no renderer dependency).
- Pattern is consistent with existing `is AnyButton` / `is ContainerView` / `is ZStackView` branches in `layoutNode`.

### Negative / Accepted Trade-offs

- `wrappedLines` is called twice per render frame (once during layout, once during render). This is accepted because: (a) the method is O(n) on short strings (UI text, not documents), (b) it is deterministic so double-call produces identical results, (c) caching would require mutable state or a shared cache that contradicts the value-type model.
- Renderer author must know to call `wrappedLines` rather than reading lines from the node. This is mitigated by: (a) documentation on `WrappedText`, (b) the method is the only public API beyond stored properties, (c) the renderer AC specifies this call explicitly.

---

## References

- `Sources/GameUI/LeafViews.swift` — existing leaf view pattern (`Text`, `Button`, `Rectangle`)
- `Sources/GameUI/LayoutEngine.swift` — existing `layoutNode` branch pattern
- `docs/feature/wrapped-text/design/wave-decisions.md` — DESIGN wave decisions summary
