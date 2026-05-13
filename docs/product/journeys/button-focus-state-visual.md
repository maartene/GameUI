# Journey: Button Focus State (SSOT Summary)

**Feature**: button-focus-state | **Date**: 2026-05-13  
**Full artifacts**: `docs/feature/button-focus-state/discuss/`

---

**Goal**: Game developer marks a `Button` as focused; the renderer displays a visually distinct state (≥ 3:1 contrast) for gamepad/keyboard players.

**Persona**: Riku Nakamura — game developer integrating GameUI into SpaceSim, adding gamepad/keyboard navigation on top of existing mouse UI.

---

| Step | Action                                                  | Emotional State |
|------|---------------------------------------------------------|-----------------|
| 1    | `Button(isFocused: focusIndex == i) { ... } action: {}` | Confident        |
| 2    | `LayoutEngine.layout(rootView, in: constraints)`        | Trusting         |
| 3    | Renderer reads `btn.isFocused`, applies visual treatment | Satisfied        |

**Arc**: Confident → Trusting → Satisfied.

**ODQ-01 RESOLVED**: `isFocused: Bool` is added to the `AnyButton` protocol. Renderers use `if let btn = node.view as? AnyButton, btn.isFocused { … }` — no `Button<Content>` down-cast needed.
