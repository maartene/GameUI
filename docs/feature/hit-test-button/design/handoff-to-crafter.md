# Handoff to Crafter — hit-test-button

**Feature ID**: `hit-test-button`
**Wave**: DESIGN → DELIVER
**Recipient**: @nw-software-crafter
**Date**: 2026-05-18

---

## Exact Public Function Signature

```swift
public func hitTestButton(view: any View, node: LayoutNode, at point: Point) -> Int?
```

File: `Sources/GameUI/HitTest.swift` (new file)
Visibility: `public` — part of GameUI module API
Concurrency: non-isolated (no `@MainActor`, no actor annotation)
Import: no Foundation, no third-party

---

## ODQ-01 Resolution — `Rect.contains` Fix (PREREQUISITE)

`Rect.contains(_ point: Point) -> Bool` exists in `Sources/GameUI/LayoutTypes.swift` at lines 39–42.

**Current implementation (exclusive boundary):**
```
point.x >= origin.x && point.x < origin.x + size.width &&
point.y >= origin.y && point.y < origin.y + size.height
```

**Required implementation (inclusive boundary):**
```
point.x >= origin.x && point.x <= origin.x + size.width &&
point.y >= origin.y && point.y <= origin.y + size.height
```

**Crafter action**: Change `<` to `<=` on both axes. This is a one-line change (or two `<` to `<=` replacements on the same logical expression).

**Verification**: Run the full `LayoutEngineTests` suite after this change. All existing tests must remain green. None of the existing tests exercise boundary equality, so no regressions are expected.

---

## Traversal Algorithm (Pseudocode)

```
function hitTestButton(view, node, point) -> Int?:
    var buttonIndex = 0
    return hitTestNode(view, node, point, index: &buttonIndex)

function hitTestNode(view, node, point, index: inout Int) -> Int?:

    // 1. Is this view an AnyButton?
    if view is AnyButton:
        capturedIndex = index
        index += 1                         // advance counter regardless of hit
        if node.frame.contains(point):     // inclusive boundary (after Rect fix)
            return capturedIndex
        // button did not contain point — continue traversal into button content
        if let result = hitTestNode(button.anyContent, node.children[0], point, index: &index):
            return result
        return nil

    // 2. ContainerView (VStack, HStack)?
    if view is ContainerView:
        for (childView, childNode) in zip(container.containerChildren, node.children):
            if let result = hitTestNode(childView, childNode, point, index: &index):
                return result
        return nil

    // 3. ZStackView?
    if view is ZStackView:
        for (childView, childNode) in zip(zStack.zStackChildren, node.children):
            if let result = hitTestNode(childView, childNode, point, index: &index):
                return result
        return nil

    // 4. FrameModifier (HasFrameSize)?
    if view is HasFrameSize:
        return hitTestNode(framed.framedContent, node.children[0], point, index: &index)

    // 5. PaddingModifier (AnyPaddingModifier)?
    if view is AnyPaddingModifier:
        return hitTestNode(padded.paddingContent, node.children[0], point, index: &index)

    // 6. Leaf (Text, Rectangle, Texture, WrappedText, Spacer) — no recursion
    return nil
```

**Critical invariant**: `view` and `node` must be from the same layout pass (structurally isomorphic). Document this as a precondition in the API comment.

**Button index semantics**: The index counts only `AnyButton` views encountered in traversal order (depth-first, construction order). Non-button views do not increment the counter.

**Button recursion note**: After matching a button, the traversal descends into `button.anyContent` against `node.children[0]` only if the button's frame did not contain the point AND nested views might be AnyButton themselves. Re-read step 1 carefully: if the button frame contains the point, return immediately. If not, recurse to find any nested buttons — but in practice, standard usage does not nest buttons inside buttons. The implementation must handle this edge case without crashing.

---

## File Placement

| Action | File | Description |
|---|---|---|
| CREATE | `Sources/GameUI/HitTest.swift` | Public free function + private recursive helper |
| MODIFY | `Sources/GameUI/LayoutTypes.swift` | Change `<` to `<=` in `Rect.contains` (lines 39–42) |

No other files require modification.

---

## Acceptance Criteria

All AC from US-01. The crafter owns implementation; these AC are WHAT, not HOW.

- [ ] AC-01: `hitTestButton(view:node:at:)` is a public free function in the GameUI module
- [ ] AC-02: Returns the traversal-order index of the first `AnyButton` whose `LayoutNode.frame` contains `point`
- [ ] AC-03: Returns `nil` when no `AnyButton` frame contains `point`
- [ ] AC-04: Traversal is depth-first, matching view-tree construction order
- [ ] AC-05: Works when buttons are nested inside containers (VStack, HStack, FrameModifier)
- [ ] AC-06: Point on the boundary of a frame counts as contained (inclusive bounds)
- [ ] AC-07: Does not invoke any button's action during traversal
- [ ] AC-08: Does not require Foundation or any third-party import

---

## Test Approach

Framework: Swift Testing (`@Test`, `#expect`). No XCTest.

**Test file**: `Tests/GameUITests/HitTestButtonTests.swift` (new file)

Suggested test structure mirrors the BDD scenarios from `user-stories.md`:

1. Single button, point inside → returns 0
2. Two flat buttons, point in first → returns 0
3. Two flat buttons, point in second → returns 1
4. Point between buttons → returns nil
5. Point outside all buttons → returns nil
6. Button nested inside VStack, point inside → returns correct index
7. Button nested inside FrameModifier inside VStack, point inside → correct index
8. Point on exact frame boundary (top-left corner) → returns index (AC-06)
9. Point on bottom-right boundary corner → returns index (AC-06)
10. No buttons in view tree → returns nil
11. Action is never called during traversal (verify with a spy/counter)

**Mutation testing strategy**: per-feature (as specified in CLAUDE.md). Apply mutation testing to `HitTest.swift` after GREEN. Key mutation targets:
- `<=` vs `<` in `Rect.contains` — confirmed by AC-06
- `&&` vs `||` in `Rect.contains`
- Off-by-one in button index counter
- Early return vs continue in traversal

---

## Architectural Constraints to Enforce During Implementation

1. No `import Foundation` in `HitTest.swift`
2. No `class` keyword in `HitTest.swift`
3. No new `protocol` or `struct` definitions in `HitTest.swift`
4. `hitTestButton` must be non-isolated (no `@MainActor`)
5. `hitTestNode` private helper must never call `button.anyAction` or `button.anyAction()`
6. The `index` counter increments only when a view is cast successfully to `AnyButton`, not for every node visited

---

## Dependency Confirmed

- `AnyButton.isFocused: Bool` — from `button-focus-state` feature, merged. Not used by `hitTestButton`; no interaction.
- `LayoutEngine.layout(_:in:)` producing correct child origins for nested containers — existing, verified in `LayoutEngineTests`.
