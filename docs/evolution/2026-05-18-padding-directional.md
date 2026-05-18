# Evolution: padding-directional

**Date:** 2026-05-18
**Feature ID:** padding-directional
**Status:** Delivered

---

## Feature Summary

`padding(x:y:)` directional padding modifier with content-box layout semantics and hit-test traversal.

Adds a `DirectionalPaddingModifier<Content>` struct and `View.padding(x:y:)` extension allowing game developers to apply independent horizontal and vertical padding to any view. The outer frame grows by `2*x` in width and `2*y` in height (content-box semantics). Hit-test traversal extends the tappable area to the full padded frame while delegating to the child view's hit-test logic.

---

## Business Context

Game developers requested independent horizontal/vertical padding control. The existing `padding(_ amount:)` modifier applies a single uniform inset on all sides, which is sufficient for symmetric spacing but inadequate for layouts requiring distinct horizontal and vertical breathing room (e.g., wide button labels, asymmetric card borders). This feature closes that gap with a first-class API rather than a workaround of nested padding modifiers.

---

## Key Decisions

| Decision | Option Chosen | Rationale |
|---|---|---|
| Protocol topology | Option B — unify at protocol level | `AnyDirectionalPaddingModifier` subsumes `AnyPaddingModifier`. Uniform padding is a degenerate case (paddingX == paddingY). Halves dispatch complexity in `layoutNode` and `hitTestNode`. Permanently closes dispatch-order fragility (DISCUSS D6). |
| Box-sizing semantics | Option X — content-box for both new and existing | Outer frame = content frame + 2*paddingX width + 2*paddingY height. `PaddingModifier` routed through the same `layoutDirectionalPaddingNode`. More intuitive, matches DISCUSS acceptance criteria, and unifies both padding types under a single semantic. 2 existing test expectations updated. |
| `AnyPaddingModifier` | Deprecated (not removed) | `@available(*, deprecated, renamed: "AnyDirectionalPaddingModifier")` gives external callers a compiler-warning migration window. No hard break at this release. |
| `PaddingModifier` concrete type | NOT deprecated | `padding(_ amount:)` continues to return `PaddingModifier<Self>`. Deprecating it now would warn on every `.padding(8)` call. Path to full consolidation is a future PR. |
| Hit-test behaviour | Tappable area extends to full padded frame | `hitTestNode` routes through `AnyDirectionalPaddingModifier` branch, traverses to child. Point is translated to child-local coordinates; hit-test result comes from the child's own logic. |

---

## Steps Completed

| Step ID | Name | Result |
|---|---|---|
| 01-01 | Implement directional padding layout and hit-test dispatch | PASS |

All 5 DES phases executed and passed: PREPARE, RED\_ACCEPTANCE, RED\_UNIT, GREEN, COMMIT.

---

## Issues Encountered

### DWD-04: Box-Sizing Semantic Gap

**Description:** A contradiction was discovered during DISTILL between the DISCUSS acceptance criteria and the existing `layoutPaddingNode` behaviour.

| Source | Behaviour | Example |
|---|---|---|
| DISCUSS AC-1 (intent) | Content-box: outer frame = content + 2*padding | `Rectangle().frame(100,50).padding(x:20,y:10)` → outer 140×70 |
| Existing `layoutPaddingNode` | Border-box: outer frame = content's declared size | `Rectangle().frame(100,50).padding(5)` → outer 100×50 (child squeezed to 90×40) |

**Root cause:** `outerSizeForPaddedContent` returned the content's declared frame size as the outer size when content conformed to `HasFrameSize`, silently squeezing the child rather than expanding the outer frame.

**Resolution:** Option X selected — content-box semantics implemented for both `DirectionalPaddingModifier` and `PaddingModifier` (routed through the unified `layoutDirectionalPaddingNode`). Two existing test expectations in `LayoutEngineTests.swift` updated to reflect the corrected semantic (`width == 100, height == 50` instead of `width == 90, height == 40`).

**Impact:** 2 existing test expectations changed (mechanical update). All 120 tests pass after the fix.

---

## Lessons Learned

When a new modifier type is a strict generalisation of an existing one, unifying at the protocol level (Option B) halves dispatch complexity and eliminates ordering fragility. The alternative — maintaining two parallel protocol branches with explicit ordering rules — trades short-term safety for compounding maintenance cost. In a pure value-type immutable system, the Liskov risk of the unification is zero: `PaddingModifier` satisfies every contract of `AnyDirectionalPaddingModifier` without exception.

Semantic gaps between wave assumptions (DISCUSS) and existing implementation behaviour (border-box in `layoutPaddingNode`) should be surfaced as upstream issues in DISTILL before RED. Discovering them after GREEN would require reverting GREEN work; discovering them in DISTILL allows the crafter to choose the correct semantic before writing a single line of production code.

---

## Test Summary

| Category | Count |
|---|---|
| New acceptance tests (DirectionalPaddingTests.swift) | 13 |
| Total passing tests after delivery | 120 |
| Tests updated (semantic correction) | 2 |
| Tests broken by delivery | 0 |

---

## Artifacts

- `Sources/GameUI/View.swift` — `AnyDirectionalPaddingModifier` protocol, `DirectionalPaddingModifier<Content>` struct, `View.padding(x:y:)` extension, `PaddingModifier` conformance, `AnyPaddingModifier` deprecation
- `Sources/GameUI/LayoutEngine.swift` — `layoutDirectionalPaddingNode`, `outerSizeForDirectionalPaddedContent`, retired `layoutPaddingNode` and `outerSizeForPaddedContent`
- `Sources/GameUI/HitTest.swift` — `AnyDirectionalPaddingModifier` dispatch branch replacing `AnyPaddingModifier` branch
- `Tests/GameUITests/acceptance/DirectionalPaddingTests.swift` — 13 acceptance tests
- `docs/architecture/padding-directional/wave-decisions.md` — DESIGN decisions
- `docs/architecture/padding-directional/slice-01-core-directional-padding.md` — implementation slice definition
