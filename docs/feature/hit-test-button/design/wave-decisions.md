# DESIGN Decisions — hit-test-button

## Key Decisions

- [D1] **Function placement = `HitTest.swift` (new file, Option A).**
  Free function in a dedicated file. Two alternatives considered (append to `LayoutEngine.swift`; extension-file naming). Both rejected: Option B violates single-responsibility for `LayoutEngine`; Option C's naming convention misleads future maintainers. See ADR-002.

- [D2] **`Rect.contains` boundary = fix existing method to `<=` (inclusive).**
  ODQ-01 resolved: `Rect.contains` exists in `LayoutTypes.swift` but uses strict `<` (exclusive upper bound). AC requires inclusive. Existing method is corrected — one-line change on both axes. No second method added. Zero existing callers depend on exclusive semantics (verified by inspection).

- [D3] **No new protocols, no new types.**
  The traversal casts to `AnyButton`, `ContainerView`, `ZStackView`, `HasFrameSize`, and `AnyPaddingModifier` — all existing protocols. No new abstractions introduced.

- [D4] **Traversal helper is private.**
  `hitTestNode(_:_:at:index:)` is a private recursive helper inside `HitTest.swift`. It is not separately testable by design — it is an implementation detail. All correctness is validated through the public `hitTestButton` function via acceptance tests.

- [D5] **Button recursion: descend into `anyContent`.**
  After matching a view as `AnyButton` and recording its index, the traversal also descends into `button.anyContent`. This ensures buttons containing nested views (e.g., a `Button` wrapping a `VStack`) do not silently absorb the entire subtree. The button's index is still the first match; nested non-button views are traversed for completeness.

- [D6] **Traversal protocol-cast order mirrors `layoutNode`.**
  Priority: `AnyButton` → `ContainerView` → `ZStackView` → `HasFrameSize` → `AnyPaddingModifier` → leaf. This matches the `layoutNode` priority chain, ensuring traversal and layout agree on tree structure.

- [D7] **`WrappedText` is a leaf in hit-test traversal.**
  `WrappedText` is a text primitive; it does not conform to `AnyButton`. Its children in the layout tree are synthetic (line nodes). The hit-test traversal has no reason to descend into `WrappedText` — no `AnyButton` can be nested inside it. `WrappedText` falls through to the leaf case and terminates recursion.

## Architecture Summary

- **Pattern**: Modular monolith, direct type-cast traversal (established codebase style)
- **Paradigm**: Object-oriented / protocol-oriented value types (structs, protocols, free functions)
- **Key components**: `HitTest.swift` (new), `LayoutTypes.swift` (one-line fix), all other files unchanged
- **Style**: Pure function, no side effects, depth-first recursion

## Reuse Analysis

| Existing Component | File | Overlap | Decision | Justification |
|---|---|---|---|---|
| `Rect.contains(_ point: Point) -> Bool` | `LayoutTypes.swift` | Point containment (exclusive upper bound) | EXTEND (fix semantics) | Exists but uses `<`; AC requires `<=`. One-line fix. Zero existing callers depend on exclusive semantics. |
| `AnyButton` protocol | `LeafViews.swift` | Type identity for button detection | REUSE AS-IS | Already used in `LayoutEngine`; same pattern. |
| `ContainerView` protocol | `Containers.swift` | `containerChildren` for recursion | REUSE AS-IS | Correct seam for descending into VStack/HStack children. |
| `ZStackView` protocol | `Containers.swift` | `zStackChildren` for z-ordered recursion | REUSE AS-IS | Correct seam for ZStack children. |
| `HasFrameSize` protocol | `View.swift` | `framedContent` for FrameModifier descent | REUSE AS-IS | Consistent with `layoutNode` pattern. |
| `AnyPaddingModifier` protocol | `View.swift` | `paddingContent` for PaddingModifier descent | REUSE AS-IS | Consistent with `layoutNode` pattern. |
| `layoutNode` (private) | `LayoutEngine.swift` | Depth-first traversal pattern | REFERENCE ONLY | Private; layout-coupled. New free function replicates the traversal pattern without sharing code. |
| `LayoutEngine` struct | `LayoutEngine.swift` | Existing public API | NO NEW MEMBERS | ODQ-02 pre-answered: free function, not a method. |

## Technology Stack

No changes to the existing stack. Extends existing choices.

| Choice | Version / Detail | Rationale | License |
|---|---|---|---|
| Swift | 6.2 | Existing project language. `hitTestButton` is non-isolated; compiles under strict concurrency. | Apache 2.0 |
| `Float` geometry | `Point`, `Size`, `Rect` (project-internal) | No Foundation, no CGFloat. Linux-compatible. | N/A |
| Swift Testing | Existing framework | Acceptance tests for `hitTestButton` use `@Test` and `#expect`. | Apache 2.0 |

## Constraints Established

- `hitTestButton` is a free function (ODQ-02, pre-answered, confirmed)
- `Rect.contains` changed from exclusive (`<`) to inclusive (`<=`) upper bound — this is a breaking semantic change, safe because zero existing callers depend on exclusive semantics
- No Foundation import in `HitTest.swift`
- No new protocols or structs
- Traversal must NOT call `anyAction` on any `AnyButton` — pure query only
- Traversal order: depth-first, view-tree construction order (invariant)
- Function is non-isolated — no `@MainActor` or actor annotation

## Upstream Changes

- **`Rect.contains` semantics corrected**: exclusive upper bound (`<`) changed to inclusive (`<=`). This change is in `LayoutTypes.swift`, a shared file. The crafter must verify all existing `LayoutEngineTests` remain green after this change. Expected result: all existing tests pass (no test currently exercises boundary equality).
- **`button-focus-state` upstream (already merged)**: `AnyButton` exposes `isFocused: Bool`. `hitTestButton` traversal uses `AnyButton` cast — consistent. `isFocused` is not used by `hitTestButton`; no interaction.
- No changes to `LayoutEngine`, `LayoutNode`, `LayoutTree`, or any container/leaf type.

## Open Design Questions — Resolved

| ODQ | Resolution |
|---|---|
| ODQ-01: Does `Rect` have `contains`? | YES — exists in `LayoutTypes.swift` line 39. Boundary is exclusive; must be fixed to inclusive. Crafter task: change `<` to `<=` on both axes. |
| ODQ-02: Free function or method? | FREE FUNCTION — pre-answered in DISCUSS wave. Confirmed: no changes to `LayoutEngine`. |
