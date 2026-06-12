# Distill Decisions — wrapped-text-max-lines

## Date
2026-06-12

## Wave Decision Reconciliation

**Result: 0 contradictions — proceed**

| DISCUSS decision | DESIGN decision | Status |
|---|---|---|
| `maxLines` must be intrinsic to `WrappedText` (not a `.frame()` modifier) | D6: `maxLines: nil` default via Swift default parameter, single init site | ALIGNED |
| Height formula: `maxLines × lineHeight` (floor + ceiling) | D3: `Float(maxLines ?? allLines.count) * lineHeight` | ALIGNED |
| `maxLines: 0` → zero-height, 0 children (valid; natural outcome of `prefix(0)`) | Confirmed: no special guard needed | ALIGNED |
| `clippedLines(measurer:maxWidth:)` is the renderer-facing API | D4: second pure method on `WrappedText`; ADR-004 accepted | ALIGNED |
| Walking skeleton: skipped (brownfield, established pattern) | No WS decision in DESIGN (consistent skip) | ALIGNED |

No DEVOPS artifacts found — using default environment matrix.

## DWD-01: Walking Skeleton Strategy — Skipped

Pre-answered in DISCUSS wave-decisions.md. This is a brownfield leaf-view extension; the WrappedText + LayoutEngine integration path is fully validated by the existing wrapped-text Slice 1–3 acceptance suites. No new walking skeleton is warranted.

Effective test strategy: **Strategy A (Full InMemory)** — pure domain, no I/O driven ports. All tests use stub measurer injected via `LayoutEngine(textMeasurer:)`.

## DWD-02: Scaffold Approach

Scaffold is minimal: stored-property addition + returning-unclipped-lines `clippedLines` stub.

| Scaffold change | File | Effect on tests |
|---|---|---|
| `maxLines: Int?` stored property + updated init | `Sources/GameUI/WrappedText.swift` | Tests compile; `layoutWrappedTextNode` ignores `maxLines` → wrong height/count → RED |
| `clippedLines` returns `wrappedLines` (unclipped) | `Sources/GameUI/WrappedText.swift` | Tests asserting clipped count fail → RED |
| `layoutWrappedTextNode` NOT modified | `Sources/GameUI/LayoutEngine.swift` | Floor/ceiling height assertions fail → RED |

**RED evidence (representative):**
- Floor test: 1-line content, `maxLines: 3` → scaffold height = `1 × 22 = 22` ≠ expected `66.0` → RED
- Ceiling test: 5-line content, `maxLines: 3` → scaffold produces 5 children ≠ expected 3 → RED
- `maxLines: 0` test: scaffold produces 1 child ≠ expected 0 → RED
- `clippedLines` ceiling test: scaffold returns 5 strings ≠ expected 3 → RED

**GREEN immediately (by design):** scenarios where `allLines.count == maxLines` (no clipping case, regression guards, unbreakable-word safety). These are correct starting conditions, not implementation gaps.

## DWD-03: Adapter Coverage

No driven adapters in this feature. `LayoutEngine.layout(_:in:)` is a pure function call (in-process). No subprocess, HTTP, or hook entry points. Adapter coverage table: N/A.

## Test Files Produced

| File | Slice | Driving port | Stories |
|---|---|---|---|
| `Tests/GameUITests/acceptance/WrappedTextMaxLinesSlice1CoreTests.swift` | Slice 01 | `LayoutEngine.layout` + `clippedLines` | US-04 |
| `Tests/GameUITests/acceptance/WrappedTextMaxLinesSlice2EdgeCaseTests.swift` | Slice 02 | `LayoutEngine.layout` + `clippedLines` | US-05 |

## Scenario Count

- Slice 1: 14 scenarios (8 layout, 5 `clippedLines` renderer contract, 1 property storage)
- Slice 2: 9 scenarios (6 layout, 3 `clippedLines` edge cases)
- Total: 23 scenarios
