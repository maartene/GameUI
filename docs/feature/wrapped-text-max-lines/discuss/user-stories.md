<!-- markdownlint-disable MD024 -->

# User Stories: wrapped-text-max-lines

## System Constraints

- No Foundation, no CGFloat, no platform-specific imports — pure Swift 6.2 with `Float` geometry.
- `WrappedText` is a leaf primitive: `body: Never`, handled by `LayoutEngine.layoutWrappedTextNode`.
- `maxLines` MUST be an intrinsic property of `WrappedText`, NOT a wrapper modifier. Reason: `RecordingGameUIAdapter` requires a `HasFrameSize` traversal fix to see content behind a `FrameModifier`. An intrinsic property keeps the `WrappedText` node directly visible in the view tree.
- `maxLines: nil` (default) preserves all existing behaviour from US-01 through US-03 with zero regression.
- Reserved height = `maxLines × lineHeight` (both floor and ceiling); this is not a `minHeight` — the container must not grow beyond the reservation.
- `lineHeight` is determined the same way as in the existing implementation: `textMeasurer(word, fontSize).height` or `fontSize` fallback.
- Swift Testing framework (not XCTest). Test names use backtick-quoted func names.

---

## US-04: WrappedText maxLines Layout Reservation

### Problem

Riku Nakamura is a game developer building SpaceSim narrative screens with HUD panels. He finds it painful to express "reserve space for 3 lines of body text" because the current workaround — `VStack(WrappedText, Spacer).frame(width: w, height: 3 * lineHeight)` — buries the intent in pixel math and couples it to a wrapper structure. When font size or DPI changes, he must update the pixel value manually. The surrounding layout elements (portrait, hint prompt) jump when narration is shorter than the reservation, because the intent is invisible to the layout engine.

### Who

- Game developer building narrative HUD screens in SpaceSim using GameUI
- Context: fixed-area body text regions where content length varies (1-line narration vs 3-line narration)
- Motivation: express "this area is always 3 lines tall" at the `WrappedText` call site, not through external wrapper arithmetic

### Solution

Add `maxLines: Int?` (default `nil`) to `WrappedText`. When non-nil, `layoutWrappedTextNode` uses `maxLines * lineHeight` as the root frame height (floor + ceiling), clips the visible lines to `maxLines`, and produces at most `maxLines` child nodes. When `nil`, existing content-height behaviour is unchanged.

### Elevator Pitch

**Before**: Riku writes `VStack { WrappedText(content: line.text, fontSize: 22, color: .white); Spacer() }.frame(width: w, height: 3 * 22)` on every narrative screen. The `3 * 22` is invisible to the layout engine and breaks whenever font size changes.

**After**: `WrappedText(content: line.text, fontSize: 22, maxLines: 3)` — the intent is declared once at the call site. The layout engine reserves exactly `3 * 22 = 66.0` units of height regardless of actual line count.

**Decision enabled**: Riku can change `fontSize` in one place and the reserved area adapts automatically, with no pixel math to maintain.

### Domain Examples

#### Example 1: Short Narration — Floor Behaviour
Riku's scene `"Battle stations!"` wraps to 1 line at `fontSize: 22`, `maxWidth: 400`. With `maxLines: 3`, the layout engine produces 1 child node and a root height of `66.0` (3 × 22). The portrait and hint prompt below do not move relative to the narration area, even though only 1 line is used.

#### Example 2: Long Narration — Ceiling / Clip Behaviour
Riku's scene `"The station's emergency klaxon echoed through every corridor as red alert panels lit in sequence from deck one to deck twelve."` wraps to 5 lines at `fontSize: 22`, `maxWidth: 400`. With `maxLines: 3`, the layout engine produces exactly 3 child nodes and a root height of `66.0`. Lines 4 and 5 are not rendered — they are clipped at the ceiling. The height of the narration area is still `66.0`.

#### Example 3: maxLines Omitted — Existing Behaviour Unchanged
Riku uses `WrappedText(content: description, fontSize: 14, color: .white)` in an item description panel without `maxLines`. The layout engine produces N child nodes and height `N * 14`, exactly as before US-04. No regression.

### UAT Scenarios (BDD)

#### Scenario: Short narration reserves full declared height (floor)
Given Riku has a `LayoutEngine` with a stub `textMeasurer` returning `width = fontSize * charCount`, `height = fontSize`
And a `WrappedText` with content "Battle stations!" `fontSize: 22` `maxLines: 3`
When `layout` runs with `LayoutConstraints(maxWidth: 400, maxHeight: 600)`
Then the root `LayoutNode` has exactly 1 child
And `root.frame.size.height == 66.0`

#### Scenario: Long narration is clipped at maxLines boundary (ceiling)
Given a `LayoutEngine` with a stub measurer returning `width = fontSize * charCount`, `height = fontSize`
And a `WrappedText` with content that wraps to 5 lines at `fontSize: 22` `maxWidth: 400` `maxLines: 3`
When `layout` runs with `LayoutConstraints(maxWidth: 400, maxHeight: 600)`
Then the root `LayoutNode` has exactly 3 children
And `root.frame.size.height == 66.0`
And no child exists for lines 4 or 5

#### Scenario: Narration that exactly fills maxLines produces no clipping
Given a `LayoutEngine` with a stub measurer
And a `WrappedText` with content that wraps to exactly 3 lines at `fontSize: 22` `maxWidth: 400` `maxLines: 3`
When `layout` runs with `LayoutConstraints(maxWidth: 400, maxHeight: 600)`
Then the root `LayoutNode` has exactly 3 children
And `root.frame.size.height == 66.0`

#### Scenario: maxLines nil preserves existing content-height behaviour
Given a `LayoutEngine` with a stub measurer
And a `WrappedText` with content that wraps to 3 lines at `fontSize: 14` with no `maxLines` argument
When `layout` runs
Then `root.frame.size.height == 42.0`
And the root has exactly 3 children

#### Scenario: Layout height is stable across varying content lengths when maxLines is set
Given a `LayoutEngine` with a stub measurer
And `maxLines: 3` `fontSize: 22`
When `layout` runs once with 1-line content and once with 5-line content
Then `root.frame.size.height == 66.0` in both cases

### Acceptance Criteria

- [ ] `WrappedText` has a `maxLines: Int?` property with default value `nil`
- [ ] `maxLines: 3`, 1 wrapped line → 1 child node, `root.frame.size.height == 3 * fontSize`
- [ ] `maxLines: 3`, 5 wrapped lines → 3 child nodes, `root.frame.size.height == 3 * fontSize`, lines 4–5 absent
- [ ] `maxLines: 3`, 3 wrapped lines → 3 child nodes, `root.frame.size.height == 3 * fontSize`
- [ ] `maxLines: nil` → N children, `root.frame.size.height == N * lineHeight` (existing behaviour, no regression)
- [ ] `maxLines` is intrinsic to `WrappedText`, not implemented as a `.frame()` wrapper modifier
- [ ] Child node vertical origins are unchanged: `children[i].frame.origin.y == parentOrigin.y + i * lineHeight`
- [ ] `root.frame.size.width == constraints.maxWidth` (unchanged from existing behaviour)

### Outcome KPIs

- **Who**: Game developers building narrative screens in SpaceSim with fixed-area body text
- **Does what**: Declare `maxLines` at the `WrappedText` call site and get stable layout height without wrapper arithmetic
- **By how much**: Layout height of narration area is constant regardless of content length — verified by deterministic height in all Slice 01 tests
- **Measured by**: Unit test suite — all Slice 01 UAT scenarios green
- **Baseline**: Currently requires `VStack + Spacer + .frame(height:)` workaround with manual pixel math

### Technical Notes

- `layoutWrappedTextNode` change: after computing `allLines`, apply `let visibleLines = maxLines.map { Array(allLines.prefix($0)) } ?? allLines`; use `visibleLines` for child node generation; use `(maxLines.map { Float($0) } ?? Float(allLines.count)) * lineHeight` for height.
- `lineHeight` source: `textMeasurer?(anyWord, fontSize).height ?? fontSize` — unchanged from existing implementation.
- `maxLines` is a stored property on `WrappedText` struct. Default value `nil` ensures backward compatibility.
- The char-count fallback (no measurer injected) is orthogonal to `maxLines`. Line clipping and height reservation run after `wrappedLines()` regardless of whether a measurer is present. No special handling needed for the no-measurer + maxLines combination.
- Depends on US-01 (Core Word-Wrap Layout), US-02 (Robustness), US-03 (Renderer Guidance) — all merged.

---

## US-05: WrappedText maxLines Edge Cases

### Problem

Riku Nakamura is writing GameUI layout code for edge cases in SpaceSim: some screens have a zero-height "hidden" narration area (fade-in not yet triggered), and some screens use a single-line "status line" with tight clipping. He needs `maxLines: 0` and `maxLines: 1` to behave safely and predictably, and needs `maxLines` combined with empty content to still honour the height reservation (the empty area must still take up space so surrounding elements do not collapse).

### Who

- Game developer using `WrappedText` with boundary `maxLines` values (0 and 1)
- Context: zero-height hidden areas, single-line status displays, empty content with reserved space
- Motivation: no defensive guard code needed around `maxLines` — any non-negative integer is safe

### Solution

Define explicit semantics for `maxLines: 0` (zero height, zero children) and `maxLines: 1` (single-line area, hard ceiling at 1), and ensure that the floor behaviour (height = `maxLines * lineHeight`) applies even when content is empty.

### Elevator Pitch

**Before**: Riku passes `maxLines: 0` for a hidden panel area and is unsure whether the layout engine will produce an unexpected height or crash. He adds a conditional to avoid calling `WrappedText` at all when the area should be zero-height.

**After**: `WrappedText(content: "", fontSize: 22, maxLines: 0)` produces a root node with `frame.size.height == 0` and 0 children — deterministic, safe, no special-casing needed in game code.

**Decision enabled**: Riku can drive the visibility/height of a narration area purely from `maxLines` (including 0 for "collapsed"), without separate conditional logic in game code.

### Domain Examples

#### Example 1: Hidden Narration Area (maxLines: 0)
Riku's fade-in system starts with `maxLines: 0` for a narration area that has not yet appeared. `WrappedText(content: openingLine, fontSize: 22, maxLines: 0)` produces 0 children and `frame.size.height == 0`. No content is visible. No crash.

#### Example 2: Single-Line Status Display (maxLines: 1)
The SpaceSim HUD shows a one-line "combat status" string. `WrappedText(content: "Shields at 42% — hull integrity nominal.", fontSize: 16, maxLines: 1)` wraps the long string to 3 lines internally but clips to 1 child. `frame.size.height == 16.0`.

#### Example 3: Reserved Empty Area (maxLines: 3, content: "")
Before a narration line has been set, Riku passes an empty string. `WrappedText(content: "", fontSize: 22, maxLines: 3)` produces 0 children and `frame.size.height == 66.0`. The three-line area is reserved even though nothing is drawn. Portrait and hint prompt stay in place.

### UAT Scenarios (BDD)

#### Scenario: maxLines zero produces zero height
Given a `LayoutEngine` with a stub measurer
And a `WrappedText` with content "Opening narration line" `fontSize: 22` `maxLines: 0`
When `layout` runs with `LayoutConstraints(maxWidth: 400, maxHeight: 600)`
Then the root `LayoutNode` has 0 children
And `root.frame.size.height == 0.0`

#### Scenario: maxLines one clips multi-line content to a single line
Given a `LayoutEngine` with a stub measurer returning `width = fontSize * charCount`, `height = fontSize`
And a `WrappedText` with content that wraps to 3 lines at `fontSize: 16` `maxWidth: 200` `maxLines: 1`
When `layout` runs with `LayoutConstraints(maxWidth: 200, maxHeight: 600)`
Then the root `LayoutNode` has exactly 1 child
And `root.frame.size.height == 16.0`

#### Scenario: Empty content with maxLines reserves the declared height
Given a `LayoutEngine` with a stub measurer
And a `WrappedText` with content "" `fontSize: 22` `maxLines: 3`
When `layout` runs with `LayoutConstraints(maxWidth: 400, maxHeight: 600)`
Then the root `LayoutNode` has 0 children
And `root.frame.size.height == 66.0`

#### Scenario: maxLines one with unbreakable word wider than maxWidth produces one child safely
Given a `LayoutEngine` with a stub measurer returning `width = fontSize * charCount`, `height = fontSize`
And a `WrappedText` with content "AncientRelicOfThePast" `fontSize: 14` `maxLines: 1`
And `LayoutConstraints(maxWidth: 50, maxHeight: 400)`
When `layout` runs
Then the root `LayoutNode` has exactly 1 child
And `root.frame.size.height == 14.0`
And no crash or infinite loop occurs

### Acceptance Criteria

- [ ] `maxLines: 0` → 0 children, `root.frame.size.height == 0.0`, no crash
- [ ] `maxLines: 1`, content wraps to 3 lines → 1 child, `root.frame.size.height == lineHeight`
- [ ] `maxLines: 1`, content wraps to 1 line → 1 child, `root.frame.size.height == lineHeight`
- [ ] `maxLines: 3`, content `""` → 0 children, `root.frame.size.height == 3 * fontSize` (floor applies to empty content)
- [ ] `maxLines: 1`, unbreakable word wider than `maxWidth` → 1 child, `root.frame.size.height == lineHeight`, no crash
- [ ] All existing Slice 01 tests continue to pass (no regression from edge-case handling)

### Outcome KPIs

- **Who**: Game developers using `WrappedText` with boundary `maxLines` values
- **Does what**: Use any non-negative `maxLines` value without defensive guard code
- **By how much**: 0 crashes or unexpected layout from any boundary `maxLines` input — all Slice 02 edge-case tests pass green
- **Measured by**: Unit test suite — all Slice 02 UAT scenarios green
- **Baseline**: Without explicit edge-case semantics, `maxLines: 0` and empty-content combinations have undefined behaviour

### Technical Notes

- `maxLines: 0` guard: when `maxLines == 0`, skip child node generation; set `height = 0.0`. This is a natural outcome of `allLines.prefix(0)` returning an empty collection.
- `maxLines: 1` + unbreakable word: the US-02 unbreakable word guard (place word as-is on its own line) runs first; `prefix(1)` then keeps that single child. No new guard needed.
- Empty content + non-nil `maxLines`: when `content.isEmpty`, `allLines` is `[]`; `prefix(maxLines)` is also `[]`; but height = `maxLines * lineHeight` (not 0). Requires explicit handling: `let height = maxLines.map { Float($0) * lineHeight } ?? Float(allLines.count) * lineHeight`.
- The `maxLines: 0` empty-content combination collapses to `height = 0` naturally (0 * lineHeight = 0).
- Depends on US-04 (Slice 01) complete.
