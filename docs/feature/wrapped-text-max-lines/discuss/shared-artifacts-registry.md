# Shared Artifacts Registry: wrapped-text-max-lines

> Tracks data values that appear in multiple places across the journey.
> Every `${variable}` in mockups and scenarios must trace to a single source of truth here.

## Registry

### maxLines

| Field | Value |
|-------|-------|
| Source of Truth | `WrappedText.maxLines: Int?` property |
| Consumers | `layoutWrappedTextNode` (clips lines, sets reserved height) |
| Owner | `wrapped-text-max-lines` feature |
| Integration Risk | HIGH — surrounding layout depends on this producing a stable, fixed height |
| Validation | `root.frame.size.height == maxLines * lineHeight` for all content lengths when non-nil |

### lineHeight

| Field | Value |
|-------|-------|
| Source of Truth | `textMeasurer?(word, fontSize).height ?? fontSize` — unchanged from wrapped-text feature |
| Consumers | `layoutWrappedTextNode` (computes child origins and reserved height) |
| Owner | `wrapped-text` feature (no change) |
| Integration Risk | LOW — existing contract; not changed by this feature |
| Validation | Child origins stacked at `i * lineHeight`; height = `maxLines * lineHeight` |

### visibleLines

| Field | Value |
|-------|-------|
| Source of Truth | `Array(allLines.prefix(maxLines ?? allLines.count))` computed in `layoutWrappedTextNode` |
| Consumers | Child `LayoutNode` generation; `WrappedText.lines` property exposed to renderer |
| Owner | `wrapped-text-max-lines` feature |
| Integration Risk | MEDIUM — renderer uses `wt.lines` via `zip(wt.lines, node.children)`; must be clipped to `maxLines` before storage |
| Validation | `wt.lines.count == node.children.count`; both clipped to `maxLines` when non-nil |

### frame.size.height (root node)

| Field | Value |
|-------|-------|
| Source of Truth | `(maxLines ?? allLines.count) * lineHeight` in `layoutWrappedTextNode` |
| Consumers | Parent layout containers (VStack, HStack) for stacking surrounding elements; portrait, hint prompt position |
| Owner | `wrapped-text-max-lines` feature (for non-nil path); `wrapped-text` feature (for nil path) |
| Integration Risk | HIGH — this is the primary stability guarantee of the feature; any deviation causes layout shift |
| Validation | Constant regardless of actual line count when `maxLines` is non-nil |

---

## Integration Checkpoints

### Checkpoint 1: `maxLines` → `frame.size.height`
`layoutWrappedTextNode` must compute height as `Float(maxLines) * lineHeight` when `maxLines` is non-nil, not as `Float(visibleLines.count) * lineHeight`. These differ when content is shorter than `maxLines` (floor case).

### Checkpoint 2: `visibleLines` → `wt.lines`
The lines stored on `WrappedText` for renderer access must be the post-clip `visibleLines`, not `allLines`. Otherwise `zip(wt.lines, node.children)` would produce a length mismatch.

### Checkpoint 3: `maxLines: nil` backward compatibility
The `nil` path must produce identical output to the pre-feature implementation. Regression test: all US-01 through US-03 scenarios pass without modification.

---

## Open Design Questions

None. The design constraint (intrinsic property, not modifier) resolves the `RecordingGameUIAdapter` traversal issue and eliminates the only open question. No red cards remaining.
