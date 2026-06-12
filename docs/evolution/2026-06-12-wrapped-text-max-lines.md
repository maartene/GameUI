# Evolution: wrapped-text-max-lines

**Date**: 2026-06-12
**Feature ID**: wrapped-text-max-lines
**Wave path**: DISCUSS → DESIGN → DISTILL → DELIVER

---

## Feature Summary

Added `maxLines: Int?` property to `WrappedText` to let callers reserve a fixed vertical area regardless of actual line count. When `maxLines` is non-nil, `LayoutEngine.layoutWrappedTextNode` applies a floor+ceiling height formula: `height = maxLines × lineHeight`, and children are clipped to `prefix(maxLines)`. When `maxLines` is nil, behaviour is identical to the pre-feature implementation — fully backward compatible.

**Business context**: Game developer persona (Riku Nakamura) building SpaceSim narrative screens needed a 3-line fixed area for body text so portrait and hint prompt never jump when narration length varies. The feature replaces a verbose workaround (`VStack + Spacer + .frame(height:)` with manual pixel math) with a single declarative parameter at the call site.

---

## Steps Completed

Sourced from `deliver/execution-log.json`:

| Step | Phase | Status | Timestamp |
|------|-------|--------|-----------|
| 01-01 | PREPARE | PASS | 2026-06-12T19:13:57Z |
| 01-01 | RED_ACCEPTANCE | PASS | 2026-06-12T19:14:20Z |
| 01-01 | RED_UNIT | PASS | 2026-06-12T19:27:44Z |
| 01-01 | GREEN | PASS | 2026-06-12T19:28:53Z |
| 01-01 | COMMIT | PASS | 2026-06-12T19:29:24Z |
| 01-02 | PREPARE | PASS | 2026-06-12T19:32:59Z |
| 01-02 | RED_ACCEPTANCE | PASS | 2026-06-12T19:33:46Z |
| 01-02 | RED_UNIT | PASS | 2026-06-12T19:34:21Z |
| 01-02 | GREEN | PASS | 2026-06-12T19:34:42Z |
| 01-02 | COMMIT | PASS | 2026-06-12T19:34:56Z |
| refactor-L1-L4 | COMMIT | PASS | 2026-06-12T19:55:05Z |
| refactor-L1-L4 | PREPARE / RED_ACCEPTANCE / RED_UNIT / GREEN | SKIPPED | 2026-06-12T20:17:26–35Z |

**Step 01-01**: Implement `clippedLines(measurer:maxWidth:) -> [String]` on `WrappedText` — returns `wrappedLines` clipped to `prefix(maxLines ?? Int.max)`. Covered Slice 1 clippedLines contract + Slice 2 edge cases (maxLines 0, maxLines 1, empty content).

**Step 01-02**: Extend `layoutWrappedTextNode` in `LayoutEngine` — compute `displayLineCount = maxLines ?? allLines.count`, clip children to `prefix(displayLineCount)`, set `height = Float(displayLineCount) * lineHeight`. Covered 8 Slice 1 layout scenarios + 6 Slice 2 layout edge cases.

**Refactor pass (L1–L4)**: Behaviour-preserving cleanup after GREEN. All 153 tests remained green throughout. No new test files. No acceptance gate applicable (refactor, not behaviour change).

**Test results**: 22 new acceptance tests GREEN, 131 regression tests GREEN — 153/153 total.

---

## Key Decisions

### DISCUSS Wave

**D-DISCUSS-1: maxLines must be intrinsic to WrappedText**
The `RecordingGameUIAdapter` traversal cannot see content behind a `FrameModifier` wrapper. Therefore `maxLines` must be a stored property on `WrappedText` itself, not a `.frame(height:)` modifier. Non-negotiable constraint carried through all waves.

**D-DISCUSS-2: Walking skeleton skipped**
Brownfield leaf-view extension. The `WrappedText` + `LayoutEngine` integration path is fully validated by the existing wrapped-text Slice 1–3 acceptance suites. No new walking skeleton warranted.

**D-DISCUSS-3: maxLines: 0 semantics**
Treated as a valid zero-height reservation: 0 children, `frame.size.height == 0`. Natural outcome of `prefix(0)` — no special guard needed.

### DESIGN Wave

**D-DESIGN-1: Stored property with nil default (D6)**
`maxLines: nil` uses Swift default parameter syntax at the single init site. Caller omitting `maxLines` gets `nil` without breaking source compatibility with existing `WrappedText(content:fontSize:color:)` call sites.

**D-DESIGN-2: Height formula uses maxLines, not visibleLines.count (D3)**
`Float(maxLines ?? allLines.count) * lineHeight`. These differ in the floor case (content shorter than `maxLines`). Using `visibleLines.count` would produce wrong height — floor invariant requires `maxLines`-first formula.

**D-DESIGN-3: Clipping location in layoutWrappedTextNode (D2)**
Clipping happens after calling `wrappedLines`, not inside `wrappedLines`. The layout engine needs both `allLines` (for height formula) and `visibleLines` (for child-node count) within the same call. Folding clipping into `wrappedLines` would require two calls or a signature change that breaks existing renderers.

**D-DESIGN-4: clippedLines method on WrappedText (D4, ADR-004 Option B)**
`WrappedText` gains a second pure method `clippedLines(measurer:maxWidth:) -> [String]` as the renderer-facing API. The clipping expression (`prefix(maxLines ?? ...)`) lives in exactly one place on the owning type. Renderers with `maxLines` views call `clippedLines`; renderers on `maxLines == nil` views may continue calling `wrappedLines` unchanged.

### DISTILL Wave

**D-DISTILL-1: Full InMemory test strategy**
Strategy A (Full InMemory) — pure domain, no I/O driven ports. All tests use stub measurer injected via `LayoutEngine(textMeasurer:)`. No adapters needed (no subprocess, HTTP, or hook entry points).

**D-DISTILL-2: Scaffold approach**
Minimal scaffold: stored-property addition + returning-unclipped-lines `clippedLines` stub. `layoutWrappedTextNode` not modified in scaffold. Results in RED for floor/ceiling height assertions and clipped-count assertions. GREEN immediately for no-clipping cases (correct starting conditions, not gaps).

**D-DISTILL-3: Slice 2 step sizing (accepted)**
Step 01-02 covers 14 scenarios (8 Slice 1 layout + 6 Slice 2 edge cases), exceeding the 8-scenario threshold. Accepted after review: all 14 scenarios test the same 2–3 line change in `layoutWrappedTextNode` (height formula + child prefix). Splitting would be artificial since both invariants emerge from the same formula.

---

## ADR Reference

**ADR-004**: WrappedText maxLines — Renderer Coordination Strategy (Accepted)
- Three options evaluated: A (renderer applies clipping independently), B (new `clippedLines` method), C (change `wrappedLines` signature).
- Selected Option B: `clippedLines` on `WrappedText`. Option A rejected (duplication across renderers). Option C rejected (source-breaking API change, forces double call in engine).
- Migrated to: `docs/adrs/ADR-004-wrappedtext-maxlines-renderer-coordination.md`

---

## Issues Encountered

None blocking. One sizing-review annotation on step 01-02 (scenario count exceeded threshold) — reviewed and accepted with rationale documented in roadmap.json under `sizing_rationale`.

---

## Lessons Learned

1. **Intrinsic property over modifier wrapper**: When an adapter has traversal limitations with modifier wrappers, designing the feature as an intrinsic stored property resolves the issue cleanly and also keeps the public API more readable.

2. **Separate allLines and visibleLines within one call**: The layout engine needing both unclipped count (for height) and clipped lines (for children) is a recurring pattern in bounded layout engines. Having the engine compute both within `layoutWrappedTextNode` avoids double method invocation while keeping `wrappedLines` untouched.

3. **Floor + ceiling as a single formula**: `Float(maxLines ?? allLines.count) * lineHeight` elegantly handles both the floor case (content shorter than maxLines) and ceiling case (content longer than maxLines) without conditional branching. The `??` operator carries all the nil-path semantics.

4. **Scaffold strategy determines RED clarity**: The minimal scaffold (property added, `clippedLines` returns unclipped, `layoutWrappedTextNode` untouched) produced clear RED signals for floor/ceiling tests while leaving no-clipping cases GREEN by design. This prevented false-RED noise in the test run.

---

## Migrated Artifacts

| Artifact | Permanent Location |
|----------|--------------------|
| ADR-004: WrappedText maxLines — Renderer Coordination Strategy | `docs/adrs/ADR-004-wrappedtext-maxlines-renderer-coordination.md` |
| Journey delta visual (max-lines) | `docs/ux/wrapped-text-max-lines/journey-max-lines-visual.md` |

---

## Source Files Modified

- `Sources/GameUI/WrappedText.swift` — added `maxLines: Int?` property, `clippedLines(measurer:maxWidth:)` method
- `Sources/GameUI/LayoutEngine.swift` — extended `layoutWrappedTextNode` with floor+ceiling logic

## Test Files Added

- `Tests/GameUITests/acceptance/WrappedTextMaxLinesSlice1CoreTests.swift` — 14 scenarios (Slice 1 core)
- `Tests/GameUITests/acceptance/WrappedTextMaxLinesSlice2EdgeCaseTests.swift` — 9 scenarios (Slice 2 edge cases)
- 2 unit tests added to `Tests/GameUITests/WrappedTextUnitTests.swift`
