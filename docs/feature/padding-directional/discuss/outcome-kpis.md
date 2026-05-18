# Outcome KPIs — padding-directional

## Feature: padding-directional

### Objective

Make directional padding a first-class, zero-friction API in GameUI so that game developers can express horizontal and vertical inset balance precisely, and have layout and pointer input both work correctly — shipped in one slice, with no regressions.

---

### Outcome KPIs

| # | Who | Does What | By How Much | Baseline | Measured By | Type |
|---|-----|-----------|-------------|----------|-------------|------|
| 1 | Game developer (Alex Reyes) | Calls `.padding(x:y:)` once instead of nesting or writing a custom modifier | 1-call API replaces any workaround — verified by smoke test | No `.padding(x:y:)` API exists | Code review + README example | Leading |
| 2 | CI test suite | Passes all directional-padding layout acceptance tests | 7 of 7 layout AC tests pass (US-PDR-01) | 0/7 (no tests exist pre-feature) | Swift Testing test suite on every commit | Leading |
| 3 | CI test suite | Passes all hit-test acceptance tests for directional-padded views | 4 of 4 hit-test AC tests pass (US-PDR-02) | 0/4 (no tests exist pre-feature) | Swift Testing test suite on every commit | Leading |
| 4 | CI test suite | Does not regress any existing `.padding(_:)` tests | 0 failures in pre-existing padding tests after merge | All existing padding tests green pre-merge | Swift Testing test suite on every commit | Guardrail |
| 5 | Game developer | Applies directional padding to interactive views without false-negative hit-test results | 0 nil returns from `hitTestButton` for valid taps on directional-padded buttons in test suite | Not applicable (new behaviour) | Acceptance test suite | Leading |

---

### Metric Hierarchy

- **North Star**: All 11 acceptance criteria pass with 0 regressions (KPI-2 + KPI-3 + KPI-4 combined)
- **Leading Indicators**:
  - Layout correctness: outer frame = content + 2*x width, content + 2*y height (KPI-2)
  - Hit-test completeness: directional-padded buttons always reachable (KPI-3, KPI-5)
- **Guardrail Metrics**:
  - Existing `.padding(_:)` test suite remains fully green (KPI-4)
  - `AnyPaddingModifier` dispatch not broken by new `AnyDirectionalPaddingModifier` check order

---

### Measurement Plan

| KPI | Data Source | Collection Method | Frequency | Owner |
|-----|------------|-------------------|-----------|-------|
| KPI-1: API adoption | Source code + README | Code review confirms `.padding(x:y:)` is the idiomatic call | At merge | nw-software-crafter |
| KPI-2: Layout AC pass | Swift Testing output | Automated test run in CI | Every commit | CI pipeline |
| KPI-3: Hit-test AC pass | Swift Testing output | Automated test run in CI | Every commit | CI pipeline |
| KPI-4: No regression | Swift Testing output | Full suite run at merge | At merge | CI pipeline |
| KPI-5: No false negatives | Swift Testing output | Hit-test scenarios in DISTILL wave | At merge | nw-acceptance-designer |

---

### Hypothesis

We believe that adding `AnyDirectionalPaddingModifier` protocol + `DirectionalPaddingModifier<Content>` struct + `View.padding(x:y:)` extension + `layoutDirectionalPaddingNode` + `hitTestNode` branch for game developers using GameUI will achieve the north-star KPI of 11/11 acceptance criteria passing with 0 regressions.

We will know this is true when the Swift Testing suite reports 11 new green tests and all pre-existing padding tests remain green on the merge commit.
