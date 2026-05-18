# Journey: Directional Padding — Human-Readable Narrative

**Persona**: Alex Reyes — game developer building HUD panels in Swift using GameUI
**Goal**: Apply different horizontal and vertical padding to any view in a single API call

---

## Emotional Arc

```
CURIOUS ────────► FOCUSED ────────► CONFIDENT
     |                  |                |
 Discovers          Applies          Sees correct
 .padding(x:y:)     modifier         layout tree +
                                      hit-test works
```

---

## Step 1 — Discover the Need

Alex is assembling a dialogue box: wide left/right margins to keep text readable, tight top/bottom margins to conserve screen height. `.padding(20)` applies 20pt on all four sides — too tall. Nesting `.padding()` calls does not help (they compound uniformly).

Alex looks for `.padding(x:y:)` in the `View` API and finds it. A single call expresses intent precisely.

**Entry**: Curious
**Exit**: Motivated

---

## Step 2 — Apply the Modifier and Lay Out

```swift
let dialogue = Rectangle()
    .padding(x: 20, y: 10)

let tree = engine.layout(dialogue, in: LayoutConstraints(maxWidth: 400, maxHeight: 300))
```

The `LayoutEngine` detects `AnyDirectionalPaddingModifier`, calls `layoutDirectionalPaddingNode`, and produces a root node with:
- `frame.size.width = content.width + 40`
- `frame.size.height = content.height + 20`
- `children[0].frame.origin = (20, 10)`

**Entry**: Focused
**Exit**: Verifying

---

## Step 3 — Verify Frame and Origin

Alex checks `tree.root.frame.size` and `tree.root.children[0].frame.origin`. Both match expectations. The outer size is clamped correctly when constraints are tight.

**Entry**: Verifying
**Exit**: Satisfied

---

## Step 4 — Hit-Test a Padded Button

Alex wraps an "Attack" button in `.padding(x: 10, y: 5)` and calls:

```swift
let index = hitTestButton(view: root, node: tree.root, at: tapPoint)
```

`hitTestButton` descends through the `AnyDirectionalPaddingModifier` wrapper without special casing in the game's input layer. The button index is returned correctly.

**Entry**: Focused
**Exit**: Confident

---

## Integration Points

| From | To | Artifact |
|------|----|----------|
| `View.padding(x:y:)` | `LayoutEngine.layoutDirectionalPaddingNode` | `DirectionalPaddingModifier<Content>` value |
| `layoutDirectionalPaddingNode` | Renderer | `LayoutNode` with outer frame |
| `layoutDirectionalPaddingNode` | `hitTestButton` | Child `LayoutNode` with inset origin |
| `hitTestNode` (AnyDirectionalPaddingModifier branch) | Game input handler | Button index |
