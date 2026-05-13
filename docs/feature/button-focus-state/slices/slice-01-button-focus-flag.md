# Slice 01 — button-focus-flag

## Goal

Add `isFocused: Bool` (default `false`) to `Button<Content>` so renderers can inspect the flag and display a visually distinct state for gamepad/keyboard players.

## IN Scope

- `isFocused: Bool` stored property on `Button<Content>`
- `isFocused` parameter added to `Button.init` with default `false`
- `AnyButton` protocol updated to expose `isFocused` (or access confirmed via concrete cast — DESIGN decides)
- All 5 acceptance criteria scenarios passing

## OUT Scope

- Focus index management (stays in SpaceSim)
- Up/Down input handling, navigation logic, animation
- GUIContext changes
- Visual rendering implementation (stays in SpaceSim renderer)
- New `FocusableButton` type

## Learning Hypothesis

**Disproves**: `isFocused` requires a new type, GUIContext change, or layout-engine modification to be inspectable.  
**Confirms**: A plain stored `Bool` property on the existing `Button` struct (with a default-`false` initialiser parameter) is sufficient for the renderer to act on focus state.

## Acceptance Criteria

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

## Dependencies

- No blockers. `Button<Content>` and `AnyButton` are fully defined in `LeafViews.swift`.
- ODQ-01 resolved: `isFocused: Bool` is added to the `AnyButton` protocol. No DESIGN wave gate needed before implementation.

## Effort Estimate

≤ 2 hours crafter dispatch time.  
**Reference class**: analogous to adding `alignment: TextAlignment` to `Text` — a new stored property with a default, no structural change.

## Pre-slice SPIKE

None needed. The existing pattern (stored property with default, default parameter in `init`) is established and low-risk.
