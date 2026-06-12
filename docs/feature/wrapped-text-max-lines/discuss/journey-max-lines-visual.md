# Journey Delta: WrappedText maxLines — Visual Map

> **Focused delta document.** This describes only the changes introduced by `wrapped-text-max-lines`.
> Full baseline journey: `docs/product/journeys/wrapped-text-visual.md`
> Full baseline SSOT: `docs/product/journeys/wrapped-text.yaml`

## What Changes

The existing wrapped-text journey has 3 steps: Declare → Layout → Render.
This enhancement touches **Step 1 (Declare)** with a new optional parameter and **Step 2 (Layout)** with new clipping and height-reservation logic. Step 3 (Render) is unchanged — `zip(wt.lines, node.children)` still works because `wt.lines` is already clipped.

---

## Persona
**Riku Nakamura** — game developer building SpaceSim narrative screens. Needs a 3-line fixed area for body text so portrait and hint prompt never jump when narration length varies.

---

## Emotional Arc (delta)

```
DECLARE                  LAYOUT                    RENDER
Confident/Clear      →   Trusting/Efficient    →   Satisfied/Stable
"One parameter          "Engine handles             "Layout is rock solid.
 at the call site.       floor + ceiling.            Portrait never jumps."
 Intent is obvious."     I don't math this."
```

Before this feature, the emotional arc had a friction point at Declare: Riku had to wrap `WrappedText` in a `VStack` + `Spacer` + `.frame(height:)` and mentally translate "3 lines" to a pixel value. The intent was invisible at the call site.

---

## Step 1 (Declare) — Delta

### Before
```swift
VStack {
    WrappedText(content: line.text, fontSize: 22, color: .white)
    Spacer()
}
.frame(width: w, height: 3 * 22)   // intent buried in pixel math
```

### After
```swift
WrappedText(content: line.text, fontSize: 22, maxLines: 3)
//          ^                                  ^
//          same                               intent expressed here
```

**New failure modes at Declare:**
- `maxLines: 0` passed — zero-height reservation (no lines reserved). Treated as valid; produces `frame.size.height == 0`.
- `maxLines: 1` passed — single-line reservation. Short narration fills the line; longer narration is clipped after word 1 wraps.
- `maxLines` omitted / `nil` — existing behaviour unchanged.

---

## Step 2 (Layout) — Delta

### Behaviour change

```
Before (maxLines nil):
  lines = greedyWrap(content, maxWidth)
  height = lines.count * lineHeight
  children = lines.map { LayoutNode per line }

After (maxLines non-nil):
  allLines = greedyWrap(content, maxWidth)         ← unchanged
  visibleLines = Array(allLines.prefix(maxLines))  ← clip ceiling
  height = maxLines * lineHeight                   ← reserved (floor + ceiling)
  children = visibleLines.map { LayoutNode }       ← clipped count
```

### ASCII Decision Table

```
maxLines | actual lines | children | height
---------|--------------|----------|-----------------------------
nil      | 1            | 1        | 1 * lineHeight  (content)
nil      | 3            | 3        | 3 * lineHeight  (content)
3        | 1            | 1        | 3 * lineHeight  (RESERVED)
3        | 3            | 3        | 3 * lineHeight  (reserved == content)
3        | 5            | 3        | 3 * lineHeight  (CLIPPED)
0        | any          | 0        | 0               (zero reservation)
1        | 1            | 1        | 1 * lineHeight  (tight reservation)
1        | 3            | 1        | 1 * lineHeight  (tight + clipped)
```

**New failure modes at Layout:**
- `maxLines` set but content is empty — 0 children, height = `maxLines * lineHeight`. Floor still applies.
- `maxLines` larger than actual line count — only actual lines become children; height is still `maxLines * lineHeight`. Blank space below.

---

## Step 3 (Render) — Unchanged

`zip(wt.lines, node.children)` still produces one draw-call per visible line. Because `wt.lines` is already clipped to `maxLines`, the renderer pattern from US-03 requires no change.

```
Renderer walks children (unchanged):
  for (line, child) in zip(wt.lines, node.children)
    draw text at child.frame.origin
  // blank space below last child is empty — no draw calls needed
```

---

## Integration Points

| Artifact | Source of Truth | Risk |
|----------|-----------------|------|
| `maxLines` | `WrappedText.maxLines` property | LOW |
| `lineHeight` | `textMeasurer` result or `fontSize` fallback (unchanged) | LOW |
| `wt.lines` | Greedy algorithm output, clipped to `maxLines` before storage | MEDIUM — renderer relies on this being clipped |
| `frame.size.height` | `maxLines * lineHeight` when `maxLines` non-nil | HIGH — surrounding layout depends on this being fixed |

---

## Error Path Summary

| Scenario | Input | Expected Behaviour |
|----------|-------|-------------------|
| Short narration (floor) | `maxLines: 3`, 1 wrapped line | 1 child, height = 3 × lineHeight |
| Long narration (ceiling) | `maxLines: 3`, 5 wrapped lines | 3 children, height = 3 × lineHeight, lines 4–5 clipped |
| Exact fit | `maxLines: 3`, 3 wrapped lines | 3 children, height = 3 × lineHeight, no clipping |
| nil (unchanged) | `maxLines: nil` | Existing behaviour: N children, height = N × lineHeight |
| Zero reservation | `maxLines: 0` | 0 children, height = 0 |
| Single line reservation | `maxLines: 1` | At most 1 child, height = lineHeight |
| maxLines + empty content | `maxLines: 3`, content = "" | 0 children, height = 3 × lineHeight (floor applies) |
