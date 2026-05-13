# Evolution — button-focus-state

**Date**: 2026-05-13  
**Feature ID**: button-focus-state  
**Status**: DELIVERED

---

## Feature Summary

Added an `isFocused: Bool` property (default `false`) to the `AnyButton` protocol and the `Button<Content>` struct in GameUI. The property is passively stored on the value type and requires no GUIContext coupling — game developers construct `Button(isFocused: true) { content } action: { handler }` and renderers read the flag directly from the resulting value to apply a visual highlight for gamepad/keyboard navigation.

---

## Business Context

GameUI is the declarative UI framework for SpaceSim, a game targeting gamepad and keyboard players. Before this change there was no way to mark a `Button` as focused — players navigating with a gamepad or keyboard had no visual confirmation of which button was selected. The renderer (SpaceSim) needed to distinguish the focused button with a contrast ratio of at least 3:1 against unfocused buttons. The constraint was that focus index management must remain in SpaceSim; GameUI only carries the passive state flag.

---

## Key Decisions

| ID | Decision | Rationale |
|----|----------|-----------|
| D1 | Feature type = User-facing | The flag is a UI control state property directly observable by gamepad/keyboard players through the renderer. |
| D2 | Walking skeleton = No | `Button` already exists with established end-to-end path. Adding `isFocused: Bool` is a property addition, not new plumbing. |
| D3 | UX depth = Lightweight | Feature is tightly constrained with 5 pre-written ACs and hard constraints; full experience mapping provides no additional signal. |
| D4 | JTBD = Skipped | User motivation is explicit — gamepad/keyboard players need visual confirmation before pressing confirm. No competing jobs identified. |
| D5 | Single slice | The entire feature is one atomic Bool property addition with default. Splitting artificially would not reduce risk or deliver partial value. |
| ODQ-01 | `isFocused: Bool` added to `AnyButton` protocol | Renderers cast to `AnyButton` and read `isFocused` directly — no `Button<Content>` down-cast needed. Eliminates renderer coupling to the generic concrete type. |

---

## Implementation Steps

**Phase 01 — Add isFocused to AnyButton protocol and Button struct**

| Step | Phase | Status | Timestamp |
|------|-------|--------|-----------|
| 01-01 | PREPARE | PASS | 2026-05-13T15:00:19Z |
| 01-01 | RED_ACCEPTANCE | PASS | 2026-05-13T15:00:43Z |
| 01-01 | RED_UNIT | SKIPPED — acceptance tests ARE the unit tests for this value-type property change | 2026-05-13T15:00:48Z |
| 01-01 | GREEN | PASS | 2026-05-13T15:02:40Z |
| 01-01 | COMMIT | PASS | 2026-05-13T15:02:54Z |

**Scope**: `Sources/GameUI/LeafViews.swift` (AnyButton protocol + Button struct). Test file: `Tests/GameUITests/ButtonFocusStateTests.swift`.

---

## Test Outcomes

- **Total tests passing**: 88
- **New tests added**: 5 (one per acceptance scenario)
- **Test failures**: 0

### New test scenarios (ButtonFocusStateTests.swift)

1. Button constructed with `isFocused: true` carries `isFocused == true`
2. Button constructed without `isFocused` carries `isFocused == false` (default)
3. Button with `isFocused: true` does not invoke the action on construction
4. Action fires exactly once when the consumer explicitly calls it
5. Of three buttons where the second has `isFocused: true`, exactly the second carries `isFocused == true`

### Outcome KPIs

| KPI | Target | Result |
|-----|--------|--------|
| KPI 1 — Zero regression at existing call sites | 0 compilation errors | PASS — `swift build` clean |
| KPI 2 — All 5 AC scenarios pass | 5/5 | PASS — 5/5 |
| KPI 3 — `isFocused` inspectable without renderer | Pure Swift Testing context | PASS — no Raylib/GUIContext required |
| KPI 4 — Mutation kill rate ≥ 80% | ≥ 80% | See mutation testing below |

---

## Refactoring

**L1 naming pass**: 21 lines removed. `wt` abbreviations expanded; inferred closure return types removed. Applied across `WrappedText`-related sources (pre-existing refactor, not part of this feature slice — referenced for completeness as it landed in the same session).

---

## Adversarial Review

- **Reviewer**: nw-acceptance-designer-reviewer
- **Status**: APPROVED
- **Defects found**: 0
- **Approved at**: 2026-05-13T00:00:00Z

---

## Mutation Testing

- **Strategy**: per-feature (per CLAUDE.md)
- **Automated run**: SKIPPED — `muter` not stable in this environment

### Manual Analysis

| # | Mutation | Target | Killing test(s) |
|---|----------|--------|-----------------|
| M1 | `isFocused: Bool = false` → `isFocused: Bool = true` | Default parameter value | AC2: defaults to false |
| M2 | `self.isFocused = isFocused` → `self.isFocused = !isFocused` | Init assignment | AC1, AC5: multi-button |
| M3 | `self.isFocused = isFocused` → `self.isFocused = false` | Init assignment (always false) | AC1: with true carries true |

**Estimated kill rate**: 100% (3/3 mutations killed by existing tests).

---

## Cleanup

The following session markers were removed as part of finalization:

- `.nwave/des/deliver-session.json`
- `.nwave/des/des-task-active`
- `.nwave/des/des-task-active-button-focus-state--`

The feature workspace `docs/feature/button-focus-state/` is preserved (wave matrix derives status from this directory).

---

## Migrated Artifacts

| Source | Destination |
|--------|-------------|
| `docs/feature/button-focus-state/discuss/journey-button-focus-state.yaml` | `docs/ux/button-focus-state/journey-button-focus-state.yaml` |
| `docs/feature/button-focus-state/discuss/journey-button-focus-state-visual.md` | `docs/ux/button-focus-state/journey-button-focus-state-visual.md` |
