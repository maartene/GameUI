# Journey: WrappedText — Visual Map (Product SSOT)

> **SSOT copy.** Canonical journey for the `wrapped-text` feature.
> Detailed feature artifacts: `docs/feature/wrapped-text/discuss/`

## Persona
**Riku Nakamura** — game developer building HUD panels and dialogue boxes in Swift using GameUI and a custom renderer (Raylib or similar).

## Goal
Declare `WrappedText(content:fontSize:color:)`, pass it to `LayoutEngine`, and get a layout tree with one child `LayoutNode` per wrapped line — no line exceeds the available width.

## Emotional Arc

```
DECLARE              LAYOUT                RENDER
Curious/Hopeful  →   Focused/Verifying  →  Confident/Satisfied
"Like Text?"         "Child nodes OK?"     "Panel fits. Ship it."
```

## Journey Flow

```
[Declare]                 [Compute Layout]              [Render]

WrappedText(              LayoutEngine branch:          Renderer walks
  content: "...",           words → greedy lines          node.children:
  fontSize: 14,             measure each candidate          line 0 at y=0
  color: .white             break when > maxWidth           line 1 at y=14
)                           child LayoutNode per line       line 2 at y=28
                            stack vertically
```

## Error Paths

| Scenario | Input | Expected Behaviour |
|----------|-------|-------------------|
| Unbreakable word | `"AncientRelicOfThePast"` at `maxWidth: 50` | 1 child node, no crash |
| Empty content | `content: ""` | 0 children, height 0, no crash |
| Near-zero maxWidth | `maxWidth: 1.0`, "Hello world" | 2 children (one word each), no infinite loop |
| No measurer | `LayoutEngine()` without textMeasurer | Char-count fallback, layout proceeds |

## Key Integration Point

`textMeasurer` in `LayoutEngine` is the single source of truth for line width measurement. Without it, `fontSize * charCount` fallback activates (same as `Text`). The renderer needs access to per-line strings — see `shared-artifacts-registry.md` open design question.
