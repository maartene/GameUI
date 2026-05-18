# Story Map: padding-directional

## User
**Alex Reyes** — game developer building HUD panels in Swift using GameUI

## Goal
Apply different horizontal and vertical padding to any view and have the layout engine and hit-testing pipeline respect those insets correctly.

---

## Backbone

| Discover Need | Apply Modifier | Lay Out | Hit-Test |
|---------------|---------------|---------|----------|
| Recognise `.padding(_:)` cannot express x/y insets | Call `.padding(x:y:)` on any view | `LayoutEngine.layout(...)` computes correct outer + child frames | `hitTestButton(view:node:at:)` traverses directional padding wrapper |
| Consider nesting two `.padding` calls (workaround) | `DirectionalPaddingModifier<Content>` produced | Outer size = content + 2x / 2y | Button index returned for point inside padded frame |
| | `AnyDirectionalPaddingModifier` protocol conformance | Child origin inset by (x, y) | Returns nil for point outside frame |
| | | Outer size clamped to constraints | Does not invoke button action during traversal |
| | | Negative values clamped to zero | |

---

## Walking Skeleton

The walking skeleton is the thinnest end-to-end slice that makes the modifier usable:

1. **Discover Need** — `View.padding(x:y:)` extension exists and returns `DirectionalPaddingModifier<Self>`
2. **Apply Modifier** — `AnyDirectionalPaddingModifier` protocol declared; `DirectionalPaddingModifier` struct conforms
3. **Lay Out** — `layoutDirectionalPaddingNode` dispatched from `layoutNode`; outer frame width = content.width + 2*x, height = content.height + 2*y
4. **Hit-Test** — `hitTestNode` descends through `AnyDirectionalPaddingModifier` wrapper

All four activities must ship together — removing any one leaves a broken interface.

---

## Slice 1: Core Directional Padding (= Walking Skeleton for this feature)

Because this feature is a tight extension of the existing modifier pattern with no optional enhancements to defer, the walking skeleton and the complete slice are identical.

**Stories in this slice:**
- **US-PDR-01**: Directional padding layout — correct outer size and child origin
- **US-PDR-02**: Hit-test traversal through directional padding wrapper

**Outcome targeted:** Game developers can apply `.padding(x:y:)` and have it work correctly in both layout and pointer input without any special casing.

---

## Scope Assessment: PASS

- Stories: 2
- Bounded contexts: 1 (GameUI library internals — View API, LayoutEngine, HitTest)
- Estimated effort: 3–4 hours
- Integration points in walking skeleton: 3 (View extension → LayoutEngine dispatch → HitTest dispatch)
- All stories ship as one slice; no independent deliverable can be carved out without leaving the codebase broken

## Priority Rationale

Both stories ship together in a single slice. Priority between them is implementation-order, not business-priority:

1. **US-PDR-01 (Layout)** — must be implemented first: `AnyDirectionalPaddingModifier` protocol and `DirectionalPaddingModifier` struct are prerequisites for US-PDR-02.
2. **US-PDR-02 (Hit-test)** — must ship in the same slice: a directional-padded button that lays out correctly but fails hit-testing is a regression in interactive UI.

Shipping layout without hit-test (or vice versa) would leave the library in a half-working state. The coupling is intentional — both dispatch sites consume the same `AnyDirectionalPaddingModifier` protocol.
