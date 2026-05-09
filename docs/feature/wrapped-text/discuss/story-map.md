# Story Map: wrapped-text

## User
**Riku Nakamura** — game developer building HUD panels and dialogue boxes in Swift using GameUI + Raylib.

## Goal
Render arbitrary-length text in a constrained area (HUD panel, dialogue box, quest log) where lines wrap automatically and never overflow the panel boundary.

---

## Backbone

| Declare View | Compute Layout | Consume Layout |
|---|---|---|
| `WrappedText(content:fontSize:color:)` | `LayoutEngine.layout(wrappedText, in:)` | Renderer walks child nodes |

---

## Full Task Grid

### Activity 1: Declare View

| Priority | Task |
|---|---|
| P1 | `WrappedText` struct with `content`, `fontSize`, `color` properties |
| P1 | `View` conformance (`body: Never`) |
| P2 | `color` property accessible post-pattern-match |

### Activity 2: Compute Layout

| Priority | Task |
|---|---|
| P1 | `LayoutEngine.layoutNode` branch for `WrappedText` |
| P1 | Greedy word-wrap algorithm (measure candidate → break when > maxWidth) |
| P1 | One child `LayoutNode` per wrapped line, y-origins stacked by lineHeight |
| P1 | Root frame: width = `maxWidth`, height = sum of line heights |
| P2 | Char-count fallback (no measurer) |
| P2 | Unbreakable word handling (single word > maxWidth placed as-is) |
| P3 | Empty string → zero children, height 0 |
| P3 | Near-zero maxWidth → each word on own line, no infinite loop |

### Activity 3: Consume Layout

| Priority | Task |
|---|---|
| P1 | Layout stores computed line strings accessible to renderer (design question from shared-artifacts-registry) |
| P2 | Renderer pattern-match documentation / example updated in README |

---

## Walking Skeleton

Decision 2 (pre-answered): walking skeleton is skipped. The pattern for leaf views is established. The minimum demonstrable slice is:

**Slice 1 (Core)** — `WrappedText` struct + `layoutNode` branch + greedy wrap with injected measurer → correct child nodes.

This is the thinnest end-to-end slice a developer can verify: declare, layout, inspect child count and frames in a unit test.

---

## Release Slices

### Slice 1: Core Word-Wrap (Day 1)
**Outcome target**: Developer can declare `WrappedText`, run layout with an injected measurer, and get correct child nodes for each line — verified in unit tests.

Tasks included:
- `WrappedText` struct + `View` conformance
- `LayoutEngine` branch for `WrappedText`
- Greedy wrap algorithm with `textMeasurer`
- Child y-origins stacked by `fontSize`
- Root frame width = `maxWidth`, height = line count × lineHeight

**Outcome KPI**: Developer completes a working multi-line HUD text panel in a single session (no layout bug or crash).

---

### Slice 2: Robustness & Fallback (Day 2)
**Outcome target**: Developer can use `WrappedText` without a measurer (prototyping) and edge-case inputs do not crash or loop.

Tasks included:
- Char-count fallback (no measurer injected)
- Unbreakable word placed on its own line without crash
- Empty string → zero children, height 0
- Near-zero maxWidth → per-word lines, no infinite loop

**Outcome KPI**: Zero crash reports from edge inputs in test suite (100% of error-path scenarios pass).

---

### Slice 3: Renderer Guidance (Day 3, partial — documentation + example)
**Outcome target**: Developer integrating a custom renderer (e.g., Raylib) knows exactly how to walk `WrappedText` children and draw each line string.

Tasks included:
- Design decision on line-string access (Option A: `WrappedText.lines` or Option C: child view nodes) — resolved in DESIGN wave
- README Raylib integration example updated for `WrappedText`

**Outcome KPI**: Developer can add `WrappedText` to an existing Raylib integration without reading the layout engine source.

---

## Priority Rationale

1. **Slice 1 first** — Core functionality; nothing else works without it. Validates the riskiest assumption: does the greedy algorithm produce correct child nodes using the injected measurer?
2. **Slice 2 second** — Robustness prevents production crashes. Char-count fallback enables prototyping without renderer. Edge cases are low-effort, high-reliability-value.
3. **Slice 3 last** — Documentation improves developer experience but does not gate any functionality. Deferred until the design question (line-string access) is resolved in DESIGN wave.

## Scope Assessment

PASS — 3 slices, 1 bounded context (GameUI layout engine), estimated 2–3 days. No story exceeds 1 day of effort. Each slice is independently demonstrable.
