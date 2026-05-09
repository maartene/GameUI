# DESIGN Decisions — wrapped-text

## Key Decisions

- [D1] **WrappedText as separate type**: `WrappedText` is a new struct in `LeafViews.swift`, not an extension of `Text`. `body` is `Never`, consistent with all existing primitive view types. Rationale: `Text` is deliberately single-line; its renderer branch emits one draw call and assumes one frame. Mixing wrapping semantics into `Text` would break the renderer's one-draw-call assumption for all existing `Text` usage.

- [D2] **Pure `wrappedLines` method**: `WrappedText` exposes `wrappedLines(measurer:maxWidth:) -> [String]` as its only non-trivial public API. The method is pure (no side effects, no stored state), deterministic, and contains no Foundation imports. Both the layout engine and the renderer call it independently. The algorithm lives in exactly one place.

- [D3] **Direct cast in `layoutNode`**: The `layoutNode` function gains one new `if let wt = view as? WrappedText` branch. No new protocol is introduced. No `ContainerView` conformance. This is consistent with the existing style used for `AnyButton` (protocol cast) and `ZStackView` (protocol cast) and `Text` (direct type cast).

- [D4] **ODQ-01 resolved as Option C**: The layout engine and renderer coordinate through `wrappedLines`, not through stored data on `LayoutNode` and not through duplicated algorithm. User rationale (verbatim): *"I'd rather have the renderer as dumb as possible."*

---

## Architecture Summary

- **Pattern**: Modular extension to existing `LayoutEngine` — one new `layoutNode` branch and one new renderer branch. No new architectural layers.
- **Paradigm**: Protocol-oriented value types (consistent with existing codebase). All new types are structs. No classes, no actors beyond what Swift 6.2 requires for `Sendable`.
- **Key components**:
  - `WrappedText` struct — owns string, fontSize, color, and line-splitting algorithm
  - `layoutWrappedTextNode` branch — detects `WrappedText`, calls `wrappedLines`, builds synthetic child `LayoutNode` array
  - Renderer branch — detects `WrappedText`, calls `wrappedLines`, zips with `node.children`, emits draw calls

---

## Reuse Analysis

| Existing Component | File | Overlap | Decision | Justification |
|---|---|---|---|---|
| `Text` | `Sources/GameUI/LeafViews.swift` | Primitive view that measures and renders a single string | CREATE NEW | `Text` is deliberately single-line; its renderer emits one draw call and assumes one frame. Mixing wrapping semantics into `Text` would break the renderer's one-draw-call assumption for all existing `Text` nodes. |
| `layoutTextNode` | `Sources/GameUI/LayoutEngine.swift` | Text measurement fallback logic (`fontSize * charCount`) | DUPLICATE INLINE | The fallback is 4 lines. Extraction into a shared helper is premature at this scale and would entangle two distinct measurement paths. |
| `ContainerView` | `Sources/GameUI/Containers.swift` | Children storage + vertical recursion pattern | NO REUSE (direct cast) | `WrappedText` has no `spacing` model, no `axis` property, and is not substitutable for `ContainerView`. A direct `is WrappedText` cast inside `layoutNode` is consistent with the existing style for `AnyButton` and `ZStackView`. |

---

## Technology Stack

- **Swift 6.2**: existing project language. No new dependency introduced.
- **`Float` geometry**: no Foundation/CGFloat (existing constraint, Linux-compatible). `Size`, `Rect`, `Point` are project-internal types used throughout.

---

## Constraints Established

- `wrappedLines` is called at layout time AND render time. This is safe because the method is deterministic (same inputs → same outputs always).
- No alignment parameter in this pass. Alignment defaults to `.leading`. Alignment support is deferred to a future iteration.
- Root frame width = `constraints.maxWidth` (not the longest line's measured width). This ensures the root node always fills the available horizontal space.
- `lineHeight = fontSize` (consistent with the fallback measurement in `layoutTextNode`: `height = textView.fontSize`).
- No changes to `LayoutNode`, `LayoutTree`, or `LayoutEngine` public API surface.

---

## Upstream Changes

- US-03 AC updated: the acceptance criterion "WrappedText.lines: [String]" is replaced by: "The renderer calls `wt.wrappedLines(measurer:maxWidth:)` and zips the result with `node.children`; each element of the zip produces one draw call."

---

## References

- `docs/product/architecture/brief.md` — full architecture document
- `docs/product/architecture/adr-001-wrappedtext-decomposition.md` — ODQ-01 decision record
- `Sources/GameUI/LeafViews.swift` — existing leaf view pattern
- `Sources/GameUI/LayoutEngine.swift` — existing `layoutNode` branch pattern
- `Sources/GameUI/Containers.swift` — `ContainerView` protocol (not reused)
