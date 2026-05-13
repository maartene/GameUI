# Journey: Button Focus State

**Persona**: Riku Nakamura — game developer integrating GameUI into SpaceSim, now adding gamepad/keyboard navigation.

**Goal**: Mark a specific Button as focused so the renderer can display a distinct visual state for keyboard/gamepad players.

---

## Journey Narrative

### Step 1 — Declare Button with Focus Flag

Riku has a menu with three buttons. The player presses D-pad Up/Down in SpaceSim, which updates a `focusIndex` variable. Riku passes `isFocused: focusIndex == i` when constructing each `Button`.

```swift
Button(isFocused: focusIndex == i) {
    Text(content: label, fontSize: 20)
} action: { handleSelection(i) }
```

**Emotional state**: Confident — the pattern mirrors existing Button construction, just one new parameter.

**Expected output**: A `Button` value with `isFocused == true` for the focused index and `false` for the others.

---

### Step 2 — LayoutEngine Evaluates the View Tree

Riku calls `LayoutEngine.layout(rootView, in: constraints)`. The engine recurses into the button's content as it always has. No special focus-layout path exists — `isFocused` is a passive flag, not a layout instruction.

**Emotional state**: Trusting — nothing changes in the layout pass; the familiar tree comes back.

**Expected output**: A `LayoutTree` where each button node's associated view carries `isFocused` as stored on the value.

---

### Step 3 — Renderer Reads isFocused and Applies Visual Distinction

In SpaceSim's renderer, Riku casts the view and checks `isFocused`:

```swift
if let btn = view as? AnyButton, btn.isFocused {
    // draw highlight border or tint
}
```

The renderer applies a visual treatment with ≥ 3:1 contrast against the unfocused state.

**Emotional state**: Satisfied — the flag is exactly where expected, no runtime query needed.

**Expected output**: The focused button renders visually distinct; the other buttons render normally.

---

## Emotional Arc

| Step | State        | Note                                             |
|------|--------------|--------------------------------------------------|
| 1    | Confident    | Familiar constructor pattern, one new parameter  |
| 2    | Trusting     | Layout unchanged — isFocused is a passive flag   |
| 3    | Satisfied    | Renderer reads flag directly from value type     |

Arc: Confident → Trusting → Satisfied. Confidence is maintained throughout.

---

## Error Paths

| Risk                          | Failure                                      | Recovery                                                        |
|-------------------------------|----------------------------------------------|-----------------------------------------------------------------|
| Default not false             | Existing call sites accidentally appear focused | `isFocused` defaults to `false`; no existing initialiser changed |
| Action fires on focus change  | Player pressing D-pad triggers button action | `isFocused` is a stored property; action fires only when called  |
| Multiple buttons marked focused | Renderer highlights two buttons              | Each `Button` is an independent value; consumer controls which one gets `isFocused: true` |
