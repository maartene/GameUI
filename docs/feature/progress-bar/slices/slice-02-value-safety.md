# Slice 02: Value Safety

## Feature
`progress-bar`

## Slice ID
02

## User Story
US-02: Trust Any Value From Game State

## Goal
Riku binds `ProgressBar(value: gameState.shieldCharge, label: "Shield charge")` straight to live game state and deletes his defensive `min(max(...))` wrapper — a mid-frame value of `1.4`, `-0.2`, or `NaN` never paints fill outside the track.

## Scope

### In
- `clampedValue` correct for every `Float`: above `1.0` → `1.0`, below `0.0` → `0.0`, `NaN` → `0.0`, `+infinity` → `1.0`, `-infinity` → `0.0`
- Property-based test: `clampedValue ∈ 0.0...1.0` for arbitrary `Float` input (AC-12)
- `value` still readable verbatim as declared (AC-14) — clamping is a render guarantee, not data loss
- Endpoint exactness: `0.0` and `1.0` pass through unchanged (AC-13)
- AC-08 … AC-14

### Out
- Everything in Slice 01 (already merged)
- Retrofitting the same clamp onto `Slider` — follow-up candidate under D7, not this slice
- Renderer-side enforcement — the whole point is that the renderer needs none

## Learning hypothesis
**Disproves D7** ("clamping belongs in the view, not the renderer") if a single `clampedValue` accessor cannot express every out-of-range case without a renderer-side guard. NaN is the specific risk: Swift's `min`/`max` propagate NaN rather than resolving it, so a naive `min(1, max(0, value))` returns NaN and pushes the guard back to the renderer. If that turns out to be unavoidable, D7 falls and clamping moves to the renderer contract.

## Acceptance criteria
See AC-08 … AC-14 in `docs/feature/progress-bar/feature-delta.md`.

## Production data
Real SpaceSim failure values observed in live game state: `1.4` (shield recharge burst overshoot), `-0.2` (damage applied before the frame's clamp), `NaN` (division by a zero max-shield capacity on a destroyed hull).

## Dogfood moment
Same day as merge — Riku deletes the defensive `min(max(shieldCharge, 0), 1)` wrapper at the SpaceSim call site and confirms the recharge burst no longer overdraws the portrait beside the bar.

## Dependencies
- Slice 01 must be merged (`ProgressBar` and `clampedValue` must exist).

## Reference class
No direct precedent in this repo — `Slider` stores `value` unguarded. Closest analogue is the `max(0, ...)` guard discipline already used throughout `layoutDirectionalPaddingNode` and `layoutWrappedTextNode`.

## Effort estimate
0.5 day.

## Pre-slice SPIKE
Not required, but the NaN ordering caveat above is a known trap — the crafter should write the NaN test first.
