# Story Map: wrapped-text-max-lines

## User
Riku Nakamura — game developer building SpaceSim narrative screens with fixed-area body text regions.

## Goal
Declare `WrappedText` with `maxLines` and receive a layout tree whose height is always `maxLines × lineHeight`, regardless of whether the text is shorter or longer than the reservation.

---

## Backbone

| Declare WrappedText | Compute Layout | Render |
|---------------------|----------------|--------|
| Pass `maxLines: Int?` at call site | Clip lines to `maxLines`; reserve height as `maxLines × lineHeight` | `zip(wt.lines, node.children)` — unchanged pattern |
| Pass `maxLines: nil` (unchanged) | Preserve existing content-height path | Existing render path unchanged |
| Pass `maxLines: 0` (edge) | Zero-height reservation | 0 children, no draw calls |
| Pass `maxLines: 1` (tight) | 1-line reservation with ceiling clip | At most 1 child |

---

## Walking Skeleton

> Skipped per pre-answered wave decisions. Pattern is established (brownfield leaf-view).

---

## Release 1: Core maxLines — Floor + Ceiling Behaviour

**Outcome target**: Riku can declare `maxLines: N` and the layout height is always `N × lineHeight`, whether content is short (floor), exact, or long (ceiling/clip).

**Stories**: US-04

**KPI targeted**: Game developer declares `WrappedText(maxLines: 3)` and surrounding layout elements (portrait, hint prompt) never shift — verified by deterministic height in layout tests.

**Tasks**:
- Add `maxLines: Int?` property to `WrappedText` struct
- Modify `layoutWrappedTextNode` to clip `allLines.prefix(maxLines)` and set `height = maxLines * lineHeight`
- `maxLines == nil` path unchanged
- UAT scenarios: short content (floor), exact content, long content (ceiling), nil (no change)

---

## Release 2: Edge Cases — maxLines: 0 and maxLines: 1

**Outcome target**: Riku can use `maxLines: 0` or `maxLines: 1` without defensive guard code and receive safe, predictable output.

**Stories**: US-05

**KPI targeted**: 0 crashes or unexpected layout from boundary `maxLines` values — verified by edge-case test suite.

**Tasks**:
- `maxLines: 0` → 0 children, `height = 0`
- `maxLines: 1` → at most 1 child, `height = lineHeight`
- `maxLines: N` + empty content → 0 children, `height = N * lineHeight` (floor applies to empty string)
- Combination: `maxLines: 1` + unbreakable word wider than `maxWidth` → 1 child, height = lineHeight

---

## Scope Assessment

PASS — 2 user stories, 1 bounded context (`GameUI` WrappedText + LayoutEngine), estimated 1–2 days total.

## Priority Rationale

Release 1 ships first because it delivers the primary stated outcome (fixed height reservation) and unblocks the SpaceSim narrative screen use case. Release 2 follows immediately as the robustness layer — edge-case behaviour must be defined before DELIVER to avoid ambiguity in the implementation. Both releases are tightly coupled (same property, same function) and are expected to ship together in a single sprint.
