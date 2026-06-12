# Outcome KPIs: wrapped-text-max-lines

## Feature: wrapped-text-max-lines

### Objective

Enable game developers using GameUI to declare a fixed-height text reservation at the `WrappedText` call site — so narrative screens with variable-length content have stable, non-shifting layouts without pixel arithmetic.

---

### Outcome KPIs

| # | Who | Does What | By How Much | Baseline | Measured By | Type |
|---|-----|-----------|-------------|----------|-------------|------|
| 1 | Game developer building narrative HUD screens | Declares `maxLines` at the `WrappedText` call site and gets a layout that never shifts surrounding elements | Layout height is constant (`maxLines × lineHeight`) across all content lengths — verified by all Slice 01 tests green | Currently requires `VStack + Spacer + .frame(height:)` workaround with manual pixel math; height breaks when `fontSize` changes | Unit test suite: all US-04 UAT scenarios pass | Leading |
| 2 | Game developer using boundary `maxLines` values (0, 1, empty content) | Uses any non-negative `maxLines` without defensive guard code | 0 crashes or unexpected layout from `maxLines: 0`, `maxLines: 1`, or empty content — all Slice 02 tests green | Undefined behaviour for `maxLines: 0` + empty content without explicit semantics | Unit test suite: all US-05 UAT scenarios pass | Leading |
| 3 | Game developer changing font size or DPI | Resizes narration area by changing `fontSize` only | Reserved height adapts automatically (`maxLines * newFontSize`); no pixel constant to update | Current workaround requires updating `height: N * lineHeight` constant in multiple places | Code review: no hardcoded pixel values in call sites after migration | Leading |

---

### Metric Hierarchy

- **North Star**: Game developer declares `WrappedText(content: line.text, fontSize: 22, maxLines: 3)` once and the surrounding layout never shifts — confirmed by stable `frame.size.height` in all layout tests.
- **Leading Indicators**:
  - All Slice 01 UAT scenarios green (floor + ceiling correctness)
  - All Slice 02 UAT scenarios green (edge-case safety)
  - No existing wrapped-text tests regress (guardrail)
- **Guardrail Metrics**:
  - All US-01 through US-03 tests remain green (no regression from `maxLines: nil` path)
  - No Foundation imports introduced
  - `maxLines` is intrinsic to `WrappedText` — no `FrameModifier` wrapper in the view tree

---

### Measurement Plan

| KPI | Data Source | Collection Method | Frequency | Owner |
|-----|------------|-------------------|-----------|-------|
| KPI-1: Stable height | US-04 test suite | Automated CI test run | At Slice 01 merge | CI pipeline |
| KPI-2: Boundary safety | US-05 test suite | Automated CI test run | At Slice 02 merge | CI pipeline |
| KPI-3: No pixel constants | Code review of SpaceSim call sites | Manual review of migrated usage | At feature release | Riku (developer) |
| Guardrail: no regression | Existing wrapped-text test suite | Automated CI on every PR | Continuous | CI pipeline |

---

### Hypothesis

We believe that adding `maxLines: Int?` as an intrinsic property to `WrappedText`, with `layoutWrappedTextNode` using `maxLines * lineHeight` as the reserved height, will enable game developers building SpaceSim narrative screens to declare fixed-area text regions without pixel arithmetic.

We will know this is true when:
- `WrappedText(content: anyNarrationLine, fontSize: 22, maxLines: 3)` always produces `root.frame.size.height == 66.0` — verified by Slice 01 tests across short, exact, and long content.
- `maxLines: 0`, `maxLines: 1`, and empty content produce safe, predictable output without defensive code — verified by Slice 02 tests.
- All existing wrapped-text tests pass with zero regressions.
