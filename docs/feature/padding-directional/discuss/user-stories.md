<!-- markdownlint-disable MD024 -->
# User Stories — padding-directional

## System Constraints

- Swift 6.2; no Foundation import
- All geometry uses project-internal `Float`-based `Size`, `Rect`, `Point` types
- All new types are `struct`s conforming to `View` and/or a new `AnyDirectionalPaddingModifier` protocol
- Return type of `.padding(x:y:)` is `DirectionalPaddingModifier<Self>` (generic, matching existing modifier pattern)
- Negative padding values are clamped to `0` via `max(0, ...)` — consistent with `layoutPaddingNode`
- No breaking changes to existing `.padding(_ amount:)` API

---

## US-PDR-01: Directional Padding Layout

### Problem

Alex Reyes is a game developer building HUD dialogue boxes in GameUI. They find it awkward to achieve wide left/right margins with tight top/bottom margins: the only option is to nest two `.padding()` calls (`.padding(20).padding(10)` achieves nothing — it adds 30 uniformly), or to write a custom `FrameModifier` workaround. Neither expresses intent.

### Who

- **User type**: Game developer writing Swift code with GameUI
- **Context**: Constructing a `VStack`- or `ZStack`-based HUD panel where horizontal and vertical insets need independent control
- **Motivation**: Express asymmetric padding in a single, readable API call without nesting modifiers

### Solution

A `.padding(x:y:)` modifier on `View` that produces a `DirectionalPaddingModifier<Self>` carrying `paddingX` and `paddingY`. The `LayoutEngine` detects the modifier via `AnyDirectionalPaddingModifier` and computes outer frame as `content.size + Size(width: 2*x, height: 2*y)`, clamped to constraints.

### Elevator Pitch

- **Before**: Alex calls `.padding(20)` on a dialogue box — all four sides get 20pt inset. To get 20 horizontal / 10 vertical, the only option is a workaround.
- **After**: Alex calls `.padding(x: 20, y: 10)` on any view; `LayoutEngine.layout(view, in: constraints)` returns a `LayoutTree` whose root `LayoutNode.frame.size` is `Size(width: content.width + 40, height: content.height + 20)`.
- **Decision enabled**: Alex independently controls horizontal vs vertical inset balance for each HUD element in the same layout pass.

### Domain Examples

#### 1: Dialogue Box — Happy Path
Alex builds a 300×80 dialogue background. Calling `.padding(x: 20, y: 10)` and laying out in 600×200 constraints produces an outer frame of 340×100. The child text view renders at origin (20, 10) within the outer frame.

#### 2: Letterbox Header — Zero Vertical Padding
Priya Sharma is building a letterbox-style header that must fill the full height of its container. She calls `.padding(x: 16, y: 0)`. The outer height equals the content height; left and right each gain 16pt of space.

#### 3: Tight Badge — Negative Value Guard
Tomás Dvořák accidentally passes `.padding(x: -5, y: 2)`. The negative x value is clamped to 0; the badge renders as if `.padding(x: 0, y: 2)` was called — no crash, no distorted frame.

### UAT Scenarios (BDD)

#### Scenario: Dialogue box gains correct horizontal and vertical insets
```gherkin
Given Alex has a Rectangle view with intrinsic size 100x50
And Alex wraps it with .padding(x: 20, y: 10)
And layout constraints are maxWidth 400 and maxHeight 300
When LayoutEngine.layout is called
Then the root LayoutNode frame width is 140
And the root LayoutNode frame height is 70
And the child LayoutNode frame origin x is 20
And the child LayoutNode frame origin y is 10
```

#### Scenario: Zero horizontal padding leaves width unchanged
```gherkin
Given Priya has a Rectangle view with intrinsic size 80x40
And Priya wraps it with .padding(x: 0, y: 10)
And layout constraints are maxWidth 400 and maxHeight 300
When LayoutEngine.layout is called
Then the root LayoutNode frame width is 80
And the root LayoutNode frame height is 60
```

#### Scenario: Zero vertical padding leaves height unchanged
```gherkin
Given Priya has a Rectangle view with intrinsic size 80x40
And Priya wraps it with .padding(x: 10, y: 0)
And layout constraints are maxWidth 400 and maxHeight 300
When LayoutEngine.layout is called
Then the root LayoutNode frame width is 100
And the root LayoutNode frame height is 40
```

#### Scenario: Outer size is clamped to available constraints
```gherkin
Given Alex has a Rectangle view with intrinsic size 90x90
And Alex wraps it with .padding(x: 20, y: 20)
And layout constraints are maxWidth 100 and maxHeight 100
When LayoutEngine.layout is called
Then the root LayoutNode frame width is at most 100
And the root LayoutNode frame height is at most 100
```

#### Scenario: Zero padding on both axes produces same frame as unwrapped content
```gherkin
Given Alex has a Rectangle view with intrinsic size 60x30
And Alex wraps it with .padding(x: 0, y: 0)
And layout constraints are maxWidth 400 and maxHeight 300
When LayoutEngine.layout is called
Then the root LayoutNode frame width is 60
And the root LayoutNode frame height is 30
```

#### Scenario: Negative padding values are silently clamped to zero
```gherkin
Given Tomás has a Rectangle view with intrinsic size 60x40
And Tomás wraps it with .padding(x: -5, y: -10)
And layout constraints are maxWidth 400 and maxHeight 300
When LayoutEngine.layout is called
Then the root LayoutNode frame width is 60
And the root LayoutNode frame height is 40
```

#### Scenario: Child origin is inset by (paddingX, paddingY) from outer origin
```gherkin
Given Alex has a Rectangle view with intrinsic size 100x50
And Alex wraps it with .padding(x: 20, y: 10)
And the outer frame origin is (5, 5)
When LayoutEngine.layout is called
Then the child LayoutNode frame origin x is 25
And the child LayoutNode frame origin y is 15
```

### Acceptance Criteria

- [ ] `.padding(x: 20, y: 10)` on a 100×50 view → outer frame 140×70; child origin at (20, 10) relative to outer origin
- [ ] `.padding(x: 0, y: 10)` on an 80×40 view → outer frame 80×60; child origin at (0, 10)
- [ ] `.padding(x: 10, y: 0)` on an 80×40 view → outer frame 100×40; child origin at (10, 0)
- [ ] Child origin = outer origin + (paddingX, paddingY) in all configurations
- [ ] Outer size clamped to `constraints.maxWidth` / `constraints.maxHeight`
- [ ] `.padding(x: 0, y: 0)` → outer frame equals unwrapped content frame
- [ ] Negative paddingX or paddingY values produce the same result as zero for that axis

### Outcome KPIs

- **Who**: Game developers using GameUI
- **Does what**: Express asymmetric horizontal/vertical padding in a single modifier call
- **By how much**: 7/7 layout acceptance criteria pass with no regressions in existing `.padding(_:)` tests
- **Measured by**: Swift Testing test suite (automated, run on every commit)
- **Baseline**: No `.padding(x:y:)` API exists; workaround requires nesting or custom modifier

### Technical Notes

- `AnyDirectionalPaddingModifier` must be checked before `AnyPaddingModifier` in `layoutNode` dispatch to prevent shadowing
- `outerSizeForPaddedContent` helper in `LayoutEngine` uses a single `amount` parameter — `layoutDirectionalPaddingNode` should implement its own size calculation directly rather than force-reusing that helper
- Swift 6.2 strict concurrency: all new functions are non-isolated and operate on value types
- No Foundation import; do not use `CGFloat`, `CGSize`, or `CGPoint`

---

## US-PDR-02: Hit-Test Traversal Through Directional Padding

### Problem

Alex Reyes wraps an action button in `.padding(x: 10, y: 5)` to give it a larger tap target. After implementing layout, Alex finds that `hitTestButton` returns `nil` for taps inside the padded button — the traversal function has no branch for `AnyDirectionalPaddingModifier` and skips the wrapper entirely.

### Who

- **User type**: Game developer wiring pointer/touch input to GameUI views
- **Context**: Interactive HUD with buttons wrapped in directional padding for precise tap-target sizing
- **Motivation**: Use `.padding(x:y:)` freely on interactive views without manually accounting for it in the input layer

### Solution

Add an `AnyDirectionalPaddingModifier` branch to `hitTestNode` in `HitTest.swift` that descends into `paddingContent`, matching the existing `AnyPaddingModifier` traversal pattern.

### Elevator Pitch

- **Before**: Alex wraps a "Attack" button in `.padding(x: 10, y: 5)`; calling `hitTestButton(view: root, node: tree.root, at: tapPoint)` returns `nil` even for taps squarely on the button, because `hitTestNode` has no `AnyDirectionalPaddingModifier` branch.
- **After**: `hitTestButton(view: root, node: tree.root, at: tapPoint)` returns `0` (the button index) for any point inside the padded button frame, regardless of which padding modifier was used.
- **Decision enabled**: Alex chooses between `.padding(_:)` and `.padding(x:y:)` based on layout needs alone, without worrying about which one breaks pointer hit testing.

### Domain Examples

#### 1: Single Padded Button — Happy Path
Alex places a "Confirm" button wrapped in `.padding(x: 10, y: 5)`. The layout produces an outer frame at (50, 100) with size 120×50. Tapping at (110, 125) — inside the outer frame — returns index `0`.

#### 2: Padded Button in VStack
Priya builds a VStack with "Move" (unwrapped) and "Attack" (wrapped in `.padding(x: 8, y: 4)`). `hitTestButton` called with a point inside the "Attack" padded frame returns index `1`.

#### 3: Tap Outside Padded Frame Returns Nil
Tomás taps at a point outside the outermost padded frame entirely. `hitTestButton` returns `nil`. The game input handler correctly ignores the tap.

### UAT Scenarios (BDD)

#### Scenario: Hit-test reaches button through directional padding
```gherkin
Given Alex has a Button "Confirm" wrapped with .padding(x: 10, y: 5)
And the layout tree is computed with constraints maxWidth 200 maxHeight 100
When hitTestButton is called with a point inside the padded button frame
Then hitTestButton returns 0
And the button action is not invoked during the traversal
```

#### Scenario: Tap outside padded frame returns nil
```gherkin
Given Alex has a Button "Confirm" wrapped with .padding(x: 10, y: 5)
And the layout tree is computed with constraints maxWidth 200 maxHeight 100
When hitTestButton is called with a point outside the outer padded frame entirely
Then hitTestButton returns nil
```

#### Scenario: Hit-test reaches directional-padded button inside VStack
```gherkin
Given Priya has a VStack containing Button "Move" and Button "Attack"
And "Attack" is wrapped with .padding(x: 8, y: 4)
And the layout tree is computed with constraints maxWidth 200 maxHeight 200
When hitTestButton is called with a point inside the padded "Attack" frame
Then hitTestButton returns the index corresponding to "Attack"
```

#### Scenario: Button action is not triggered during hit-test traversal
```gherkin
Given Alex has a Button "Confirm" with a recorded action counter wrapped with .padding(x: 10, y: 5)
And the layout tree is computed with constraints maxWidth 200 maxHeight 100
When hitTestButton is called with a point inside the padded button frame
Then the action counter remains 0
And hitTestButton returns 0
```

### Acceptance Criteria

- [ ] Button wrapped in `.padding(x: 10, y: 5)` → `hitTestButton` returns the button index for a point inside the padded frame
- [ ] Point inside padded button frame → index returned; point outside outer padded frame → nil returned
- [ ] Button wrapped in directional padding inside a VStack → `hitTestButton` returns the correct stack-position index
- [ ] `hitTestButton` does not invoke the button action during traversal

### Outcome KPIs

- **Who**: Game developers using interactive views wrapped in directional padding
- **Does what**: Receive correct button index from `hitTestButton` for any point inside a directional-padded button frame
- **By how much**: 4/4 hit-test acceptance criteria pass; 0 false negatives (nil returned for valid taps) in the test suite
- **Measured by**: Swift Testing test suite (automated)
- **Baseline**: `hitTestButton` currently returns nil for any button wrapped in a non-`AnyPaddingModifier` wrapper

### Technical Notes

- Pattern-match on `AnyDirectionalPaddingModifier` in `hitTestNode`, descend into `paddingContent` — mirrors the existing `AnyPaddingModifier` branch
- The hit-test traversal does not use padding amounts (x, y) — it relies on the `LayoutNode` frame already accounting for padding; only the descent into `paddingContent` is needed
- Dispatch order in `hitTestNode` must check `AnyDirectionalPaddingModifier` before any generic leaf checks
- No changes to the public `hitTestButton` signature
