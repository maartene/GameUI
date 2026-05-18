# Shared Artifacts Registry — padding-directional

All variables that flow across journey steps, protocol boundaries, or module boundaries for the `padding-directional` feature.

---

## paddingX

| Field | Value |
|-------|-------|
| **Source of Truth** | `DirectionalPaddingModifier.paddingX: Float` |
| **Owner** | padding-directional feature |
| **Consumers** | `layoutDirectionalPaddingNode` (horizontal inset calc), `AnyDirectionalPaddingModifier` protocol requirement, tests asserting frame width |
| **Integration Risk** | HIGH — if `paddingX` is swapped with `paddingY` in the layout function, all x-axis assertions fail silently |
| **Validation** | Unit tests assert `outer.width == content.width + 2 * paddingX` |

---

## paddingY

| Field | Value |
|-------|-------|
| **Source of Truth** | `DirectionalPaddingModifier.paddingY: Float` |
| **Owner** | padding-directional feature |
| **Consumers** | `layoutDirectionalPaddingNode` (vertical inset calc), `AnyDirectionalPaddingModifier` protocol requirement, tests asserting frame height |
| **Integration Risk** | HIGH — same axis-swap risk as paddingX |
| **Validation** | Unit tests assert `outer.height == content.height + 2 * paddingY` |

---

## content (paddingContent)

| Field | Value |
|-------|-------|
| **Source of Truth** | `AnyDirectionalPaddingModifier.paddingContent: any View` |
| **Owner** | `DirectionalPaddingModifier<Content>` struct |
| **Consumers** | `layoutDirectionalPaddingNode` (recursive child layout), `hitTestNode` (traversal descent), tests constructing wrapper views |
| **Integration Risk** | MEDIUM — if `paddingContent` returns a different view than the wrapped content, layout and hit-test will diverge |
| **Validation** | `DirectionalPaddingModifier.paddingContent` returns `self.content` — verified by struct conformance |

---

## LayoutNode (outer)

| Field | Value |
|-------|-------|
| **Source of Truth** | Return value of `layoutDirectionalPaddingNode(_:in:origin:)` |
| **Owner** | `LayoutEngine` |
| **Consumers** | Renderer (frame for drawing), `hitTestButton` (bounds for point-in-rect check), acceptance tests asserting `frame.size` |
| **Integration Risk** | HIGH — the outer node's frame is the integration contract between layout and every downstream consumer |
| **Validation** | Acceptance tests assert `rootNode.frame.size == Size(width: content.width + 2*x, height: content.height + 2*y)` |

---

## LayoutNode (child)

| Field | Value |
|-------|-------|
| **Source of Truth** | First child of the outer `LayoutNode` produced by `layoutDirectionalPaddingNode` |
| **Owner** | `LayoutEngine` |
| **Consumers** | Renderer (origin for drawing content at inset position), acceptance tests asserting `children[0].frame.origin` |
| **Integration Risk** | MEDIUM — wrong child origin shifts rendered content; not caught by outer-size tests alone |
| **Validation** | Tests assert `rootNode.children[0].frame.origin == Point(x: origin.x + paddingX, y: origin.y + paddingY)` |

---

## AnyDirectionalPaddingModifier

| Field | Value |
|-------|-------|
| **Source of Truth** | Protocol declaration in `View.swift` (or alongside `AnyPaddingModifier`) |
| **Owner** | padding-directional feature |
| **Consumers** | `layoutNode` dispatch (pattern match), `hitTestNode` dispatch (pattern match) |
| **Integration Risk** | HIGH — both dispatch sites must be updated together; updating only one leaves the other silently broken |
| **Validation** | Acceptance test for hit-test would fail if `hitTestNode` is not updated; layout test would fail if `layoutNode` is not updated |

---

## Integration Checkpoint Summary

| Checkpoint | Risk | Verification |
|-----------|------|-------------|
| `layoutNode` checks `AnyDirectionalPaddingModifier` before `AnyPaddingModifier` | HIGH — order matters if types ever overlap | Integration test confirms directional modifier routes to `layoutDirectionalPaddingNode` |
| `hitTestNode` checks `AnyDirectionalPaddingModifier` | HIGH — missing branch = nil for valid taps | Hit-test acceptance test (Story 2, AC-1) |
| `paddingX` / `paddingY` not transposed | HIGH | Both axes tested independently with asymmetric values |
| Outer size clamped to constraints | MEDIUM | Constraint-clamping scenario in .feature file |
| Negative values clamped to zero | LOW | Negative-value scenario in .feature file |
