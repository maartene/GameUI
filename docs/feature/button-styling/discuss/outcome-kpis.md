# Outcome KPIs — button-styling

## Feature: button-styling

### Objective

Enable game developers using GameUI to ship menus where buttons are visually distinct by role,
with zero theme-change call-site churn, by the end of the button-styling delivery sprint.

---

### Outcome KPIs

| # | Who | Does What | By How Much | Baseline | Measured By | Type |
|---|-----|-----------|-------------|----------|-------------|------|
| KPI-BS-1 | Riku Nakamura (game developer with ≥2 button types per screen) | Declares button role at call site, differentiates in renderer without text-inspection | Renderer switch with N cases serves N screens — zero duplication | Currently impossible: no semantic metadata on AnyButton | Code review of adoption renderer + acceptance tests | Leading |
| KPI-BS-2 | Riku Nakamura (SpaceSim, 12 menu screens) | Changes a button theme (e.g., primary color) across all screens | Single renderer edit (1 switch case) — 0 call-site changes required | Currently requires per-screen renderer branching on text content | Count of call-site changes in a theme-change scenario | Leading |
| KPI-BS-3 | First-time adopters of AnyButton.tag | Adopt standard tag vocabulary without reading source code | Time-to-first-working-styled-button < 10 minutes from API discovery | No documented convention today | Developer feedback + Quick Help discoverability review | Leading |
| KPI-BS-4 | Existing GameUI callers (brownfield) | Continue using Button() without modification | Zero compilation errors after feature lands | N/A (new capability) | CI green on all existing tests post-merge | Guardrail |

---

### Metric Hierarchy

- **North Star**: KPI-BS-2 — game developer changes theme in 1 renderer edit with 0 call-site changes
  (this is the highest-scoring JTBD outcome, O-2 score 17)
- **Leading Indicators**:
  - KPI-BS-1: Renderer successfully reads `AnyButton.tag` for differentiation
  - KPI-BS-3: Tag vocabulary discoverable from doc comment
- **Guardrail Metrics**:
  - KPI-BS-4: No regressions in existing call sites (CI green)
  - Layout geometry must be tag-invariant (layout test — any tag value produces identical frame)
  - `isFocused` and `tag` remain independent (no cross-property interference)

---

### Measurement Plan

| KPI | Data Source | Collection Method | Frequency | Owner |
|-----|------------|-------------------|-----------|-------|
| KPI-BS-1 | Acceptance tests (UAT scenarios) | Swift Testing suite — renderer reads tag via AnyButton cast | Every CI run | nw-software-crafter |
| KPI-BS-2 | Code review of renderer change | Manual review: count lines changed in renderer for a theme update | At PR review | product-owner |
| KPI-BS-3 | Xcode Quick Help / doc comment review | Code review: verify doc comment completeness | At PR review | product-owner |
| KPI-BS-4 | CI test suite | All existing tests green post-merge | Every CI run | nw-software-crafter |

---

### Hypothesis

We believe that adding `tag: String = ""` to `AnyButton` for game developers building
multi-button menus will achieve a renderer that differentiates button roles in a single switch
statement with zero per-screen duplication.

We will know this is true when Riku's SpaceSim renderer reads `btn.tag` for all 12 menu screens
from a single switch, and a theme-color change requires editing exactly 1 switch case (not 12
call sites).

---

### OKR Connection

**Objective**: Make GameUI the go-to library for game developers who need polished, themeable menus.

**Key Results** (this feature contributes):
- KR1: Game developers can differentiate ≥3 button roles in the renderer with a single switch statement
  (no per-screen duplication) — KPI-BS-1 and KPI-BS-2
- KR2: New renderer authors discover standard tag vocabulary from Xcode Quick Help in < 10 minutes —
  KPI-BS-3

---

### Smell Test Checklist

| Check | KPI-BS-1 | KPI-BS-2 | KPI-BS-3 | KPI-BS-4 |
|-------|----------|----------|----------|----------|
| Measurable today? | Yes (acceptance test) | Yes (count call-site changes) | Qualitative (doc review) | Yes (CI) |
| Rate not total? | N/A (boolean capability) | Count (0 = pass) | Qualitative | Boolean (green/red) |
| Outcome not output? | Yes (renderer behaviour) | Yes (developer behaviour) | Yes (developer behaviour) | Guardrail (regression) |
| Has baseline? | Yes (impossible today) | Yes (scattered today) | Yes (no docs today) | N/A |
| Team can influence? | Yes (add tag to protocol) | Yes (tag enables this) | Yes (add doc comment) | Yes (default value) |
| Has guardrails? | KPI-BS-4 | KPI-BS-4 | KPI-BS-4 | Is the guardrail |
