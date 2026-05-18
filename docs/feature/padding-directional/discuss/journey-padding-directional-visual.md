# Journey: Directional Padding — Visual Narrative

## Persona
**Alex Reyes** — game developer building a HUD system in Swift using GameUI.
Alex is assembling a dialogue box: wide left/right margins to keep text readable, but tight top/bottom margins to conserve vertical screen space.

---

## Emotional Arc

```
CURIOUS ──────► FOCUSED ──────► CONFIDENT
   |                |                |
Discovers       Applies          Sees correct
padding(x:y:)   modifier         layout tree
```

---

## Step 1 — Discover the Need

Alex tries `.padding(20)` for a dialogue box. The result is correct left/right but the top/bottom gap is too tall, pushing content off screen. Alex looks at the API:

```
// Current API — uniform padding only
view.padding(20)   // 20 on all four sides

// What Alex needs
view.padding(x: 20, y: 10)  // 20 left/right, 10 top/bottom
```

**Emotion:** Curious, slightly frustrated. Wonders if nesting two `.padding` calls is the answer.
Nesting works but feels wrong — two wrapper nodes, double allocations, non-obvious intent.

---

## Step 2 — Apply the Modifier

Alex calls `.padding(x: 20, y: 10)` on the dialogue background view and passes the result to `LayoutEngine.layout(...)`.

```swift
let dialogue = Rectangle()
    .padding(x: 20, y: 10)

let tree = engine.layout(dialogue, in: LayoutConstraints(maxWidth: 400, maxHeight: 300))
```

**Emotion:** Focused. Expects the same declare-and-layout pattern as every other modifier.

---

## Step 3 — Inspect the Layout Tree

Alex checks `tree.root.frame.size`:

```
Expected outer size:
  width  = content.width  + 2 * 20  (x-padding)
  height = content.height + 2 * 10  (y-padding)

Child origin:
  x = outer.origin.x + 20
  y = outer.origin.y + 10
```

The LayoutNode structure mirrors the existing `PaddingModifier` pattern — one parent node wrapping one child node.

**Emotion:** Focused → Verifying. Looks at child frame to confirm origin is inset correctly.

---

## Step 4 — Hit-Test a Button Inside Directional Padding

Alex wraps an action button in `.padding(x: 10, y: 5)` and wires up pointer input:

```swift
let btn = Button("Attack") { ... }
    .padding(x: 10, y: 5)
let tree = engine.layout(btn, in: ...)
let index = hitTestButton(view: btn, node: tree.root, at: tapPoint)
```

`hitTestButton` descends through the `AnyDirectionalPaddingModifier` wrapper and returns the button index. No special handling needed in the game's input layer.

**Emotion:** Confident. The modifier fits seamlessly into the existing input pipeline.

---

## Integration Points

| Step | Output Artifact | Consumed By |
|------|----------------|-------------|
| 1 | `DirectionalPaddingModifier<Content>` value | LayoutEngine |
| 2 | `LayoutNode` with correct outer frame | Renderer, HitTest |
| 3 | Child `LayoutNode` with inset origin | Renderer |
| 4 | Button index from `hitTestButton` | Game input handler |

---

## Error / Edge Paths

- **Zero padding on one axis** (`.padding(x: 0, y: 10)`): width unchanged, height grows by 20. Not an error.
- **Negative values**: treated as 0 via `max(0, ...)` guards — consistent with `layoutPaddingNode`.
- **Constraints too tight**: outer size clamped to `constraints.maxWidth / maxHeight` — same as uniform padding.
