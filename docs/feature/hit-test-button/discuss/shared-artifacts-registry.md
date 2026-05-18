# Shared Artifacts Registry — hit-test-button

| Artifact | Type | Source of Truth | Consumers | Risk |
|---|---|---|---|---|
| `mousePosition: Point` | Value | Platform layer (Raylib / SpaceSim) | `hitTestButton(at:)` argument | LOW — caller-provided, no internal state |
| `layout.root: LayoutNode` | Value | `LayoutEngine.layout(_:in:)` result | `hitTestButton(node:)` argument | MEDIUM — must come from same layout pass as `view` |
| `fullMenuView: any View` | Protocol existential | Screen's declarative view expression | `hitTestButton(view:)` argument | MEDIUM — must correspond to the same layout pass as `node` |
| `focusedIndex: Int?` | Screen state | SpaceSim screen | `Button(isFocused: focusedIndex == i)` | LOW — caller owns and controls this value |
| `AnyButton` protocol | Protocol | `LeafViews.swift` | `hitTestButton` traversal, renderer | LOW — stable, `isFocused` already on protocol |
| Traversal order | Invariant | Depth-first, view-tree construction order | `hitTestButton` result, screen button array | HIGH — if inconsistent, wrong button is highlighted |

## Integration Risks

### MEDIUM — view/node alignment

`hitTestButton` receives both a `view` (for type inspection) and a `node`
(for frame data). They must come from the same layout pass. If a screen
re-layouts the view without updating the node reference (or vice versa),
the returned index points to the wrong button.

Mitigation: document the invariant in the API signature comment and in US-01
acceptance criteria.

### HIGH — traversal order invariant

The traversal order of `hitTestButton` must match the order in which the
screen indexes its button array. If the function visits buttons in a different
order than the screen's `buttons[i]` array is constructed, hover will
highlight the wrong button.

Mitigation: specify traversal order explicitly in AC (depth-first,
construction order). Test with a multi-button layout that has a non-trivial
structure (nested VStack).
