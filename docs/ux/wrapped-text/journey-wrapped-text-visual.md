# Journey: WrappedText — Visual Map

## Persona
**Riku Nakamura** — game developer building a HUD inventory panel in Swift. He uses GameUI with Raylib. He needs to display item descriptions, quest log entries, and dialogue that can be arbitrarily long.

## Goal
Declare a `WrappedText` view, pass it to `LayoutEngine`, and get back a layout tree where every line fits within the available width — so his renderer can draw each line at the correct position without overflowing the panel.

---

## Emotional Arc

```
DECLARE             LAYOUT              RENDER
   |                   |                   |
Curious/Hopeful    Focused/Verifying   Confident/Satisfied
"Will this just    "Does each line     "Text fits. I can
 work like Text?"   stay in bounds?"    ship this panel."
```

Start: **Curious** — Riku has used `Text` and expects `WrappedText` to follow the same pattern.
Middle: **Focused** — He inspects the resulting `LayoutTree` to verify child nodes exist and frames are correct.
End: **Confident** — The panel renders multi-line text that stays inside the HUD boundary.

---

## Journey Flow (ASCII)

```
[Step 1: Declare]                [Step 2: Layout]                  [Step 3: Render]
                                                                              
 Riku writes:                     LayoutEngine processes                Each LayoutNode
 WrappedText(                      WrappedText branch:                   child is drawn
   content: "Long string…",         1. Split content into words          at its frame
   fontSize: 16,                    2. Greedily build lines              origin:
   color: .white                    3. Measure each line candidate          line 0 → y=0
 )                                  4. Wrap when line exceeds             line 1 → y=16
                                       constraints.maxWidth               line 2 → y=32
 Feels: Curious                     5. Each line → child LayoutNode
 Artifact: WrappedText value        6. Return root node with children
                                                                     
 ──────────────────────>             Feels: Focused                  Feels: Confident
 [textMeasurer present?]             Artifact: LayoutTree              (renderer walk)
  YES → accurate line widths          with N child nodes
  NO  → char-count fallback
```

---

## Step 1: Declaration

```
+-- Step 1: Declare WrappedText ----------------------------------------+
|                                                                        |
|  // In Riku's HUD panel builder:                                       |
|                                                                        |
|  WrappedText(                                                          |
|      content: "The ancient relic pulses with an eerie blue glow,      |
|                said to grant its bearer visions of the past.",         |
|      fontSize: 14,                                                     |
|      color: .white                                                     |
|  )                                                                     |
|                                                                        |
|  // Injected engine:                                                   |
|  let engine = LayoutEngine(textMeasurer: makeTextMeasurer(font: font)) |
|                                                                        |
|  Shared artifact: ${textMeasurer}  ← source: LayoutEngine init        |
+------------------------------------------------------------------------+
```

Emotional state entry: Curious — "Will this compose like Text?"
Emotional state exit: Hopeful — "I declared it the same way."

---

## Step 2: Layout Engine Processing

```
+-- Step 2: LayoutEngine.layoutNode(WrappedText) -----------------------+
|                                                                        |
|  Input: WrappedText{content, fontSize, color}                         |
|         LayoutConstraints{maxWidth: ${maxWidth}, maxHeight: …}        |
|         origin: ${origin}                                              |
|                                                                        |
|  Process:                                                              |
|   words = content.split(by: " ")                                      |
|   currentLine = ""                                                     |
|   lines = []                                                           |
|   for word in words:                                                   |
|     candidate = currentLine + " " + word (trimmed)                    |
|     if measure(candidate, fontSize).width <= maxWidth:                 |
|       currentLine = candidate                                          |
|     else:                                                              |
|       if currentLine not empty: lines.append(currentLine)             |
|       if word alone > maxWidth: lines.append(word)  ← unbreakable     |
|       else: currentLine = word                                         |
|   if currentLine not empty: lines.append(currentLine)                 |
|                                                                        |
|  Fallback (no measurer):                                               |
|   width estimate = fontSize × charCount                                |
|   (same as Text node fallback)                                         |
|                                                                        |
|  Output: LayoutNode{                                                   |
|    frame: Rect(origin, Size(maxWidth, totalHeight))                    |
|    children: [                                                         |
|      LayoutNode{frame: Rect(origin, lineSize)}  ← line 0              |
|      LayoutNode{frame: Rect(y+lineH, lineSize)} ← line 1              |
|      …                                                                 |
|    ]                                                                   |
|  }                                                                     |
|                                                                        |
|  Shared artifact: ${textMeasurer} used here                           |
+------------------------------------------------------------------------+
```

Emotional state entry: Focused — "Let me check the child nodes."
Emotional state exit: Verifying — "Each child has a frame, let me count them."

Integration checkpoint: child node count equals the number of wrapped lines; no child frame width exceeds `constraints.maxWidth`.

---

## Step 3: Renderer Walk

```
+-- Step 3: Renderer Consumes LayoutTree -------------------------------+
|                                                                        |
|  for (line, childNode) in zip(wrappedText.lines, node.children):      |
|    DrawText(line, at: childNode.frame.origin, …)                       |
|                                                                        |
|  Visual output in HUD panel (maxWidth = 200px, fontSize = 14):        |
|                                                                        |
|  +-- Item Description (200px) -------+                                |
|  | The ancient relic pulses with an  |  ← line 0, y=0                 |
|  | eerie blue glow, said to grant    |  ← line 1, y=14                |
|  | its bearer visions of the past.   |  ← line 2, y=28                |
|  +------------------------------------+                                |
|                                                                        |
|  Each line stays within the 200px boundary.                           |
+------------------------------------------------------------------------+
```

Emotional state entry: Hopeful — "Will the lines actually fit on screen?"
Emotional state exit: Confident/Satisfied — "Text fits. Panel is complete."

---

## Error Paths

### Error Path A: No word breaks possible (single word wider than maxWidth)

```
+-- Error Path A: Unbreakable Word ------------------------------------+
|                                                                       |
|  content: "Superlongitemnamedunbreakable"                            |
|  maxWidth: 50px, fontSize: 14                                        |
|                                                                       |
|  Expected behaviour:                                                  |
|   → Word placed as-is on its own line                                |
|   → Child node frame.size.width may exceed maxWidth                  |
|   → No infinite loop, no crash                                       |
|   → Renderer clips at its own boundary (outside WrappedText scope)   |
+-----------------------------------------------------------------------+
```

### Error Path B: Empty string

```
+-- Error Path B: Empty Content ---------------------------------------+
|                                                                       |
|  content: ""                                                         |
|                                                                       |
|  Expected behaviour:                                                  |
|   → Zero child LayoutNodes produced                                  |
|   → Root frame size: Size(width: 0, height: 0) or Size(maxWidth, 0) |
|   → No crash                                                         |
+-----------------------------------------------------------------------+
```

### Error Path C: Near-zero constraints

```
+-- Error Path C: Near-Zero maxWidth ----------------------------------+
|                                                                       |
|  constraints.maxWidth: 1.0, content: "Hello world"                  |
|                                                                       |
|  Expected behaviour:                                                  |
|   → Each word becomes its own line (all exceed 1px, placed as-is)   |
|   → No infinite loop                                                 |
|   → Lines: ["Hello", "world"]                                        |
+-----------------------------------------------------------------------+
```

---

## Integration Checkpoints

1. `textMeasurer` is the single source of truth for line width measurement. If absent, char-count fallback activates — same rule as `Text`.
2. Child `LayoutNode` origins are stacked vertically: `y = origin.y + (lineIndex × lineHeight)`.
3. Root frame width = `constraints.maxWidth` (not the maximum line width); root frame height = sum of all line heights.
4. Renderer must pattern-match `WrappedText` separately from `Text` and walk `.children` for draw calls.
