# User Stories — button-focus-state

*JTBD skipped (Decision 4 = No). User motivation is explicit in the brief.*

---

## S-01 — Button Focus Flag

**As** a game developer using GameUI,  
**I want** `Button` to carry an `isFocused: Bool` flag (default `false`),  
**So that** my renderer can visually distinguish the focused button for gamepad/keyboard players without any GUIContext coupling.

### Elevator Pitch

Before: There is no way to mark a `Button` as focused — gamepad/keyboard players see no visual difference between buttons regardless of which one is selected in the navigation logic.

After: Construct `Button(isFocused: true) { content } action: { handler }` → inspect `button.isFocused` on the resulting value and find `true`; the renderer applies a visual highlight with ≥ 3:1 contrast against unfocused buttons.

Decision enabled: The renderer (SpaceSim) decides which visual treatment to apply — highlight border, background tint, or glow — based on `isFocused`, without needing to query GUIContext or maintain separate focus state in the rendering layer.

### Acceptance Criteria

```gherkin
Scenario: isFocused: true produces a focused node in the view tree
  Given a Button constructed with isFocused: true
  When the view tree is evaluated
  Then the Button carries isFocused == true

Scenario: isFocused defaults to false — existing call sites unchanged
  Given a Button constructed without isFocused
  When the view tree is evaluated
  Then the Button carries isFocused == false

Scenario: Focus flag does not fire the action
  Given a Button constructed with isFocused: true
  When the view tree is evaluated
  Then the action has not been invoked

Scenario: Action fires only when the consumer calls it
  Given a Button with isFocused: true
  When the consumer explicitly invokes the action
  Then it fires exactly once

Scenario: Multiple buttons — only the focused one carries isFocused == true
  Given three Buttons, the second with isFocused: true
  When the view tree is evaluated
  Then exactly one Button carries isFocused == true — the second one
```

### Constraints (from brief)

- `isFocused` lives on the `Button` value type — inspectable without a Raylib window
- `GUIContext` is not changed — focus index stays in SpaceSim
- No new `FocusableButton` type — extend existing `Button` only
- All existing call sites compile unchanged (`isFocused` defaults to `false`)

### Out of Scope

Focus index management, Up/Down input handling, navigation logic, animation — all stay in SpaceSim.

### Slice

Slice 01 — button-focus-flag (`docs/feature/button-focus-state/slices/slice-01-button-focus-flag.md`)
