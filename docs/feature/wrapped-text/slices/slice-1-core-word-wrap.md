# Slice 1: Core Word-Wrap

## Slice ID
`wrapped-text/slice-1`

## Outcome Target
Developer can declare `WrappedText(content:fontSize:color:)`, pass it to `LayoutEngine.layout(_:in:)` with an injected `textMeasurer`, and receive a `LayoutTree` where each line of wrapped text is a child `LayoutNode` with a correct frame — verified in unit tests.

## Learning Hypothesis
We believe that implementing a greedy word-wrap layout branch in `LayoutEngine` with the injected `textMeasurer` as the measurement source will produce correct per-line child nodes that enable developers to render multi-line text in HUD panels without overflow.

We will know this is true when:
- A unit test with a stub measurer produces the expected number of children
- No child frame width exceeds `constraints.maxWidth`
- Child y-origins are stacked correctly at `i * fontSize`

## User Story
US-01 — WrappedText Core Word-Wrap Layout

## Effort Estimate
1 day

## Acceptance Tests (thin vertical slice)
1. `WrappedText` struct compiles with `content`, `fontSize`, `color` properties and `View` conformance (`body: Never`)
2. `LayoutEngine.layout(wrappedText, in: constraints)` with injected measurer produces `LayoutTree` with 2+ children for a 47-word input at `maxWidth: 200`
3. No child `LayoutNode.frame.size.width` exceeds `200`
4. Child `LayoutNode` y-origins are stacked: `children[i].frame.origin.y == i * fontSize`
5. Root `LayoutNode.frame.size.height == childCount * lineHeight`

## Out of Scope for This Slice
- Char-count fallback (no measurer) — Slice 2
- Edge cases: empty string, unbreakable word, near-zero maxWidth — Slice 2
- Renderer guidance / README update — Slice 3

## Dependencies
None — greenfield addition to GameUI.
