# Journey: Button Styling — Visual Summary (SSOT)

> Full visual narrative: `docs/feature/button-styling/discuss/journey-button-styling-visual.md`

## Persona
Riku Nakamura — game developer building SpaceSim menus. Needs "Start Game" (primary),
"Settings" (secondary), and "Quit" (destructive) to render distinctly.

## Emotional Arc

Curious → Confident → Trusting → Satisfied/Delighted

## Flow (Summary)

```
[Trigger: all buttons look identical]
        |
        v
[Step 1] Button(tag: "primary" / "secondary" / "destructive")
         Emotional: Confident — one argument, same pattern as isFocused
        |
        v
[Step 2] LayoutEngine.layout(view, ...)
         Tag invisible to layout — geometry unchanged
         Emotional: Trusting
        |
        v
[Step 3] Renderer: if let btn = view as? AnyButton { switch btn.tag { ... } }
         One switch covers all screens. Theme change = one line edit.
         Emotional: Satisfied/Delighted
```

## Design Decision

Option A (tag) chosen over Option B (color injection).
JTBD O-2 "minimise call-site edits on theme change" scored 17 — highest priority.
See: `docs/feature/button-styling/discuss/jtbd-opportunity-scores.md`

## API Shape

```swift
// AnyButton protocol addition:
var tag: String { get }

// Button<Content> init addition:
Button(tag: String = "", isFocused: Bool = false, action: ..., content: ...) { ... }
```

## Stories

- US-BS-01: Tag Property on Button (Walking Skeleton — ≤ 0.5 days)
- US-BS-02: Standard Tag Vocabulary (Documentation — ≤ 0.25 days)

## changelog
- 2026-05-18: Initial SSOT visual summary created (button-styling DISCUSS wave)
