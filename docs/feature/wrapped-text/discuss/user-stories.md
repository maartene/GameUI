<!-- markdownlint-disable MD024 -->

# User Stories: wrapped-text

## System Constraints

- No Foundation, no CGFloat, no platform-specific imports — pure Swift 6.2 with `Float` geometry.
- `WrappedText` is a leaf primitive: `body: Never`, handled by `LayoutEngine.layoutNode`.
- Word-wrap measurement uses the injected `textMeasurer` closure when present; falls back to `fontSize * charCount` estimation when nil (same rule as `Text`).
- Output layout: one child `LayoutNode` per wrapped line; renderer must walk `.children` for draw calls.
- Left-aligned text only in this first pass. Alignment parameter is not part of this feature; all lines are left-aligned (leading edge).
- `WrappedText.color` and `.fontSize` must be accessible to the renderer after pattern-matching.

---

## US-01: WrappedText Core Word-Wrap Layout

### Problem

Riku Nakamura is a game developer building HUD panels and dialogue boxes in Swift using GameUI and Raylib. He finds it painful to manually split long strings into fixed-length lines — the line lengths change whenever the font size or panel width changes, and he has to recompute them by hand every time. He currently uses multiple `Text` nodes inside a `VStack`, but this forces him to hard-code line breaks in game source code, coupling content to layout.

### Who

- Game developer using GameUI with a custom renderer
- Context: building HUD panels with dynamically-sized text areas (inventory descriptions, quest logs, dialogue)
- Motivation: wants text layout to be declarative and automatic, not manually computed

### Solution

A `WrappedText` view primitive that accepts a string, font size, and color, and produces one child `LayoutNode` per wrapped line during layout — using the injected `textMeasurer` for accurate line widths.

### Elevator Pitch

**Before**: Riku manually splits "The ancient relic pulses with an eerie blue glow, said to grant its bearer visions of the past." into fixed-length chunks hard-coded in Swift, re-coding every time panel width changes.

**After**: `WrappedText(content: "The ancient relic...", fontSize: 14, color: .white)` — layout engine produces 3 child nodes automatically at `maxWidth: 200`. Riku walks `node.children` in his renderer.

**Decision enabled**: Riku can now define HUD panel width in a single place (the `LayoutConstraints`) and all `WrappedText` components reflow automatically.

### Domain Examples

#### Example 1: Item Description in HUD Panel (Happy Path)
Riku is building an inventory panel 200px wide. He has the item description "The ancient relic pulses with an eerie blue glow, said to grant its bearer visions of the past." at `fontSize: 14` with Raylib font metrics (roughly 8px/char). `LayoutEngine` produces 3 child nodes, each with `origin.y` equal to `0`, `14`, and `28` respectively. No child frame width exceeds `200`.

#### Example 2: Quest Log Entry (Single Short Line)
Riku displays "Collect 10 herbs" at `fontSize: 16` in a 300px wide quest log panel. The string is only 90px wide. `LayoutEngine` produces exactly 1 child node with `frame.size.width ≤ 300`. The developer does not need to handle the multi-line case specially.

#### Example 3: Dialogue Line (Exactly Fills One Line)
Riku has "Go now." at `fontSize: 20` in a 200px panel where "Go now." measures exactly 99px. `LayoutEngine` produces 1 child node. The algorithm does not add a spurious second empty child.

### UAT Scenarios (BDD)

#### Scenario: Multi-line item description produces correct child nodes
Given Riku has a `LayoutEngine` with a stub `textMeasurer` returning `width = fontSize * charCount`, `height = fontSize`
And a `WrappedText` with content "The ancient relic pulses with an eerie blue glow said to grant its bearer visions of the past" `fontSize: 14` `color: .white`
When `layout` runs with `LayoutConstraints(maxWidth: 200, maxHeight: 600)`
Then the root `LayoutNode` has 2 or more children
And no child `LayoutNode.frame.size.width` exceeds `200`

#### Scenario: Child origins are stacked vertically by lineHeight
Given a `LayoutEngine` with a stub measurer returning `height = fontSize`
And a `WrappedText` that produces exactly 3 wrapped lines at `fontSize: 16`
When `layout` runs with `LayoutConstraints(maxWidth: 200, maxHeight: 600)`
Then `children[0].frame.origin.y == 0`
And `children[1].frame.origin.y == 16`
And `children[2].frame.origin.y == 32`

#### Scenario: Root node height equals total stacked line height
Given a `WrappedText` that produces 3 lines each of height `14`
When `layout` runs
Then `root.frame.size.height == 42`

#### Scenario: Single short line produces exactly one child
Given a `WrappedText` with content "HP" `fontSize: 14`
And `LayoutConstraints(maxWidth: 200)`
When `layout` runs
Then the root `LayoutNode` has exactly 1 child
And `children[0].frame.size.width <= 200`

#### Scenario: WrappedText is accepted by LayoutEngine as a View
Given a `WrappedText` value
When it is passed to `LayoutEngine.layout(_:in:)`
Then the call compiles and returns a non-nil `LayoutTree`

#### Scenario: Text that exactly fits one line produces exactly one child without overflow
Given a `LayoutEngine` with a stub measurer
And a `WrappedText` with content that measures exactly `constraints.maxWidth` wide
When layout runs
Then exactly 1 child `LayoutNode` is produced
And the child `frame.size.width` equals the content width (not exceeding `constraints.maxWidth`)

### Acceptance Criteria

- [ ] `WrappedText` struct exists with `content: String`, `fontSize: Float`, `color: Color` properties
- [ ] `WrappedText` conforms to `View` with `body: Never`
- [ ] `LayoutEngine.layoutNode` handles `WrappedText` in a dedicated branch
- [ ] Multi-line input (e.g., 47-word description) at `maxWidth: 200` with stub measurer produces 2 or more children
- [ ] No child `LayoutNode.frame.size.width` exceeds `constraints.maxWidth` when a measurer is injected
- [ ] Child nodes stacked vertically: `children[i].frame.origin.y == parentOrigin.y + i * fontSize`
- [ ] Root node `frame.size.height == lineCount * lineHeight`
- [ ] Root node `frame.size.width == constraints.maxWidth` (root always fills available width, consistent with container behaviour)
- [ ] Single-line input produces exactly 1 child node
- [ ] Given identical content, fontSize, color, and LayoutConstraints, `LayoutEngine.layout` returns identical `LayoutTree` across multiple calls (deterministic, side-effect-free)

### Outcome KPIs

- **Who**: Game developers using GameUI with a custom renderer
- **Does what**: Declare `WrappedText` and get correct per-line layout without manually splitting strings
- **By how much**: Developer completes a working multi-line HUD text panel in a single session (< 30 min from declaration to renderer output)
- **Measured by**: Internal developer usage in the reference Raylib integration; unit test pass rate
- **Baseline**: Currently requires manual `VStack` + multiple `Text` nodes with hard-coded line breaks

### Technical Notes

- `WrappedText` must not import Foundation; word splitting uses `String.components(separatedBy: " ")` or equivalent Swift stdlib method.
- `lineHeight` is derived from `textMeasurer(word, fontSize).height` or `fontSize` directly — consistent with `Text` fallback.
- `LayoutEngine` branch added before the catch-all `return LayoutNode(...)` at the bottom of `layoutNode`.
- Greedy algorithm: build `currentLine`, test candidate, break and start new line when candidate exceeds `maxWidth`.
- Root frame width = `constraints.maxWidth` (not the longest line width) — consistent with container behaviour.

---

## US-02: WrappedText Robustness and Fallback

### Problem

Riku is testing his HUD panel code before connecting his Raylib renderer. He has no font metrics available yet, so he creates `LayoutEngine()` without a `textMeasurer`. His `WrappedText` declarations should still produce a reasonable layout for prototyping. Additionally, his game data includes item names that are single CamelCase tokens (e.g., "AncientRelicOfThePast") that cannot be broken by spaces — these must not crash or loop.

### Who

- Game developer using GameUI during prototyping (no renderer injected) or with unexpected input data
- Context: prototyping without font metrics; production with unusual content (no spaces, empty strings)
- Motivation: wants `WrappedText` to be safe to call with any content without defensive wrapper code

### Solution

A char-count fallback (matching `Text` behaviour) when no measurer is injected, plus guard logic for unbreakable words, empty strings, and near-zero constraints.

### Elevator Pitch

**Before**: Riku calls `LayoutEngine().layout(wrappedText, in: constraints)` without a measurer and his game crashes with an infinite loop because one item name has no spaces.

**After**: `LayoutEngine()` without measurer activates char-count fallback transparently. `"AncientRelicOfThePast"` at `maxWidth: 50` produces exactly 1 child node and the engine completes cleanly.

**Decision enabled**: Riku can prototype layout without a renderer and trust that production content with unusual formatting will not crash his game.

### Domain Examples

#### Example 1: Prototyping Without Measurer (Char-Count Fallback)
Riku is iterating on panel layouts before integrating Raylib fonts. He creates `LayoutEngine()` with no arguments. `WrappedText(content: "Short text for testing fallback", fontSize: 10, color: .white)` with `maxWidth: 100` produces at least 1 child node using the `fontSize * charCount` estimation. No crash.

#### Example 2: Single Unbreakable Word (Game Item Name)
Riku's item database has `"AncientRelicOfThePast"` as a token. `WrappedText(content: "AncientRelicOfThePast", fontSize: 14, color: .white)` with `maxWidth: 50` and a stub measurer (8px/char → width 168px > 50) produces exactly 1 child node. The greedy loop does not enter an infinite cycle.

#### Example 3: Empty Quest Description
A quest is unlocked but has no description yet: `content: ""`. `WrappedText(content: "", fontSize: 14, color: .white)` produces a root node with 0 children and `frame.size.height == 0`. No crash. Renderer's `zip(lines, children)` produces 0 iterations.

### UAT Scenarios (BDD)

#### Scenario: Char-count fallback when no measurer is injected
Given a `LayoutEngine` with no `textMeasurer`
And a `WrappedText` with content "Short text for testing fallback" `fontSize: 10` `color: .white`
When `layout` runs with `LayoutConstraints(maxWidth: 100, maxHeight: 400)`
Then at least 1 child `LayoutNode` is produced
And no crash or test failure occurs

#### Scenario: Single unbreakable word wider than maxWidth placed on own line
Given a `LayoutEngine` with a stub measurer returning `width = fontSize * charCount`
And a `WrappedText` with content "AncientRelicOfThePast" `fontSize: 14` `color: .white`
And `LayoutConstraints(maxWidth: 50, maxHeight: 400)`
When `layout` runs
Then exactly 1 child `LayoutNode` is produced
And the layout engine completes without looping

#### Scenario: Empty content produces zero children
Given a `WrappedText` with content "" `fontSize: 14` `color: .white`
When `layout` runs with any `LayoutConstraints`
Then the root `LayoutNode` has 0 children
And `root.frame.size.height == 0`
And no crash or test failure occurs

#### Scenario: Near-zero maxWidth places each word on its own line
Given a `LayoutEngine` with a stub measurer
And a `WrappedText` with content "Hello world" `fontSize: 14` `color: .white`
And `LayoutConstraints(maxWidth: 1.0, maxHeight: 400)`
When `layout` runs
Then the root `LayoutNode` has exactly 2 children
And the layout engine completes without looping

### Acceptance Criteria

- [ ] `LayoutEngine` without `textMeasurer` + `WrappedText` → at least 1 child node, no crash (char-count fallback)
- [ ] Content `"AncientRelicOfThePast"` at `maxWidth: 50` with measurer → exactly 1 child node, no infinite loop
- [ ] Content `""` → root has 0 children, `root.frame.size.height == 0`, no crash
- [ ] Content `"Hello world"` at `maxWidth: 1.0` → exactly 2 children, engine completes
- [ ] No input combination produces an infinite loop or unhandled exception

### Outcome KPIs

- **Who**: Game developers using `WrappedText` in production or prototyping
- **Does what**: Use `WrappedText` with any content without defensive guard code
- **By how much**: 0 crash reports from boundary inputs (all 4 error-path scenarios pass green)
- **Measured by**: Unit test suite — all Slice 2 scenarios pass
- **Baseline**: Without this story, any single-word content wider than maxWidth causes an infinite loop

### Technical Notes

- Char-count fallback: `width = fontSize * Float(word.count)` — matches `layoutTextNode` fallback in `LayoutEngine`.
- Unbreakable word guard: if `currentLine.isEmpty && measureWord > maxWidth`, append word as-is and continue (do not retry).
- Empty string: `content.isEmpty` check at entry returns `LayoutNode(frame: Rect(origin, Size(width: 0, height: 0)), children: [])`.
- Near-zero maxWidth: the unbreakable word guard handles this — every word exceeds `1.0` and is placed individually.
- Depends on US-01 being merged.

---

## US-03: WrappedText Renderer Guidance

### Problem

Riku has implemented `WrappedText` layout (Slices 1–2) and wants to add it to his Raylib renderer. He opens the README Raylib integration example and finds no `WrappedText` branch — he has to guess how to recover line strings from the `LayoutTree`. The `LayoutNode` has no string payload, so without a pattern or convention, he does not know whether to re-split the content string himself or look for a `lines` property on `WrappedText`.

### Who

- Game developer extending an existing GameUI renderer integration
- Context: adding `WrappedText` support to a working Raylib (or other renderer) integration
- Motivation: wants to follow the established pattern (like `Text`, `Rectangle`) without reading engine source

### Solution

Resolve the line-string access design question (Option A or C from shared-artifacts-registry.md), implement it in `WrappedText`, and update the README Raylib integration example with a `WrappedText` branch.

### Elevator Pitch

**Before**: Riku reads `LayoutEngine.swift` internals to understand how to recover line strings from a `WrappedText` layout tree. He makes a mistake (re-splitting differently) and some lines are drawn with wrong content.

**After**: README shows `if let wt = view as? GameUI.WrappedText { for (line, child) in zip(wt.lines, node.children) { ... } }`. Riku copies the pattern and it works first time.

**Decision enabled**: Riku can add `WrappedText` renderer support in under 15 minutes by following the documented pattern.

### Domain Examples

#### Example 1: Raylib Renderer Adds WrappedText Branch
Riku adds to `GameUIRaylibRenderer.renderNode`: `if let wt = view as? GameUI.WrappedText { return zip(wt.lines, node.children).map { (line, child) in .text(position: child.frame.origin, text: line, fontSize: wt.fontSize, color: toRaylibColor(wt.color)) } }`. This emits one `.text` draw command per line.

#### Example 2: Custom SDL2 Renderer Follows Same Pattern
Another developer using SDL2 follows the same `wt.lines` + `node.children` zip pattern. The convention is the same regardless of renderer.

#### Example 3: Empty WrappedText in Renderer
`wt.lines` is `[]` and `node.children` is `[]`. `zip` produces 0 iterations. No draw commands emitted. No crash.

### UAT Scenarios (BDD)

#### Scenario: README example covers WrappedText renderer integration
Given the README Raylib integration section
When Riku reads the "recursive renderer" code sample
Then a `WrappedText` branch is present in the pattern-match
And the branch shows how to access per-line strings and child node origins

#### Scenario: WrappedText.lines accessible after layout
Given a `WrappedText` that produced 3 child nodes during layout
When the renderer pattern-matches the view as `WrappedText`
Then `wt.lines.count == 3`
And `wt.lines[0]` is the first wrapped line string
And `wt.lines[2]` is the third wrapped line string

#### Scenario: zip(lines, children) produces correct draw call count
Given a renderer walking a `WrappedText` root node with 3 children
When the renderer iterates `zip(wt.lines, node.children)`
Then exactly 3 draw calls are emitted
And each draw call position equals the corresponding child `frame.origin`

### Acceptance Criteria

- [ ] `WrappedText` exposes a `lines: [String]` property populated during `LayoutEngine` layout (Note: if DESIGN wave chooses Option C — child view nodes — this AC is replaced by: "Each `WrappedText` child is a `Text` view node accessible via `containerChildren`". AC is finalised after DESIGN wave resolves the line-string access question.)
- [ ] `zip(wt.lines, node.children)` produces one pair per wrapped line
- [ ] README Raylib integration example includes a `WrappedText` pattern-match branch
- [ ] Empty `content` → `wt.lines == []`, `node.children == []`, renderer emits 0 draw calls, no crash

### Outcome KPIs

- **Who**: Game developers integrating custom renderers with `WrappedText`
- **Does what**: Add `WrappedText` renderer support by following the README example
- **By how much**: Developer completes renderer integration in under 15 minutes without reading engine source
- **Measured by**: Self-report from integration test; README example verified against test suite
- **Baseline**: Currently no pattern exists — developer must infer from internals

### Technical Notes

- Depends on US-01 (Slice 1) merged and DESIGN wave decision on line-string access approach.
- If Option A (store lines on `WrappedText`): `WrappedText` gains a `var lines: [String]` property populated in `layoutWrappedTextNode`. This requires `WrappedText` to be a class (reference type) or the algorithm to return a mutated copy. Design implication: `WrappedText` may need to become a reference type or the engine returns a new annotated type. Flagged for DESIGN wave.
- If Option C (child view nodes): each child is a `Text` view node. Renderer recurses naturally. `lines` property not needed. Increases tree complexity but follows existing renderer pattern without new convention.
- README change is a documentation-only change (no new API beyond the design decision).
- Depends on US-01 and US-02.
