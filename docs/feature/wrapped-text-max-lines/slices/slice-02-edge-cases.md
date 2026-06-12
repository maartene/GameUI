# Slice 02: Edge Cases — maxLines: 0, maxLines: 1, Empty Content

## Feature
`wrapped-text-max-lines`

## Slice ID
02

## User Story
US-05: WrappedText maxLines Edge Cases

## Outcome
Riku can pass any non-negative integer for `maxLines` (including 0 and 1) and receive safe, predictable layout output. `maxLines: 0` produces a zero-height area. `maxLines: 1` produces a single-line area with clipping. Empty content with a non-nil `maxLines` still reserves the declared height (floor applies).

## Scope

### In
- `maxLines: 0` → 0 children, `frame.size.height == 0`
- `maxLines: 1` → at most 1 child, `frame.size.height == lineHeight`
- `maxLines: 1` + content that wraps to multiple lines → 1 child (ceiling clip), `height == lineHeight`
- `maxLines: N` + empty content (`content == ""`) → 0 children, `height == N * lineHeight` (floor applies; empty string produces no lines but height is reserved)
- `maxLines: 1` + unbreakable word wider than `maxWidth` → 1 child (from US-02 guard), `height == lineHeight`

### Out
- Happy-path floor + ceiling scenarios — covered in Slice 01

## Acceptance Criteria (summary)
- `maxLines: 0` → 0 children, `height == 0.0`
- `maxLines: 1`, 1 wrapped line → 1 child, `height == lineHeight`
- `maxLines: 1`, 3 wrapped lines → 1 child, `height == lineHeight`
- `maxLines: 3`, empty content → 0 children, `height == 3 * lineHeight`
- `maxLines: 1`, unbreakable word → 1 child, `height == lineHeight`, no crash

## Dependencies
- Slice 01 (US-04) — must be complete before implementation of this slice begins

## Estimated Effort
0.5 days
