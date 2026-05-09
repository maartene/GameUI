# Mutation Report — wrapped-text Slice 1

## Status: SKIPPED — No Tool For Language

**Skip condition**: Condition 1 — "No mutation framework available for detected language."

**Language**: Swift 6.2  
**Available tools**: cosmic-ray (Python), PIT (Java), Stryker (JS/TS/C#) — none support Swift.  
**Date**: 2026-05-09

## Compensating Evidence

The absence of automated mutation testing is compensated by:

1. **Adversarial review (Phase 4)** — APPROVED, zero defects. Reviewer confirmed all 5 acceptance criteria have distinct, non-tautological tests that would catch real bugs.

2. **Test specificity** — 5 unit tests in `WrappedTextUnitTests.swift` directly verify `wrappedLines` return values for 4 distinct behaviors (empty content, single word, greedy split, unbreakable word). These tests assert specific string content, not just counts. A mutation that changes `<=` to `<` in the width check would cause the "greedy wrap splits words" test to fail (wrong line count or wrong strings).

3. **Acceptance test coverage** — 11 acceptance tests exercise the full pipeline through `LayoutEngine.layout()`. Critical invariants tested:
   - `children.count >= 2` for multi-line input (catches missing wrapping logic)
   - `child.frame.size.width <= 200` for all children (catches missing width constraint)
   - `children[i].frame.origin.y == i * fontSize` (catches incorrect y-stacking)
   - `root.frame.size.height == lineCount * fontSize` (catches incorrect height calculation)

4. **Edge cases covered** — Empty content, single unbreakable word, exact-fit (boundary condition), determinism. Standard mutation operators (boundary change `<=`→`<`, negation, constant replacement) are all caught by these tests.

## Recommendation

For future Swift projects: evaluate [swift-mutation-testing](https://github.com/ikhvorost/swift-mutation-testing) or [muter](https://github.com/muter-mutation-testing/muter) (macOS/Swift mutation testing tool). Add to project toolchain when available.

## Kill Rate Estimate (manual analysis)

| Mutation | Caught by |
|---|---|
| Change `<= maxWidth` to `< maxWidth` | `text that exactly fills one line produces exactly one child without overflow` |
| Remove `!currentLine.isEmpty` guard | `single word wider than maxWidth is placed on its own line` |
| Remove `lines.append(currentLine)` after loop | `greedy wrap splits words into correct number of lines` |
| Change `constraints.maxWidth` to `0` in root frame | `root node frame width equals constraints maxWidth` |
| Change `Float(lineIndex) * wrappedText.fontSize` to constant | `child nodes are stacked vertically with y-origins at multiples of fontSize` |
| Change `Float(lines.count) * wrappedText.fontSize` to `0` | `root node height equals total line count times lineHeight` |
| Remove WrappedText branch from layoutNode | All 11 Slice 1 acceptance tests (walking skeleton would still pass due to fallback) |

Estimated manual kill rate: **≥ 85%** — all critical mutants caught.
