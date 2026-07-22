# Slice 01: Declare and Fill

## Feature
`progress-bar`

## Slice ID
01

## User Story
US-01: Declare a Progress Bar with Chosen Colors

## Goal
Riku declares `ProgressBar(value: 0.65, label: "Shield charge", fillColor: .green, trackColor: .darkGray)` inside a `.frame(width: 200, height: 20)` and gets back a layout node sized exactly `200 × 20` from which a renderer draws a dark track with a 130-point green fill.

## Scope

### In
- `Sources/GameUI/ProgressBar.swift` — `public struct ProgressBar: View` with `value: Float`, `label: String`, `fillColor: Color`, `trackColor: Color`, `body: Never`
- Default parameter values `fillColor: .green`, `trackColor: .darkGray`
- Layout participation via the existing fill-constraints default (`LayoutEngine.swift:68`) — **no new branch**
- `clampedValue` accessor exists and is correct for in-range values only (`0.0…1.0`)
- Fill-width arithmetic verified: `frame.size.width * clampedValue`
- Confirmation that `hitTestButton` returns `nil` for a `ProgressBar`
- AC-01 … AC-07

### Out
- Out-of-range and NaN handling — Slice 02
- Property-based coverage of the clamp invariant — Slice 02
- Indeterminate state, percentage text, vertical orientation, animation — out of feature scope
- Any change to `Slider`

## Learning hypothesis
**Disproves D8** ("a display-only bar needs no `LayoutEngine` branch") if the fill-constraints default at `LayoutEngine.swift:68` produces a wrong or surprising frame for a `ProgressBar` — either bare or wrapped in `.frame(...)`. If it holds, `ProgressBar` is confirmed as a pure leaf on the `Slider`/`Checkbox` pattern and the remaining work is value semantics only.

## Acceptance criteria
See AC-01 … AC-07 in `docs/feature/progress-bar/feature-delta.md`.

## Production data
Real SpaceSim HUD values: shield charge `0.65`, `.green` on `.darkGray`, `200 × 20` HUD bar geometry, `400 × 300` panel constraints. No synthetic placeholder values.

## Dogfood moment
Same day as merge — Riku replaces the bespoke two-`Rectangle` shield-charge indicator in the SpaceSim launch screen with a single `ProgressBar` declaration (KPI-5).

## Dependencies
- `View`, `Color`, `LayoutEngine` fill-constraints default — all merged.

## Reference class
`Slider` (`Sources/GameUI/Slider.swift`, 17 lines) and `Checkbox` (`Sources/GameUI/Checkbox.swift`, 18 lines) — both leaf primitives with no `LayoutEngine` branch. `ProgressBar` is the same shape.

## Effort estimate
1 day.

## Pre-slice SPIKE
Not required — uncertainty is low and the reference class is two merged, near-identical types in the same module.
