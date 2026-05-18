# Prioritization: padding-directional

## Release Priority

| Priority | Slice | Target Outcome | KPI | Rationale |
|----------|-------|---------------|-----|-----------|
| 1 | Slice 01 — Core Directional Padding | Game developer can apply `.padding(x:y:)` and receive correct layout + hit-test with a single call | 11/11 AC tests pass; 0 regressions in existing padding tests | Single coherent unit; all parts tightly coupled |

## Why a Single Slice

This feature is a brownfield extension of the existing `PaddingModifier` / `AnyPaddingModifier` pattern. The work decomposes into four implementation tasks that share one protocol (`AnyDirectionalPaddingModifier`):

1. Declare `AnyDirectionalPaddingModifier` protocol and `DirectionalPaddingModifier<Content>` struct
2. Add `View.padding(x:y:)` extension
3. Add `layoutDirectionalPaddingNode` and dispatch branch in `layoutNode`
4. Add `AnyDirectionalPaddingModifier` branch in `hitTestNode`

Tasks 3 and 4 both depend on task 1. Shipping task 3 without task 4 produces a layout-correct but hit-test-broken library state. There is no sub-slice that delivers independently verifiable value to the game developer.

## Coupling Rationale

`AnyDirectionalPaddingModifier` is consumed at two separate call sites (layout dispatch and hit-test dispatch). These are not independent features — they are two halves of the same contract. A game developer who calls `.padding(x:y:)` expects both layout and pointer input to work. Splitting them across releases would require either:

- A release with broken hit-test (unacceptable), or
- A release with an unusable API that the developer cannot actually apply to interactive views (no value)

Neither split is viable. Single slice is the correct delivery unit.

## Backlog

| Story | Slice | Priority | Outcome Link | Dependencies |
|-------|-------|----------|-------------|--------------|
| US-PDR-01 Directional padding layout | Slice 01 | P1 | KPI-1: 7/7 layout AC pass | None |
| US-PDR-02 Hit-test traversal through directional padding | Slice 01 | P1 (same slice) | KPI-2: 4/4 hit-test AC pass | US-PDR-01 (protocol declaration) |

## Out of Scope (Explicitly Deferred)

These are not part of any planned slice:

- `padding(top:leading:bottom:trailing:)` — four-sided independent padding
- `padding(EdgeInsets)` — EdgeInsets-based API
- Animated padding transitions
- Padding with per-axis negative insets (beyond zero-clamping)
