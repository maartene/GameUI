# Shared Artifacts Registry: wrapped-text

## Purpose

Every `${variable}` appearing across the WrappedText journey has a single documented source of truth. This registry prevents integration failures between the layout engine, the view value, and downstream renderers.

---

## Registry

### textMeasurer

| Field | Value |
|-------|-------|
| **Source of truth** | `LayoutEngine` initialiser parameter: `textMeasurer: (@Sendable (String, Float) -> Size)?` |
| **Owner** | `LayoutEngine` struct (GameUI framework) |
| **Consumers** | Step 1 fallback detection; Step 2 `layoutWrappedTextNode` greedy loop |
| **Integration risk** | HIGH — if nil, char-count fallback activates silently; misinjected measurer produces wrong line breaks |
| **Validation** | Test: inject stub measurer, verify child widths are consistent with measurer output |

### content

| Field | Value |
|-------|-------|
| **Source of truth** | `WrappedText.content: String` property |
| **Owner** | `WrappedText` view value |
| **Consumers** | Step 2 word-splitter; Step 3 renderer (re-splits to recover line strings per child node) |
| **Integration risk** | MEDIUM — renderer must either re-split identically or receive pre-computed line strings. Open design question resolved in DESIGN wave. |
| **Validation** | Test: content round-trips through layout → renderer without mutation |

### fontSize

| Field | Value |
|-------|-------|
| **Source of truth** | `WrappedText.fontSize: Float` property |
| **Owner** | `WrappedText` view value |
| **Consumers** | Step 2: passed to `textMeasurer(candidate, fontSize)`; Step 2: used as `lineHeight` for y-offset stacking; Step 3: renderer draw call font size argument |
| **Integration risk** | HIGH — if renderer uses a different fontSize than the layout engine used for measurement, lines overflow visually even though layout said they fit |
| **Validation** | Test: renderer must read `wrappedText.fontSize` not a local constant |

### color

| Field | Value |
|-------|-------|
| **Source of truth** | `WrappedText.color: Color` property |
| **Owner** | `WrappedText` view value |
| **Consumers** | Step 3: renderer draw call color argument |
| **Integration risk** | LOW — color does not affect layout; only affects rendering |
| **Validation** | Renderer test: color property accessible on pattern-matched `WrappedText` |

### maxWidth (constraints)

| Field | Value |
|-------|-------|
| **Source of truth** | `LayoutConstraints.maxWidth: Float` passed to `LayoutEngine.layout(_:in:)` |
| **Owner** | Caller (game developer) |
| **Consumers** | Step 2: line overflow gate `candidateWidth > maxWidth`; root node frame width |
| **Integration risk** | HIGH — constraint is the only external input controlling wrap behaviour; wrong value produces wrong breaks |
| **Validation** | Test: vary maxWidth and assert child count changes accordingly |

### lineStrings (computed)

| Field | Value |
|-------|-------|
| **Source of truth** | Greedy word-wrap algorithm in `LayoutEngine.layoutWrappedTextNode` (computed at layout time) |
| **Owner** | Layout algorithm output — OPEN DESIGN QUESTION for DESIGN wave |
| **Consumers** | Step 3: renderer needs line strings to draw text at each child origin |
| **Integration risk** | HIGH — renderer cannot draw text without knowing what string each child node represents. Two options: (A) store computed lines on `WrappedText` as a mutable post-layout annotation; (B) renderer re-splits identically using same content + same measurer. Option B is fragile. Recommend Option A or a new type. |
| **Validation** | End-to-end test: rendered draw commands contain the same words as content, in order |

### childNodeOrigins

| Field | Value |
|-------|-------|
| **Source of truth** | `LayoutEngine` child placement loop: `y = parentOrigin.y + lineIndex * lineHeight` |
| **Owner** | `LayoutEngine.layoutWrappedTextNode` |
| **Consumers** | Step 3: renderer uses `childNode.frame.origin` as draw-call position |
| **Integration risk** | MEDIUM — if lineHeight is not consistently `fontSize`, lines overlap or gap |
| **Validation** | Test: child node origin y-values are evenly spaced by `fontSize` |

---

## Integration Validation Summary

| Check | Artifact | Risk | Status |
|-------|----------|------|--------|
| textMeasurer reused for all lines in single pass | textMeasurer | HIGH | To validate in DESIGN wave |
| fontSize same in layout and render | fontSize | HIGH | Documented constraint |
| lineStrings accessible to renderer | lineStrings | HIGH | Open design question — DESIGN wave |
| child y-origins spaced by lineHeight | childNodeOrigins | MEDIUM | Verifiable in unit test |
| maxWidth respected as overflow gate | maxWidth | HIGH | Core AC |
| color accessible post-pattern-match | color | LOW | Simple property access |

---

## Open Design Question (carry to DESIGN wave)

**Q: How does the renderer know what string each child LayoutNode represents?**

The `LayoutNode` type carries only a `frame: Rect` and `children: [LayoutNode]`. It has no string payload. The renderer needs to know the string for each child to call `DrawText`.

Options:
- **A (Preferred)**: `WrappedText` stores a computed `var lines: [String]` populated during `layoutWrappedTextNode`. Renderer reads `wrappedText.lines[i]` paired with `node.children[i]`.
- **B**: Renderer re-runs the same word-split algorithm independently. Fragile — requires renderer to replicate layout logic exactly.
- **C**: Introduce a new `WrappedTextLine` view type that wraps a `Text` — each child is a real view node. Renderer recurses naturally. Increases tree complexity.

Recommend Option A or C for DESIGN wave evaluation.
