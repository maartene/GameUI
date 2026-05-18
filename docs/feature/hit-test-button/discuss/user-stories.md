<!-- markdownlint-disable MD024 -->
# User Stories — hit-test-button

*JTBD skipped (Decision 4 = No). Feature type: library API extension (Decision 1 = Backend).*
*DIVERGE wave: not run. No prior recommendation.md or job-analysis.md.*

## System Constraints

- Swift 6.2, no Foundation import
- `Float` geometry only — `Point`, `Size`, `Rect` are project-internal types
- No new types permitted — function only, using existing `AnyButton`, `LayoutNode`, `View`
- Swift Testing framework (not XCTest) for all test artifacts
- No third-party dependencies
- Must compile with `swiftLanguageModes: [.v6]` (strict concurrency)

---

## US-01: hitTestButton — Button Hit Detection by Mouse Position

### Problem

Riku Nakamura is a game developer building SpaceSim menus. He finds it tedious
to implement the same four-piece mouse hover boilerplate (`hoverConstraints`,
`buttonRects`, `collectButtonFrames`, `applyHoverFocus`) in every screen he
writes. When a new screen is added, the boilerplate is copy-pasted and subtly
broken by the time code review catches it.

### Who

- Game screen developer | Writing a new SpaceSim screen with button hover | Wants one library call to replace four boilerplate pieces

### Elevator Pitch

Before: Riku writes `hoverConstraints: LayoutConstraints`, a `buttonRects`
computed property that re-runs the layout engine, a `collectButtonFrames`
traversal helper, and an `applyHoverFocus` method that wires it all together —
in every screen.

After: `hitTestButton(view: fullMenuView, node: layout.root, at: mousePosition)`
returns `Int?` — the traversal-order index of the first `AnyButton` whose frame
contains the point, or nil if no button is hit.

Decision enabled: Riku decides how to map the returned index to a focused
button (`if let i = hitTestButton(...) { focusedIndex = i }`). GameUI handles
frame extraction and containment testing; the screen retains full control over
what to do with the result.

### Solution

Add a free function to the GameUI public API:

```swift
public func hitTestButton(view: any View, node: LayoutNode, at point: Point) -> Int?
```

The function traverses `view` and `node` in parallel (depth-first,
construction order), collects `AnyButton` nodes, and returns the index of the
first button whose `LayoutNode.frame` contains `point`. Returns `nil` if no
button frame contains the point.

### Domain Examples

#### 1: Main Menu Hover (Happy Path)
Riku's SpaceSim main menu has three buttons: "New Game", "Load Game", "Quit".
They are laid out by LayoutEngine at y-positions 200, 260, 320. The mouse is
at Point(x: 400, y: 265). `hitTestButton` returns `1` (Load Game). Riku sets
`focusedIndex = 1`. On the next frame, "Load Game" renders with its focused
highlight.

#### 2: Cursor Between Buttons (Edge Case)
The same three-button menu. Mouse is at Point(x: 400, y: 245) — between
"New Game" (frame ends at y: 240) and "Load Game" (frame starts at y: 260).
`hitTestButton` returns `nil`. Riku's screen sets `focusedIndex = nil`. No
button is highlighted.

#### 3: Buttons Nested Inside VStack Inside FrameModifier (Nesting Case)
Riku's pause menu wraps a VStack of two buttons inside a
`FrameModifier(width: 300, height: 200)` panel. The LayoutEngine propagates
the panel origin (x: 250, y: 150) into child frames. Mouse is at
Point(x: 380, y: 220) — inside the second button's frame (which starts at
y: 200 within the panel, so absolute y: 350... wait — concrete values:
panel origin y: 150, first button height: 40, second button origin y: 190,
absolute frame origin y: 340). Mouse at Point(x: 380, y: 355) is inside
the second button. `hitTestButton` returns `1`.

#### (Additional) 4: Point on Frame Boundary (Boundary Condition)
A button's frame is Rect(origin: Point(x: 0, y: 100), size: Size(width: 200, height: 40)).
Mouse is exactly at Point(x: 0, y: 100) — the top-left corner of the frame.
`hitTestButton` returns `0` (point on boundary counts as contained).

### UAT Scenarios (BDD)

```gherkin
Scenario: Cursor over first button identifies it by index
  Given Riku has a view with "New Game" and "Load Game" buttons
  And both buttons have been laid out by LayoutEngine into a LayoutTree
  And "New Game" occupies the frame at y: 200, height: 40
  When hitTestButton is called with Point(x: 400, y: 210)
  Then hitTestButton returns 0

Scenario: Cursor over second button identifies it by index
  Given Riku has a view with "New Game" and "Load Game" buttons
  And both buttons have been laid out by LayoutEngine into a LayoutTree
  And "Load Game" occupies the frame at y: 260, height: 40
  When hitTestButton is called with Point(x: 400, y: 270)
  Then hitTestButton returns 1

Scenario: Cursor between buttons returns nil
  Given Riku has a view with buttons at y: 200 and y: 260 (each 40pt tall)
  And a matching LayoutTree
  When hitTestButton is called with Point(x: 400, y: 245)
  Then hitTestButton returns nil

Scenario: Cursor outside all buttons returns nil
  Given Riku has a view with two buttons in a 800x600 layout
  And a matching LayoutTree
  When hitTestButton is called with Point(x: 400, y: 10)
  Then hitTestButton returns nil

Scenario: Button nested inside a VStack is reachable by traversal
  Given Riku has a VStack containing "Resume" and "Quit" buttons
  And the VStack is laid out with "Resume" at y: 0 and "Quit" at y: 40 (height: 40 each)
  And a matching LayoutTree
  When hitTestButton is called with Point(x: 50, y: 50)
  Then hitTestButton returns 1

Scenario: Point on frame boundary counts as a hit
  Given a single button laid out at Rect(origin: Point(x:0, y:100), size: Size(width:200, height:40))
  And a matching LayoutTree
  When hitTestButton is called with Point(x: 0, y: 100)
  Then hitTestButton returns 0
```

### Acceptance Criteria

- [ ] `hitTestButton(view:node:at:)` is a public free function in the GameUI module
- [ ] Returns the traversal-order index of the first `AnyButton` whose `LayoutNode.frame` contains `point`
- [ ] Returns `nil` when no `AnyButton` frame contains `point`
- [ ] Traversal is depth-first, matching view-tree construction order
- [ ] Works when buttons are nested inside containers (VStack, HStack, FrameModifier)
- [ ] Point on the boundary of a frame counts as contained (inclusive bounds)
- [ ] Does not invoke any button's action during traversal
- [ ] Does not require Foundation or any third-party import

### Outcome KPIs

- **Who**: Game screen developers using GameUI (Riku's role)
- **Does what**: Implement mouse hover highlighting without writing per-screen boilerplate
- **By how much**: Four boilerplate pieces (hoverConstraints, buttonRects, collectButtonFrames, applyHoverFocus) reduced to zero — 100% elimination per screen
- **Measured by**: Count of screens that call `hitTestButton` vs. screens that still carry the four-piece boilerplate in SpaceSim codebase
- **Baseline**: Every existing hover-capable screen carries all four pieces manually

### Technical Notes

- `Rect.contains(_ point: Point)` must handle inclusive boundary (point at exact edge = inside)
- Traversal must walk both `view` (for type identity via `AnyButton`) and `node` (for frame data) in lockstep — the two trees must be structurally isomorphic
- `@infrastructure` note: if `Rect` does not have a `contains` method, it must be added as a dependency of this story (tracked as dependency below)
- Strict concurrency: `hitTestButton` is a pure function; no `@Sendable` closure capture needed; function itself can be non-isolated
- No mutation — pure function, no side effects

### Dependencies

- `AnyButton` protocol with `isFocused: Bool` — COMPLETED (`button-focus-state` feature, merged)
- `Rect.contains(_ point: Point) -> Bool` — check if this already exists; add if missing (prerequisite, same story or pre-task)
- `LayoutEngine.layout(_:in:)` producing correct child origins for nested containers — EXISTING (verified in LayoutEngineTests)
