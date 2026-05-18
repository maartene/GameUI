# Slice 01 — Core Directional Padding

## Goal

Ship `padding(x:y:)` with correct layout and hit-test traversal as a single coherent unit.

## Scope

### IN Scope

| Component | Description |
|-----------|-------------|
| `AnyDirectionalPaddingModifier` protocol | Declares `paddingX: Float`, `paddingY: Float`, `paddingContent: any View` |
| `DirectionalPaddingModifier<Content: View>` struct | Conforms to `View` and `AnyDirectionalPaddingModifier`; carries `content`, `paddingX`, `paddingY` |
| `View.padding(x:y:)` extension | Returns `DirectionalPaddingModifier<Self>` — consistent with `padding(_:)` return type pattern |
| `PaddingModifier` conformance update | Gains `paddingX { amount }` and `paddingY { amount }` to conform to `AnyDirectionalPaddingModifier`; uniform padding is a special case where paddingX == paddingY |
| `AnyPaddingModifier` deprecation | Marked `@available(*, deprecated, renamed: "AnyDirectionalPaddingModifier")` — warning-only; not removed |
| `paddingAmount` deprecation | Marked `@available(*, deprecated, message: "Use paddingX or paddingY")` on `PaddingModifier` — warning-only |
| `layoutDirectionalPaddingNode` | New private function in `LayoutEngine`; unified handler for all padding (uniform and asymmetric) |
| `layoutPaddingNode` removal | Replaced by `layoutDirectionalPaddingNode`; no longer needed once `PaddingModifier` dispatches via `AnyDirectionalPaddingModifier` |
| `outerSizeForPaddedContent` removal | Replaced by `outerSizeForDirectionalPaddedContent(paddingX:paddingY:)` — generalised helper accepting independent x/y amounts |
| `layoutNode` dispatch branch | `AnyPaddingModifier` check **replaced** by single `AnyDirectionalPaddingModifier` check — not added before it |
| `hitTestNode` traversal branch | `AnyPaddingModifier` check **replaced** by `AnyDirectionalPaddingModifier` check; descends into `paddingContent` |

### OUT of Scope

- `padding(top:leading:bottom:trailing:)` or per-edge independent padding
- `EdgeInsets`-based padding API
- Animated padding transitions
- Padding changes at runtime (no binding/reactive support)
- Documentation beyond inline API comments

## Learning Hypothesis

This slice operates as a validation of the modifier pattern's generalisability:

- **If it succeeds**: confirms that the existing `layoutPaddingNode` pattern generalises cleanly to x/y amounts without requiring a new layout subsystem.
- **If it fails**: disproves that assumption and surfaces what additional infrastructure is needed (e.g., if `outerSizeForPaddedContent` cannot be adapted for asymmetric amounts, a broader refactor may be required).

## Acceptance Criteria

### Layout (US-PDR-01)

1. `.padding(x: 20, y: 10)` on a view with intrinsic size 100×50 → outer frame is 140×70
2. `.padding(x: 0, y: 10)` on a view with intrinsic size 80×40 → outer frame is 80×60 (width unchanged)
3. `.padding(x: 10, y: 0)` on a view with intrinsic size 80×40 → outer frame is 100×40 (height unchanged)
4. Child origin is inset by (paddingX, paddingY) from the outer frame origin
5. Outer size is clamped to `constraints.maxWidth` / `constraints.maxHeight`
6. `.padding(x: 0, y: 0)` → outer frame equals unwrapped content frame
7. Negative values are clamped to 0 via `max(0, ...)` — same guard as `layoutPaddingNode`

### Hit-Test (US-PDR-02)

1. Button wrapped in `.padding(x: 10, y: 5)` → `hitTestButton` returns the button index
2. Point inside padded button frame → index returned; point outside padded frame entirely → nil
3. Button wrapped in directional padding inside a VStack → returns correct stack-position index
4. `hitTestButton` does NOT invoke the button action during traversal

## Effort

Estimated: 3–4 hours

Breakdown:
- Protocol + struct declaration: ~30 min
- `View.padding(x:y:)` extension: ~15 min
- `layoutDirectionalPaddingNode` + `layoutNode` dispatch: ~1 hour
- `hitTestNode` dispatch branch: ~30 min
- Tests (11 acceptance tests, ~2 assertions each): ~1.5 hours

## Dependencies

None external. Internal changes in this slice:
- No new external dependencies
- `AnyPaddingModifier` and `paddingAmount` are deprecated (compile-time warnings, not errors) — not additive-only
- `layoutPaddingNode` and `outerSizeForPaddedContent` are removed (private, zero risk)
- No migration required for callers of `.padding(_:)` — concrete return type `PaddingModifier<Self>` unchanged
- If content-box semantics are chosen (recommended), the existing unit test at `LayoutEngineTests.swift:262–263` requires a 2-value update (see DISTILL DWD-04)

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| `outerSizeForPaddedContent` is not adaptable for x/y asymmetry | Resolved | — | Replaced entirely by `outerSizeForDirectionalPaddedContent(paddingX:paddingY:)`; no adaptation needed |
| `layoutNode` dispatch order causes uniform padding to shadow directional | Resolved | — | Risk eliminated structurally: `AnyPaddingModifier` branch is removed, not reordered; single `AnyDirectionalPaddingModifier` branch dispatches both types |
| `PaddingModifier` not dispatched through unified branch after Option B | Low | High | Dispatch verification test added (see acceptance tests): confirms `PaddingModifier` reaches `layoutDirectionalPaddingNode` via `AnyDirectionalPaddingModifier` |
| `hitTestNode` update missed — directional padding silently not traversed | Medium | High | AC test US-PDR-02 AC-1 catches this; written RED before implementation |
| Box-sizing semantic gap — DISCUSS ACs expect content-box, design contract has border-box helper | Medium | Medium | Crafter must choose Option X (content-box) or Z (border-box) before implementing; see DISTILL DWD-04 |
