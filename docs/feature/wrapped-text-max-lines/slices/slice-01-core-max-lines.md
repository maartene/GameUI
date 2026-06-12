# Slice 01: Core maxLines — Floor + Ceiling Behaviour

## Feature
`wrapped-text-max-lines`

## Slice ID
01

## User Story
US-04: WrappedText maxLines Layout Reservation

## Outcome
Riku can declare `WrappedText(content: line.text, fontSize: 22, maxLines: 3)` and the layout engine always returns a root node with `frame.size.height == 3 * 22 == 66.0`, regardless of whether the content wraps to 1, 3, or 5 lines. Surrounding layout elements (portrait, hint prompt) never shift position.

## Scope

### In
- `maxLines: Int?` property on `WrappedText` (default `nil`)
- `layoutWrappedTextNode` clips `allLines.prefix(maxLines)` for child count
- Reserved height: `maxLines * lineHeight` when `maxLines` non-nil
- `maxLines == nil` path: existing behaviour unchanged
- UAT scenarios: floor (short content), exact match, ceiling (clipped), nil

### Out
- `maxLines: 0` — handled in Slice 02
- `maxLines: 1` edge case — handled in Slice 02
- `maxLines` + empty content — handled in Slice 02

## Acceptance Criteria (summary)
- `maxLines: 3`, 1 wrapped line → 1 child, `height == 3 * lineHeight`
- `maxLines: 3`, 3 wrapped lines → 3 children, `height == 3 * lineHeight`
- `maxLines: 3`, 5 wrapped lines → 3 children, `height == 3 * lineHeight`, lines 4–5 absent from children
- `maxLines: nil` → existing content-height behaviour (N children, height = N * lineHeight)

## Dependencies
- US-01 (WrappedText Core Word-Wrap Layout) — merged
- US-02 (Robustness and Fallback) — merged
- US-03 (Renderer Guidance) — merged

## Estimated Effort
1 day
