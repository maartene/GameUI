# DISCUSS Decisions — hit-test-button

## Key Decisions

- [D1] Feature type = Backend library API extension: `hitTestButton` is a pure
  query function added to the GameUI public API. There is no end-user UI.
  The "user" is Riku (game screen developer). Pre-answered, not re-derived.

- [D2] Walking skeleton = No: `LayoutEngine`, `AnyButton`, `LayoutNode`, and
  `Button` all exist. The traversal is a new function, but it connects already-
  working pieces. No new plumbing is required.

- [D3] UX research depth = Lightweight: The feature is a single pure function
  with a precisely defined signature and a clear problem statement. Full
  emotional journey mapping adds no signal.

- [D4] JTBD = Skipped: The developer motivation is explicit — eliminate four-
  piece boilerplate. No competing jobs identified.

- [D5] Single story, single slice: The entire feature is one atomic function.
  Splitting by "traversal" vs. "containment check" would produce stories with
  no independent value. Elephant Carpaccio confirms single slice is correct.

- [D6] No standalone `.feature` file: Gherkin scenarios are embedded per story
  in `user-stories.md` and in `journey-button-hover.yaml`, per methodology.

- [D7] DIVERGE artifacts absent: No `recommendation.md` or `job-analysis.md`
  exist for this feature. Noted as expected — this is a library API addition
  discovered through usage pain, not a DISCOVER/DIVERGE pipeline feature.
  Risk: LOW — problem statement is concrete and well-scoped.

## Requirements Summary

- Primary user need: Riku needs one GameUI function to replace four pieces of
  per-screen mouse hover boilerplate. The function returns the traversal-order
  index of the hovered button, or nil.
- API: `public func hitTestButton(view: any View, node: LayoutNode, at point: Point) -> Int?`
- Walking skeleton scope: N/A — brownfield API extension.
- Feature type: Backend library API.

## Constraints Established

- Pure function — no side effects, no action firing during traversal
- Traversal order: depth-first, view-tree construction order (invariant for callers)
- Inclusive boundary: point on frame edge counts as contained
- No Foundation import; no third-party dependencies
- Swift 6.2 strict concurrency — function must be non-isolated
- `Rect.contains(_ point: Point) -> Bool` is a prerequisite — add if missing

## Open Design Questions

- **ODQ-01**: Does `Rect` already have a `contains(_:)` method?
  - If yes: use it directly. If no: add it before or as part of this story.
  - Owner: Crafter (DESIGN wave)
  - Risk: LOW — trivial to add, well-understood semantics

- **ODQ-02**: Should the function be a free function or a method on `LayoutEngine`?
  - Current spec: free function (matches the brief exactly, consistent with
    SwiftUI's `hitTest` being a method on `View` not on a separate engine).
  - Pre-answered as free function. Crafter may revisit.

## Upstream Changes

- `button-focus-state` feature (merged): `AnyButton` now exposes `isFocused: Bool`.
  `hitTestButton` traversal uses `AnyButton` protocol cast — consistent with
  existing `LayoutEngine` pattern (`if let button = view as? AnyButton`).

## Risk Register

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| `view`/`node` from different layout passes | MEDIUM | MEDIUM | Document invariant in API comment; AC covers it |
| Traversal order diverges from screen's button array | LOW | HIGH | Specify depth-first construction order in AC and test with non-trivial nesting |
| `Rect.contains` missing | LOW | LOW | Pre-task to verify and add if needed |
| Strict concurrency issue with `any View` existential | LOW | MEDIUM | Pure function, no captures; Crafter validates in DESIGN |
