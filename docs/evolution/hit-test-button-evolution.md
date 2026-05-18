# hit-test-button — Evolution Document

**Feature**: `hitTestButton` public free function for mouse hover hit-testing
**Delivered**: 2026-05-18
**Commits**: e31b90d, 75c93b8

## Problem Solved

Every screen that supported mouse hover was reimplementing the same four-piece boilerplate:
- `hoverConstraints: LayoutConstraints` — injected from outside
- `buttonRects` computed property — re-running the layout engine
- `collectButtonFrames` traversal helper — private per-screen
- `applyHoverFocus` method — wiring it together

## Solution

```swift
public func hitTestButton(view: any View, node: LayoutNode, at point: Point) -> Int?
```

A single pure free function in `Sources/GameUI/HitTest.swift`. Returns the depth-first
traversal-order index of the first `AnyButton` whose `LayoutNode.frame` contains `point`,
or `nil`. Screen usage:

```swift
if let index = hitTestButton(view: fullMenuView, node: layout.root, at: mousePosition) {
    focusedIndex = index
}
```

## Files Changed

| File | Change |
|---|---|
| `Sources/GameUI/HitTest.swift` | NEW — public `hitTestButton` + private `hitTestNode` helper |
| `Sources/GameUI/LayoutTypes.swift` | FIX — `Rect.contains` exclusive `<` → inclusive `<=` (ODQ-01) |
| `Tests/GameUITests/acceptance/HitTestButtonTests.swift` | NEW — 14 acceptance tests |
| `Tests/GameUITests/RectTests.swift` | NEW — 2 unit tests for Rect boundary semantics |

## Key Decisions

- **Free function** (not a method on `LayoutEngine`) — keeps LayoutEngine single-responsibility
- **Inclusive boundary** — point on frame edge counts as a hit; required fixing `Rect.contains`
- **No new protocols or types** — reuses `AnyButton`, `ContainerView`, `ZStackView`, `HasFrameSize`, `AnyPaddingModifier`
- **ZStack ties** — first button in construction order wins when views overlap

## Test Coverage

104 tests total, 0 failures. 14 tests in scope for this feature:
- 13 acceptance tests covering all 8 ACs (AC-01 through AC-08)
- 1 unit test for `Rect.contains` inclusive boundary (RED_UNIT phase)
- ZStack overlap edge case + inverse boundary test added in review revision

## Mutation Testing

Skipped — Muter not reliably available. Key mutation risks documented in
`docs/product/architecture/adr-002-hit-test-button-placement.md`.
