# Slice 2: Robustness and Fallback

## Slice ID
`wrapped-text/slice-2`

## Outcome Target
`WrappedText` handles all boundary inputs without crash, infinite loop, or silent incorrect output — enabling developers to use it safely in production and during prototyping (without injected measurer).

## Learning Hypothesis
We believe that handling four boundary conditions (no measurer → char-count fallback, unbreakable word, empty string, near-zero maxWidth) will eliminate all crash and infinite-loop risk from the word-wrap feature, making it safe to ship.

We will know this is true when:
- All four error-path test scenarios pass (green)
- No input combination produces a crash or infinite loop in the test suite

## User Story
US-02 — WrappedText Robustness and Fallback

## Effort Estimate
1 day

## Acceptance Tests

### Char-count fallback
- `LayoutEngine` with no `textMeasurer` + `WrappedText` → at least 1 child node, no crash

### Unbreakable word
- Content `"Superlongitemnamedunbreakable"`, `maxWidth: 50`, `fontSize: 14` → exactly 1 child node, engine completes

### Empty string
- Content `""` → root node has 0 children, root frame height == 0, no crash

### Near-zero maxWidth
- Content `"Hello world"`, `maxWidth: 1.0` → exactly 2 children ("Hello", "world"), engine completes

## Dependencies
Slice 1 must be complete (US-01 merged).
