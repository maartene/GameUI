# DESIGN Decisions — wrapped-text-max-lines

## Key Decisions

- [D1] Add `maxLines: Int?` as a stored property on `WrappedText` with default `nil`: maintains backward compatibility; `nil` path produces identical output to pre-feature implementation. (see: `Sources/GameUI/WrappedText.swift`)

- [D2] Clipping happens in `layoutWrappedTextNode` after calling `wrappedLines`, not inside `wrappedLines` itself: the layout engine needs both `allLines` (for the height formula) and `visibleLines` (for child-node count) in the same call. Folding clipping into `wrappedLines` would either require two calls or force a signature change that breaks existing renderers. (see: `Sources/GameUI/LayoutEngine.swift`, ADR-004)

- [D3] Height formula is `Float(maxLines ?? allLines.count) * lineHeight`, not `Float(visibleLines.count) * lineHeight`: these differ in the floor case (content shorter than `maxLines`). Using `visibleLines.count` would produce wrong height. The `maxLines`-first formula is the floor+ceiling invariant. (see: US-04 AC, `docs/feature/wrapped-text-max-lines/discuss/shared-artifacts-registry.md`)

- [D4] `WrappedText` gains `clippedLines(measurer:maxWidth:) -> [String]` as a second pure method for renderer use: renderer must zip against the clipped set, not the full `wrappedLines` output. Placing clipping in one method on the owning type prevents duplication across renderer implementations. `wrappedLines` remains unchanged. (see: ADR-004)

- [D5] `lineHeight` for the empty-content case (`allLines == []`) is derived from any non-empty probe string via the existing measurer, falling back to `fontSize` when no measurer is injected: this is identical to the existing lineHeight derivation path; no new fallback logic required. (see: `docs/feature/wrapped-text-max-lines/discuss/shared-artifacts-registry.md` — `lineHeight` entry)

- [D6] `maxLines: nil` init default uses Swift default parameter syntax, not an overloaded init: maintains a single init site; caller omitting `maxLines` gets `nil` without breaking source compatibility with existing `WrappedText(content:fontSize:color:)` call sites. (see: `docs/product/journeys/wrapped-text.yaml` Step 1 action signature)

## Architecture Summary

- Pattern: brownfield extension — intrinsic property + `layoutWrappedTextNode` modification + second pure method on owning type
- Paradigm: OOP (Swift protocol-oriented value types, all structs)
- Key components: `WrappedText` (extended), `layoutWrappedTextNode` (extended), `clippedLines` (new pure method)

## Reuse Analysis

| Existing Component | File | Overlap | Decision | Justification |
|---|---|---|---|---|
| `WrappedText` struct | `Sources/GameUI/WrappedText.swift` | Stores `content`, `fontSize`, `color`; exposes `wrappedLines` | EXTEND | Add `maxLines: Int?` stored property and `clippedLines(measurer:maxWidth:)` method. No existing responsibilities change. |
| `wrappedLines(measurer:maxWidth:)` | `Sources/GameUI/WrappedText.swift` | Full greedy line-splitting algorithm | REUSE AS-IS | Called unchanged by `layoutWrappedTextNode` and as internal input to `clippedLines`. Splitting algorithm does not need to know about `maxLines`. |
| `layoutWrappedTextNode` | `Sources/GameUI/LayoutEngine.swift` | Calls `wrappedLines`, builds child `LayoutNode` array, computes root height | EXTEND | Two lines added post-`wrappedLines`: prefix-clip for visible lines, `maxLines`-driven height formula. Nil path unchanged. |
| `LayoutNode`, `LayoutTree`, `LayoutEngine` public API | `Sources/GameUI/LayoutEngine.swift` | Layout tree data structures and engine entry points | NO CHANGE | No new types, no new public surface, no structural changes to the tree. |
| `textMeasurer` closure on `LayoutEngine` | `Sources/GameUI/LayoutEngine.swift` | Injected text measurement function | REUSE AS-IS | `clippedLines` accepts the same `(@Sendable (String, Float) -> Size)?` signature unchanged. |
| `.frame(height:)` modifier / `HasFrameSize` | `Sources/GameUI/View.swift` | Reserved-height via wrapper modifier | REJECTED | `RecordingGameUIAdapter` requires a `HasFrameSize` traversal fix to see content behind a `FrameModifier`. Intrinsic property keeps `WrappedText` directly visible in the view tree. Non-negotiable per DISCUSS constraint. |

## Technology Stack

- Swift 6.2: no new dependency
- `Float` geometry: no new types; all arithmetic uses existing `Size`, `Rect`, `Point`
- No Foundation, no CGFloat, no third-party dependencies

## Constraints Established

- `maxLines: Int?` MUST be a stored property on `WrappedText`, not a modifier wrapper. Non-negotiable (RecordingGameUIAdapter traversal constraint from DISCUSS wave).
- Height formula MUST use `maxLines` (not `visibleLines.count`) to honour the floor invariant.
- `wrappedLines` signature MUST NOT change. Existing renderer code calling it on `maxLines == nil` views must continue to compile and produce correct results.
- `clippedLines` is the renderer-facing API from this feature forward. Renderers using `maxLines` must call `clippedLines`, not `wrappedLines`.
- All new types are structs (Swift 6.2 strict concurrency; no classes).
- No `import Foundation` in `WrappedText.swift`.
- All existing acceptance tests (Slice 1–3 WrappedText) must remain green without modification.
- `maxLines: 0` produces `height == 0.0` and 0 children (natural outcome of `prefix(0)`; no special guard needed).

## Upstream Changes

None. All DISCUSS assumptions are carried forward without modification.
