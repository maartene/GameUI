# Journey: Button Hover — Visual Map

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

## Journey Flow

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
+--[Step 2: Query GameUI]----------------------------------------+
|                                                                |
|  let index = hitTestButton(                                    |
|      view: fullMenuView,    <-- declarative view expression    |
|      node: layout.root,     <-- LayoutTree from layout pass   |
|      at:   mouse            <-- Point from platform layer      |
|  )                                                             |
|                                                                |
|  Returns: Int? (traversal-order index) or nil                  |
|                                                                |
|  Replaces:                                                     |
|    - hoverConstraints property                                 |
|    - buttonRects computed property                             |
|    - collectButtonFrames traversal helper                      |
|    - applyHoverFocus wiring method                             |
|                                                                |
|  Emotional state: Relieved — four pieces become one call       |
+----------------------------------------------------------------+
                              |
              +---------------+---------------+
              |                               |
         [index != nil]                  [index == nil]
              |                               |
              v                               v
+--[Step 3a: Apply focus]-------+  +--[Step 3b: Clear focus]-------+
|  focusedIndex = index          |  |  focusedIndex = nil           |
|  Next frame: Button(           |  |  Next frame: all buttons      |
|    isFocused: i == focusedIndex|  |    isFocused: false           |
|  )                             |  |                               |
|  Renderer: highlight active    |  |  Renderer: no highlight       |
+--------------------------------+  +-------------------------------+
              |                               |
              +---------------+---------------+
                              |
                              v
+--[Screen redraws]----------------------------------------------+
|  Hovered button rendered with isFocused == true               |
|  All others: isFocused == false                                |
|  Emotional state: Satisfied                                    |
+----------------------------------------------------------------+
```

## Error Paths

```
[hitTestButton called with mismatched view/node]
  -> frames don't align with view tree
  -> returned index points to wrong button or is nil unexpectedly
  Recovery: always use view + node from the same layout pass

[Cursor outside all buttons]
  -> hitTestButton returns nil (correct behavior)
  -> screen must reset focusedIndex — do not leave stale value from prior frame

[Nested button inside container with wrong origin]
  -> frame check fails even when cursor is visually over button
  Recovery: ensure LayoutEngine propagates origin correctly through containers
  (existing behavior — not a new risk)
```

## Shared Artifacts

| Artifact | Source | Consumers |
|---|---|---|
| `mousePosition: Point` | Platform layer (Raylib) | `hitTestButton(at:)` |
| `layout.root: LayoutNode` | `LayoutEngine.layout(_:in:)` | `hitTestButton(node:)` |
| `fullMenuView` | Screen's view expression | `hitTestButton(view:)` |
| `focusedIndex: Int?` | Screen state | `Button(isFocused:)` on next frame |

## Integration Checkpoint

The traversal order of `hitTestButton` must match the button order the screen
uses to index into its own button array. If traversal order is depth-first
left-to-right (matching the view tree construction order), the returned index
is directly usable as `menuButtons[index]`.
