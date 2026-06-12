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

---

## Enhancement: maxLines (wrapped-text-max-lines)

> Added 2026-06-12. Full delta artifacts: `docs/feature/wrapped-text-max-lines/discuss/`

### New Call Site

```swift
// Before (workaround — intent buried in pixel math)
VStack {
    WrappedText(content: line.text, fontSize: 22, color: .white)
    Spacer()
}.frame(width: w, height: 3 * 22)

// After (intent expressed at call site)
WrappedText(content: line.text, fontSize: 22, maxLines: 3)
```

### Layout Change (Step 2 delta)

```
maxLines: nil  → height = actual_lines * lineHeight   (existing, unchanged)
maxLines: N    → height = N * lineHeight              (reserved — floor + ceiling)
                 children = allLines.prefix(N)         (ceiling clip)
```

### Behaviour Table

```
maxLines | actual lines | children | height
---------|--------------|----------|-----------------------------
nil      | 1            | 1        | 1 × lineHeight  (content)
nil      | 3            | 3        | 3 × lineHeight  (content)
3        | 1            | 1        | 3 × lineHeight  (RESERVED)
3        | 3            | 3        | 3 × lineHeight
3        | 5            | 3        | 3 × lineHeight  (CLIPPED)
0        | any          | 0        | 0
1        | 3            | 1        | 1 × lineHeight  (CLIPPED)
3        | 0 (empty)    | 0        | 3 × lineHeight  (floor on empty)
```

### New Error Paths

| Scenario | Input | Expected Behaviour |
|----------|-------|-------------------|
| Short narration (floor) | `maxLines: 3`, 1 line | 1 child, height = 3 × lineHeight |
| Long narration (ceiling) | `maxLines: 3`, 5 lines | 3 children, height = 3 × lineHeight |
| Zero reservation | `maxLines: 0` | 0 children, height = 0 |
| Single-line tight | `maxLines: 1`, 3 lines | 1 child, height = lineHeight |
| Empty + reserved | `maxLines: 3`, `content: ""` | 0 children, height = 3 × lineHeight |

### Renderer (Step 3) — Unchanged

`zip(wt.lines, node.children)` still works. `wt.lines` is clipped to `maxLines` before storage, so the zip pair counts always match.
