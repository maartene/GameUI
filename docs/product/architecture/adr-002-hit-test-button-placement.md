# ADR-002: hitTestButton Function Placement and Rect.contains Boundary Semantics

## Status

Accepted

---

## Context

The `hit-test-button` feature adds a public query function to the GameUI module:

```swift
public func hitTestButton(view: any View, node: LayoutNode, at point: Point) -> Int?
```

Two architectural decisions are required before implementation:

1. **Where does the function live?** The codebase already has `LayoutEngine.swift` (layout pass), `LeafViews.swift` (leaf view types), `Containers.swift` (container types), and `LayoutTypes.swift` (geometry). The function is neither layout computation nor a view type. Three candidate placements were identified.

2. **How is point containment handled?** `Rect.contains(_ point: Point) -> Bool` already exists in `LayoutTypes.swift`. Its current implementation uses a strict less-than (`<`) on both axes, producing an exclusive upper boundary. The feature AC explicitly requires inclusive boundary (point on edge = inside). Two resolution strategies were identified.

**Constraints in force:**
- Swift 6.2 strict concurrency — function must be non-isolated
- No Foundation import; no third-party dependencies
- No new protocols, no new types beyond what is strictly necessary
- ODQ-02 pre-answered: free function (not a method on `LayoutEngine`)
- Development paradigm: protocol-oriented value types, structs

---

## Decision

### Decision 1 — Function placement: new file `HitTest.swift`

`hitTestButton` and its private recursive helper `hitTestNode` live in `Sources/GameUI/HitTest.swift`.

**Rationale:**

`LayoutEngine.swift` is responsible for the layout computation pass (translating a view tree into a frame tree). Hit-testing is a separate responsibility: a read-only query over the results of layout. Placing the function in `LayoutEngine.swift` would mix two distinct responsibilities in one file, creating a precedent that accumulates all layout-adjacent operations there (future: `buttonFrames(view:node:)`, `nodeAtPoint(node:point:)`, etc.).

The codebase already uses feature-named files per responsibility: `WrappedText.swift`, `Color.swift`, `ViewBuilder.swift`. A file named `HitTest.swift` is immediately discoverable and unambiguous.

### Decision 2 — Rect.contains: fix existing method to `<=` (inclusive)

The existing `Rect.contains` method in `LayoutTypes.swift` is modified to use `<=` on both the x and y upper bounds. No new method is added.

**Rationale:**

The method already has the correct signature and intent. Its current exclusive-boundary behavior is a semantic misalignment with the standard geometric convention (a rect's boundary is part of the rect). Correcting the implementation is preferable to adding a second method with a nearly identical signature, which would create ambiguity for future callers. Existing callers in `LayoutEngine` are not affected: layout code constructs frames but does not test point containment.

---

## Alternatives Considered

### Placement Option B — Append to `LayoutEngine.swift`

**Evaluation:** `LayoutEngine.swift` is a layout-computation file (270 lines at time of writing). A hit-test function appended to the same file would co-locate two responsibilities that should be independently evolvable. The filename does not signal hit-testing, reducing discoverability. If future layout-query functions are added, the file grows without a principled stopping criterion. Rejected on maintainability grounds.

**Quality attribute impact:** Reduces Maintainability. Co-location by file proximity rather than by responsibility is inconsistent with the codebase's file-per-responsibility convention.

### Placement Option C — Extension file `LayoutEngine+HitTest.swift`

**Evaluation:** In Swift conventions, `TypeName+Protocol.swift` or `TypeName+Feature.swift` denotes an extension on `TypeName`. `hitTestButton` is a module-level free function, not a method on `LayoutEngine`. Naming the file `LayoutEngine+HitTest.swift` would mislead future maintainers into expecting `LayoutEngine.hitTestButton(...)` as a method call. The naming convention would spread incorrectly to future additions. Rejected because the naming is actively misleading.

**Quality attribute impact:** Reduces Maintainability. Violates Swift naming convention semantics for extension files.

### Rect.contains — Add a second method `containsInclusive(_ point: Point) -> Bool`

**Evaluation:** A second method with an almost-identical name would create decision overhead for every future caller: which method do I use? Geometric convention universally treats a rect's boundary as part of the rect (inclusive). The current exclusive-boundary implementation is the anomaly, not the inclusive one. A second method would codify the anomaly as permanent. Rejected in favour of correcting the existing method.

**Quality attribute impact:** Adding a second method increases API surface and reduces Maintainability. The existing exclusive-boundary method has zero callers that depend on the exclusive semantics (verified by grep: `Rect.contains` is not called anywhere in the current source).

---

## Consequences

### Positive

- `HitTest.swift` is a dedicated, single-responsibility file. Future hit-test variants or query functions belong there without ambiguity.
- `Rect.contains` now has correct inclusive-boundary semantics by default. All future callers benefit without needing to know about the historical anomaly.
- No changes to `LayoutEngine`, `LayoutNode`, `LayoutTree`, or any protocol. The public API surface of the library grows by exactly one free function.
- The traversal pattern in `hitTestNode` mirrors `layoutNode`'s protocol-cast chain, so any developer familiar with `LayoutEngine` can read and modify the traversal without new concepts.

### Negative / Accepted Trade-offs

- One new file in `Sources/GameUI/`. File count grows from 8 to 9.
- `Rect.contains` semantics change from exclusive to inclusive upper bound. This is a breaking change in theory. In practice, `Rect.contains` has zero callers in the existing source tree (confirmed by inspection); the change is safe. The AC test suite will enforce the new semantics going forward.
- The `hitTestNode` recursive helper is private, which means it is not separately testable. Its correctness is validated entirely through `hitTestButton` acceptance tests. This is intentional: the helper is an implementation detail and testing it directly would couple tests to implementation structure.

---

## References

- `Sources/GameUI/LayoutTypes.swift` — `Rect.contains` (line 39–42): current exclusive implementation
- `Sources/GameUI/LayoutEngine.swift` — `layoutNode` private method: traversal pattern reference
- `Sources/GameUI/LeafViews.swift` — `AnyButton` protocol
- `Sources/GameUI/Containers.swift` — `ContainerView`, `ZStackView` protocols
- `Sources/GameUI/View.swift` — `HasFrameSize`, `AnyPaddingModifier` protocols
- `docs/feature/hit-test-button/discuss/wave-decisions.md` — ODQ-01, ODQ-02, constraints
- `docs/feature/hit-test-button/discuss/user-stories.md` — AC list, boundary condition AC-06
