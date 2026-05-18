# Outcome KPIs — hit-test-button

## Feature: hit-test-button

### Objective

Eliminate per-screen hover boilerplate so that any new SpaceSim screen gets
correct mouse hover highlighting by calling one GameUI function, with zero
manual frame extraction code, within the current sprint.

### Outcome KPIs

| # | Who | Does What | By How Much | Baseline | Measured By | Type |
|---|---|---|---|---|---|---|
| 1 | Game screen developers (Riku's role) | Implement hover without per-screen boilerplate | 4 boilerplate pieces → 0 per new screen (100% reduction) | Every hover-capable screen carries all 4 pieces manually | Count boilerplate-carrying screens vs. hitTestButton-calling screens in SpaceSim codebase | Leading |
| 2 | Game screen developers | Add hover to a new screen | Time-to-correct-hover ≤ 5 minutes (one function call + wiring) | Estimated 30–60 min of boilerplate writing and debugging per screen | Peer code review: time from "screen compiles" to "hover works correctly" | Leading |
| 3 | GameUI library | Preserve zero regressions in existing button behavior | 0 existing tests broken, 0 button actions fired during hit-test | Baseline: all GameUITests green | CI test run post-merge | Guardrail |

### Metric Hierarchy

- **North Star**: Game screen developers implement hover in ≤ 5 minutes per screen (leading indicator of API usability)
- **Leading Indicators**:
  - Boilerplate piece count per screen trending to zero
  - Number of screens calling `hitTestButton` vs. carrying manual traversal
- **Guardrail Metrics**:
  - Existing GameUITests remain green (zero regressions)
  - `hitTestButton` never fires a button action (pure query function)

### Measurement Plan

| KPI | Data Source | Collection Method | Frequency | Owner |
|---|---|---|---|---|
| Boilerplate elimination | SpaceSim codebase | Code review / grep for boilerplate pattern | At merge + next screen addition | Riku / PO |
| Time-to-hover | Developer observation | Peer review stopwatch or retrospective estimate | At first adoption | Riku |
| Zero regressions | CI | Automated test run | Every PR | CI / Crafter |

### Hypothesis

We believe that providing `hitTestButton(view:node:at:)` as a single GameUI
public function for game screen developers will achieve zero-boilerplate hover
implementation per new screen.
We will know this is true when game screen developers implement mouse hover in
a new screen without writing any of the four boilerplate pieces, in under 5
minutes.
