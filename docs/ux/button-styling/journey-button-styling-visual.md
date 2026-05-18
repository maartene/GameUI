# Journey: Button Styling — Visual Narrative

## Persona
Riku Nakamura — game developer building SpaceSim menus.
Riku has already used `Button(isFocused:)` to handle keyboard/gamepad navigation (prior feature).
Now Riku needs the main menu to show "Start Game" in a vibrant primary style, "Settings" in a muted
secondary style, and "Quit" in a warning-red destructive style.

## Emotional Arc

```
[Start]        [Step 1]        [Step 2]          [Step 3]         [End]
Curious        Confident       Trusting           Satisfied        Delighted
               "One extra      "Layout just       "Switch in
               argument —      works, nothing     renderer covers
               same pattern    changed"           all three roles"
               as isFocused"
```

**Arc pattern**: Discovery Joy — Curious → Confident → Trusting → Satisfied/Delighted.
Riku already knows the `Button` API. Adding a tag feels like discovering a familiar pattern
extended, not learning something new.

---

## ASCII Flow Diagram

```
+-----------------------------------------------------------------+
|  TRIGGER: Riku sees the main menu renders all buttons           |
|  identically. Players confuse "Start Game" with "Settings".     |
+-----------------------------------------------------------------+
         |
         v
+----------------------------------+
| STEP 1: Declare buttons with tag |
|                                  |
| Button(tag: "primary") { ... }   |
| Button(tag: "secondary") { ... } |
| Button(tag: "destructive") { ... }|
|                                  |
| Emotional state: CONFIDENT       |
| "Same init pattern, one arg"     |
+----------------------------------+
         |
         | [tag stored as AnyButton.tag]
         v
+----------------------------------+
| STEP 2: Layout pass runs         |
|                                  |
| LayoutEngine.layout(view, ...)   |
| Tag is invisible to layout —     |
| same geometry as before.         |
|                                  |
| Emotional state: TRUSTING        |
| "Nothing changed in layout"      |
+----------------------------------+
         |
         | [LayoutTree produced, tag travels with view]
         v
+----------------------------------+
| STEP 3: Renderer inspects tag    |
|                                  |
| if let btn = view as? AnyButton  |
| switch btn.tag {                 |
|   case "primary":    draw(blue)  |
|   case "secondary":  draw(gray)  |
|   case "destructive":draw(red)   |
|   default:           draw(white) |
| }                                |
|                                  |
| Emotional state: SATISFIED       |
| "One switch, zero per-screen     |
|  duplication"                    |
+----------------------------------+
         |
         v
+----------------------------------+
|  OUTCOME: All three button types |
|  render with distinct visual     |
|  styles. Players navigate with   |
|  confidence. Riku changes the    |
|  primary color globally in one   |
|  renderer edit.                  |
+----------------------------------+
```

---

## Step-by-Step Narrative

### Step 1 — Declare Buttons with Semantic Tag (Riku's code)

**What Riku types:**

```swift
// SpaceSim MainMenuView.swift
var body: some View {
    VStack {
        Button(tag: "primary", isFocused: focusedIndex == 0) {
            Text("Start Game")
        } action: { startGame() }

        Button(tag: "secondary", isFocused: focusedIndex == 1) {
            Text("Settings")
        } action: { openSettings() }

        Button(tag: "destructive", isFocused: focusedIndex == 2) {
            Text("Quit")
        } action: { quit() }
    }
}
```

**What Riku sees:** No compiler errors. The `tag` parameter accepts any `String`. The API is
additive — existing `Button()` call sites without `tag` continue to compile with a default
empty string.

**Emotional state:** Confident. The `tag` parameter is in the same position as `isFocused`.
Riku already knows this constructor shape.

**Integration checkpoint:** `tag` is stored as a `let` property on `Button<Content>` and exposed
via `AnyButton.tag`. The layout engine does not read `tag`. It passes through untouched.

---

### Step 2 — Layout Pass (Unchanged)

**What happens:**

```
LayoutEngine.layout(mainMenuView, in: constraints)
  → walks VStack → Button(primary) → Button(secondary) → Button(destructive)
  → produces LayoutTree with same frame geometry as before
  → tag is passenger metadata, not measured, not compared
```

**What Riku observes:** The menu layout is pixel-identical to before tagging. No regressions.

**Emotional state:** Trusting. The layout engine is not broken by the new metadata. Geometry
is deterministic and unchanged.

**Failure mode:** If `tag` were accidentally consumed by the layout engine (e.g. comparing tags
to choose layout strategy), layout regressions would appear. Mitigation: `tag` is declared
on `AnyButton`, not on any container or layout-relevant protocol.

---

### Step 3 — Renderer Inspects Tag and Draws Styled Button

**What the renderer does:**

```swift
// SpaceSimRenderer.swift  (Riku's renderer, not part of GameUI)
func renderNode(_ node: LayoutNode, view: any View) {
    if let btn = view as? AnyButton {
        let color: Color
        switch btn.tag {
        case "primary":     color = Color(r: 0.27, g: 0.53, b: 1.0)   // accent blue
        case "secondary":   color = Color(r: 0.50, g: 0.50, b: 0.50)  // muted gray
        case "destructive": color = Color(r: 0.85, g: 0.20, b: 0.20)  // warning red
        default:            color = Color(r: 1.0,  g: 1.0,  b: 1.0)   // white fallback
        }
        drawRect(node.frame, color: color)
        renderNode(node, view: btn.anyContent)
        return
    }
    // ... other view types ...
}
```

**What Riku sees:** Three visually distinct buttons. "Start Game" is blue/prominent.
"Settings" is gray/secondary. "Quit" is red/warning.

**Emotional state:** Satisfied, then Delighted when Riku notices that changing the primary
button color requires editing exactly one line in the renderer — not touching any call site.

---

## Error Path: Missing Tag (Empty String Default)

When `Button()` is constructed without a tag, `tag` defaults to `""`.

```
Button(isFocused: focusedIndex == 0) { Text("Legacy Button") } action: { ... }
// → tag == ""
```

The renderer's `default:` case handles this. The button renders with the fallback/unstyled
appearance. No crash. No warning. Existing call sites are unaffected.

**Emotional state:** Relieved. Brownfield code does not require mass migration.

---

## TUI Mockup — Renderer Output (Conceptual)

```
+------------------------------------------+
|  SPACE SIM — MAIN MENU                   |
+------------------------------------------+
|                                          |
|  [ ██████ START GAME ██████ ]  <primary> |
|  (accent blue, prominent)                |
|                                          |
|  [     Settings      ]         <secondary|
|  (muted gray)                            |
|                                          |
|  [       Quit        ]         <destructi|
|  (warning red)                           |
|                                          |
+------------------------------------------+
```

Variable `${buttonTag}` sourced from `AnyButton.tag` (see shared-artifacts-registry.md).
