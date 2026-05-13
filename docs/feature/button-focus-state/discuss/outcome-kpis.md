# Outcome KPIs — button-focus-state

## KPI 1 — Zero Regression at Existing Call Sites

**What**: All existing `Button(action:content:)` call sites in the project compile unchanged after the change.  
**Target**: 0 compilation errors at existing call sites.  
**Measurement**: `swift build` on the GameUI package after the change. Any error at an existing Button initialisation is a KPI failure.  
**Rationale**: `isFocused` must default to `false` — no consumer is forced to update.

---

## KPI 2 — All 5 AC Scenarios Pass

**What**: The 5 Gherkin scenarios in the brief pass as Swift Testing tests.  
**Target**: 5 / 5 scenarios pass, 0 failures.  
**Measurement**: `swift test` output — all scenario-mapped tests green.  
**Rationale**: The scenarios are the complete specification; anything below 100% means the feature is not done.

---

## KPI 3 — isFocused Inspectable Without Renderer

**What**: `isFocused` can be read from a `Button` value with no Raylib or rendering context.  
**Target**: Test reads `isFocused` in a pure Swift Testing context (no window, no OpenGL, no GUIContext) — passes.  
**Measurement**: Test suite runs in CI (Linux, no display) without crashing or skipping.  
**Rationale**: Hard constraint from brief — value-type inspectability is the core contract.

---

## KPI 4 — Mutation Kill Rate ≥ 80%

**What**: Mutation testing (per-feature strategy per CLAUDE.md) kills ≥ 80% of mutants introduced into the `isFocused` property and its initialiser.  
**Target**: Kill rate ≥ 80%.  
**Measurement**: Run `/nw-mutation-test` after implementation; report kill rate from mutation-report.md.  
**Rationale**: Project mutation testing strategy is `per-feature`; this is a new feature.
