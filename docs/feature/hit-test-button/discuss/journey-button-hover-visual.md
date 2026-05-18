# Journey: Button Hover — Visual Map (feature copy)

> SSOT lives at `docs/product/journeys/button-hover-visual.md`.
> This copy is the feature-scoped artifact for DISCUSS wave handoff.

## Persona

Riku Nakamura — game developer building SpaceSim menus, adding mouse hover
on top of an existing button layout. Every screen he writes reimplements the
same four-piece boilerplate. He wants GameUI to absorb that complexity.

## Emotional Arc

```
FRUSTRATED          RELIEVED            SATISFIED
     |                   |                   |
[Mouse pos] ----> [hitTestButton] ----> [Apply index]
"Every screen       "One call.          "New screens
 needs the           Returns Int?.       get hover
 same 4 pieces."     Done."              for free."
```

## Journey Flow (Library-Consumer View)

```
+--[Platform Layer]-----------------------------------------------+
|  mousePosition: Point  (Float x, Float y, layout coord space)  |
+----------------------------------------------------------------+
                              |
                              v
+--[Step 1: Poll mouse position]----------------------------------+
|  let mouse = platform.mousePosition()                          |
|  Emotional state: Neutral — routine input polling              |
+----------------------------------------------------------------+
                              |
                              v
+--[Step 2: Query GameUI — the new API surface]------------------+
|                                                                |
|  let index = hitTestButton(                                    |
|      view: fullMenuView,    <-- declarative view expression    |
|      node: layout.root,     <-- LayoutTree from same pass      |
|      at:   mouse            <-- Point from platform layer      |
|  )                                                             |
|                                                                |
|  Returns: Int? (traversal-order index) or nil                  |
|                                                                |
|  Replaces all four boilerplate pieces:                         |
|    - hoverConstraints: LayoutConstraints property              |
|    - buttonRects: [Rect] computed property                     |
|    - private collectButtonFrames traversal                     |
|    - applyHoverFocus wiring method                             |
|                                                                |
|  Emotional state: Relieved                                     |
+----------------------------------------------------------------+
                              |
              +---------------+---------------+
              |                               |
         [index != nil]                  [index == nil]
              |                               |
              v                               v
+--[Step 3a: Apply focus]-------+  +--[Step 3b: Clear focus]-------+
|  focusedIndex = index          |  |  focusedIndex = nil           |
|  Button(isFocused: i == idx)   |  |  all isFocused: false         |
|  Renderer: highlight           |  |  Renderer: no highlight       |
+--------------------------------+  +-------------------------------+
              |                               |
              +---------------+---------------+
                              |
                              v
+--[Screen redraws]----------------------------------------------+
|  Hovered button: isFocused == true                             |
|  All others:     isFocused == false                            |
|  Emotional state: Satisfied                                    |
+----------------------------------------------------------------+
```

## Error Paths

```
[view/node from different layout passes]
  -> frames don't align with view tree
  -> wrong index or spurious nil
  Recovery: always use view + node from the same layout pass in the same frame

[Cursor outside all buttons]
  -> hitTestButton returns nil  (correct behavior, not an error)
  -> screen must clear focusedIndex — stale highlight from prior frame is a bug

[Nested button with wrong origin]
  -> frame check fails even when cursor is visually over button
  Recovery: LayoutEngine already propagates origins correctly (existing behavior)
```

## Shared Artifacts

| Artifact | Source | Consumers |
|---|---|---|
| `mousePosition: Point` | Platform layer | `hitTestButton(at:)` |
| `layout.root: LayoutNode` | `LayoutEngine.layout(_:in:)` | `hitTestButton(node:)` |
| `fullMenuView: any View` | Screen's view expression | `hitTestButton(view:)` |
| `focusedIndex: Int?` | Screen state | `Button(isFocused: focusedIndex == i)` |

## Integration Checkpoint

Traversal order of `hitTestButton` (depth-first, view-tree construction order)
must match the button order the screen uses to index its button array.
This is the single critical invariant for correct hover highlighting.
