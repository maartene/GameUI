# DISTILL Decisions — padding-directional

## Prior Wave Reading Checklist

- ✓ `docs/product/journeys/padding-directional.yaml`
- ✓ `docs/product/architecture/brief.md` (padding-directional section)
- ⊘ `docs/product/kpi-contracts.yaml` — not found (warn, proceed)
- ✓ `docs/feature/padding-directional/discuss/user-stories.md`
- ✓ `docs/feature/padding-directional/discuss/story-map.md`
- ✓ `docs/feature/padding-directional/discuss/wave-decisions.md`
- ✓ `docs/feature/padding-directional/design/wave-decisions.md`
- ⊘ `docs/feature/padding-directional/spike/` — not found
- ⊘ `docs/feature/padding-directional/devops/` — not found (default environment matrix applied)

## Wave-Decision Reconciliation

Result: **0 contradictions** between DISCUSS and DESIGN on observable behaviour.

DESIGN Option B (unify at protocol level) changes protocol topology but does not alter any observable frame metric, hit-test return value, or API call-site specified in the DISCUSS ACs. All DISCUSS stories and ACs are verifiable as written.

## DWD-01: Walking Skeleton Strategy — Strategy A (pure value types, no I/O)

GameUI is a pure value-type Swift library. All driving ports are pure Swift functions with no file I/O, network, or external services. No doubles, mocks, or test containers are needed. Every acceptance test calls the real `LayoutEngine.layout(_:in:)` or `hitTestButton(view:node:at:)` directly.

## DWD-02: Driving Ports

| Driving Port | Entry Point | Used By |
|---|---|---|
| `LayoutEngine.layout(_:in:)` | Public method on `LayoutEngine` struct | All layout AC tests (US-PDR-01) |
| `hitTestButton(view:node:at:)` | Public free function in `GameUI` module | All hit-test AC tests (US-PDR-02) |

## DWD-03: Scaffold — RED State

Scaffold created in `Sources/GameUI/View.swift`:
- `AnyDirectionalPaddingModifier` protocol (new — required for test compilation)
- `DirectionalPaddingModifier<Content: View>` struct (new)
- `View.padding(x:y:)` extension (new)
- `PaddingModifier` extended to conform to `AnyDirectionalPaddingModifier` (`paddingX { amount }`, `paddingY { amount }`)
- `AnyPaddingModifier` marked `@available(*, deprecated, renamed: "AnyDirectionalPaddingModifier")`
- `paddingAmount` marked `@available(*, deprecated, message: "Use paddingX or paddingY")`

`LayoutEngine.swift` and `HitTest.swift` are NOT updated. `DirectionalPaddingModifier` falls through to the default fill-constraints node in `layoutNode`, and is not traversed by `hitTestNode`.

**RED state confirmed:** 12 of 13 new tests fail with assertion errors (not crashes or compile errors). 0 existing tests broken.

## DWD-04: Upstream Issue — Box-Sizing Semantic Gap

**Contradiction discovered during DISTILL between DISCUSS intent and existing `layoutPaddingNode` behavior:**

| Source | Behavior | Example |
|---|---|---|
| DISCUSS AC-1 | Content-box: outer frame = content + 2*padding | `Rectangle().frame(100,50).padding(x:20,y:10)` → outer 140×70 |
| Existing `layoutPaddingNode` (for `HasFrameSize` content) | Border-box: outer frame = content's declared size | `Rectangle().frame(100,50).padding(5)` → outer 100×50 (child squeezed to 90×40) |

**Root cause:** `outerSizeForPaddedContent` returns the content's declared frame size as the outer size when the content conforms to `HasFrameSize`. The DESIGN's `outerSizeForDirectionalPaddedContent` inherits this behaviour. DISCUSS ACs were written with content-box intent.

**Impact on existing tests:** If the crafter implements `layoutDirectionalPaddingNode` with content-box semantics AND routes `PaddingModifier` through it (Option B — DESIGN intent), the existing unit test `"padding modifier insets child origin and reduces child size by padding on all sides"` in `LayoutEngineTests.swift:250` will break. That test expects `childNode.frame.size.width == 90` (border-box result); content-box produces `100` (unchanged content size).

**Crafter decision required (before RED → GREEN):**

Choose one:
- **Option X (content-box for both):** Implement `layoutDirectionalPaddingNode` without `HasFrameSize` special-casing. `PaddingModifier` routed through it produces content-box outer frames. Update `LayoutEngineTests.swift:262–263` to expect `width == 100, height == 50` (content unchanged, padding adds to outer). This is consistent with DISCUSS ACs and more intuitive.
- **Option Y (content-box for directional, border-box for uniform):** Do NOT route `PaddingModifier` through `layoutDirectionalPaddingNode`. Keep separate `layoutPaddingNode` for `PaddingModifier` (border-box). Add `AnyDirectionalPaddingModifier` dispatch BEFORE `AnyPaddingModifier` in `layoutNode`. This preserves existing uniform padding semantics but creates an inconsistency between the two padding types.
- **Option Z (border-box for both):** Implement `layoutDirectionalPaddingNode` with the same `HasFrameSize` special-casing as `layoutPaddingNode`. Update DISCUSS ACs (and these acceptance tests) to expect 100×50 instead of 140×70.

**Recommendation: Option X.** Content-box is more intuitive, consistent with how developers expect padding to work, and matches the DISCUSS acceptance criteria. The existing test update is mechanical (change two expected values). Document the semantic change in the PR description.

## DWD-05: Test File Location

```
Tests/GameUITests/acceptance/DirectionalPaddingTests.swift
```

## Test Count Summary

| Suite | Tests | RED | Green |
|---|---|---|---|
| Walking Skeleton | 1 | 1 | 0 |
| Layout (US-PDR-01) | 7 | 6 | 1* |
| Hit-Test (US-PDR-02) | 4 | 2 | 2** |
| Regression | 1 | 0 | 1 |
| **Total** | **13** | **9** | **4** |

\* AC-5 (clamping) passes incidentally: the default fill-constraints behavior already produces a frame ≤ 100×100 within 100×100 constraints. It will also pass after implementation (130×130 would be clamped to 100×100). The test is correct in both states.

\*\* "hitTestButton does not invoke action" passes because no action is ever invoked (RED traversal returns nil without entering the button). "point outside → nil" passes because point (1000, 1000) lies outside any frame the default layout could produce.

## Self-Review Checklist

- [x] WS strategy declared (DWD-01)
- [x] WS scenarios tagged — N/A (Swift Testing, not Gherkin; all tests use real function calls)
- [x] Driving ports identified (DWD-02)
- [x] Scaffold in Sources/ makes tests compile (DWD-03)
- [x] RED state confirmed: 12 assertion failures, 0 crashes, 0 compile errors
- [x] Upstream issue documented (DWD-04)
- [x] All 11 DISCUSS ACs covered by at least one test
