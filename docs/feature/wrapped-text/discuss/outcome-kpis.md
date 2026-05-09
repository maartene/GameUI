# Outcome KPIs: wrapped-text

## Feature: wrapped-text

### Objective

Enable game developers using GameUI to render arbitrary-length text in constrained areas without manual line-break computation — so HUD panels, dialogue boxes, and quest logs are built faster and adapt automatically to layout changes.

---

### Outcome KPIs

| # | Who | Does What | By How Much | Baseline | Measured By | Type |
|---|-----|-----------|-------------|----------|-------------|------|
| 1 | Game developer building HUD panels | Declares `WrappedText` and gets correct multi-line layout in a single session | Completes working multi-line panel in < 30 min from first declaration | Currently requires manual VStack + multiple Text nodes with hard-coded line breaks (30–90 min of trial/error per panel) | Internal developer integration time; unit test pass rate for Slice 1 scenarios | Leading |
| 2 | Game developer with unexpected content (no spaces, empty strings) | Uses `WrappedText` without defensive guard code | 0 crashes or infinite loops from any boundary input | No robustness handling exists (baseline = crash risk for any single-word content wider than maxWidth) | Slice 2 test suite: all 4 error-path scenarios green | Leading |
| 3 | Game developer integrating custom renderer | Adds `WrappedText` renderer support by following README example | Under 15 minutes without reading engine source | No documented renderer pattern for `WrappedText` exists | Self-report; README example verified against test suite | Leading |

---

### Metric Hierarchy

- **North Star**: Game developer declares `WrappedText` and ships a working multi-line HUD panel in a single session (< 30 min, zero manual line-break computation).
- **Leading Indicators**:
  - Slice 1 test suite 100% green (layout correctness proxy)
  - Slice 2 test suite 100% green (robustness/safety proxy)
  - README example covers `WrappedText` renderer pattern (adoption proxy)
- **Guardrail Metrics**:
  - Existing `Text`, `HStack`, `VStack` layout tests remain 100% green (no regression)
  - `LayoutEngine` layout is side-effect-free and deterministic (same input → same output)
  - No Foundation, no CGFloat imports introduced (purity constraint not broken)

---

### Measurement Plan

| KPI | Data Source | Collection Method | Frequency | Owner |
|-----|------------|-------------------|-----------|-------|
| KPI-1: < 30 min to working panel | Developer integration (reference Raylib project) | Manual timing; unit test coverage as proxy | At Slice 1 merge | Riku (developer) |
| KPI-2: 0 crashes from boundary inputs | Slice 2 test suite | Automated CI test run | At Slice 2 merge | CI pipeline |
| KPI-3: < 15 min renderer integration | Developer report; README verification | Code review + README test | At Slice 3 merge | Reviewer |
| Guardrail: no regression | Existing test suite | Automated CI on every PR | Continuous | CI pipeline |

---

### Hypothesis

We believe that a greedy word-wrap `LayoutEngine` branch, combined with char-count fallback and boundary-input guards, will enable game developers using GameUI to render multi-line text in HUD panels without manual line-break computation.

We will know this is true when:
- A developer (Riku) can declare `WrappedText` and get correct child nodes in a single layout pass — verified by Slice 1 tests.
- All boundary inputs (empty string, unbreakable word, near-zero maxWidth, no measurer) produce safe, non-crashing output — verified by Slice 2 tests.
- A renderer developer can follow the README example to add `WrappedText` support without reading `LayoutEngine.swift` internals — verified at Slice 3.
