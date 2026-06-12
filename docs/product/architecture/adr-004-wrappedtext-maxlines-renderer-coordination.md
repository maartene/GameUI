# ADR-004: WrappedText maxLines — Renderer Coordination Strategy

## Status

Accepted

---

## Context

The existing `WrappedText` design (ADR-001, Option C) establishes that both the layout engine and the renderer call `wrappedLines(measurer:maxWidth:)` independently. The method is deterministic, so double invocation is safe: both sides get the same line array and can zip layout nodes with line strings.

Introducing `maxLines: Int?` creates a coordination gap. The layout engine must clip the line array to `maxLines` when producing child `LayoutNode` entries. If the renderer continues to call `wrappedLines` directly (unclipped), it receives `N` strings but only `min(N, maxLines)` child nodes — a length mismatch that causes `zip` to silently drop lines or, worse, a renderer-side index error.

Three strategies were identified for keeping the renderer's line-array in sync with `node.children.count` after clipping:

**Option A — Renderer applies clipping independently**
Renderer calls `wrappedLines` and then manually applies `prefix(wt.maxLines ?? Int.max)` before zipping. The clipping expression is duplicated between layout engine and renderer.

**Option B — New `clippedLines(measurer:maxWidth:)` method on `WrappedText`**
`WrappedText` gains a second pure method that internally calls `wrappedLines` and applies the prefix. The layout engine continues to call `wrappedLines` (for the full set, then clips inline). The renderer calls `clippedLines`. Clipping logic lives in one place on the owning type.

**Option C — Change `wrappedLines` signature to accept `maxLines`**
`wrappedLines(measurer:maxWidth:maxLines:)` applies clipping internally. The layout engine and renderer call the same method with `maxLines` passed through. The existing signature is replaced or overloaded.

The product constraints additionally require: no new protocols, no new types, no mutation, no changes to `LayoutNode`/`LayoutTree`/`LayoutEngine` public API, backward compatibility with all existing renderer code.

---

## Decision

**Option B**: `WrappedText` gains a second pure method `clippedLines(measurer:maxWidth:) -> [String]`.

- `wrappedLines` is unchanged. Existing layout engine call site is unchanged. Existing renderers that already call `wrappedLines` on `maxLines == nil` views continue to work correctly.
- `clippedLines` calls `wrappedLines` internally and applies `prefix(maxLines ?? wrappedLines.count)`. The prefix expression exists in exactly one place.
- The layout engine calls `wrappedLines` and applies the prefix inline for child-node generation. This is intentionally separate from `clippedLines` because the engine also needs the unclipped count for the height formula: `Float(maxLines ?? allLines.count) * lineHeight`.
- The renderer calls `clippedLines` and receives a `[String]` of exactly `node.children.count` elements.

Invariant the design must preserve: `clippedLines(...).count == node.children.count` when both the layout engine and renderer are called with the same measurer and constraints. This is documented as a precondition in the API, not a runtime guard (consistent with Swift standard library conventions).

---

## Alternatives Considered

### Option A — Renderer applies clipping independently

**Evaluation**: Duplication of the `prefix(maxLines ?? ...)` expression across every renderer implementation. If the capping expression changes (e.g., a guard for negative `maxLines` is added), all renderer authors must update independently. Rejected because it maximises renderer complexity and splits ownership of the clipping rule.

**Quality attribute impact**: Violates Maintainability. Renderer authors must understand `maxLines` semantics to apply the correct prefix; a bug in their clipping expression produces subtle misalignment rather than a clear error.

### Option C — Change `wrappedLines` signature to `maxLines` parameter

**Evaluation**: Changing the signature of `wrappedLines` is a source-breaking change to the existing public API. Every existing renderer that calls `wrappedLines(measurer:maxWidth:)` must be updated. Additionally, the layout engine needs the *unclipped* line count to compute the reserved height formula (`Float(maxLines) * lineHeight` vs `Float(allLines.count) * lineHeight` differ in the floor case). This forces the engine to call the method twice or decompose the return value, adding complexity. Rejected because it increases API surface change and complicates the layout engine without benefit.

**Quality attribute impact**: Source-breaking public API change violates Backward Compatibility. Engine complexity increase violates Maintainability.

---

## Consequences

### Positive

- `WrappedText` remains the single source of clipping logic: one method, one `prefix` expression.
- Backward compatibility is preserved: `wrappedLines` signature unchanged; existing renderer code calling `wrappedLines` on a `maxLines == nil` view is still correct (returns same result as `clippedLines` when `maxLines` is nil).
- The `clippedLines` method is trivially testable in isolation (pure function, same test harness as `wrappedLines`).
- `layoutWrappedTextNode` retains access to both `allLines` (for height formula) and `visibleLines` (for child-node generation) within the same call without double method invocation.

### Negative / Accepted Trade-offs

- Two public methods on `WrappedText` with similar names may confuse renderer authors. Mitigated by doc comment on `wrappedLines` directing renderer authors to `clippedLines`.
- `clippedLines` duplicates the call to `wrappedLines` internally (the line-splitting runs twice during a render cycle, same as the pre-feature design). This is accepted for the same reasons as ADR-001: O(n) on short UI strings, deterministic, caching would require mutable state.

---

## References

- ADR-001: WrappedText Line Decomposition Strategy — establishes `wrappedLines` as single source of truth
- `Sources/GameUI/WrappedText.swift` — `wrappedLines` implementation
- `Sources/GameUI/LayoutEngine.swift` — `layoutWrappedTextNode` branch
- `docs/feature/wrapped-text-max-lines/discuss/user-stories.md` — US-04, US-05
- `docs/feature/wrapped-text-max-lines/discuss/shared-artifacts-registry.md` — `visibleLines` and `frame.size.height` coordination checkpoints
