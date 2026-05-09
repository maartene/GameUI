# DISTILL Decisions — wrapped-text

## Date
2026-05-09

## Prior Wave Reading Checklist

| Artifact | Status |
|---|---|
| `docs/product/journeys/wrapped-text.yaml` | ✓ Read |
| `docs/product/architecture/brief.md` | ✓ Read |
| `docs/product/kpi-contracts.yaml` | ✗ Not found — KPI behaviors taken from per-story outcome KPIs in user-stories.md |
| `docs/feature/wrapped-text/discuss/user-stories.md` | ✓ Read |
| `docs/feature/wrapped-text/discuss/story-map.md` | ✓ Read |
| `docs/feature/wrapped-text/discuss/wave-decisions.md` | ✓ Read |
| `docs/feature/wrapped-text/design/wave-decisions.md` | ✓ Read |
| `docs/feature/wrapped-text/spike/` | ✗ Not found — no spike run |
| `docs/feature/wrapped-text/devops/` | ✗ Not found — using default environment matrix |

**DEVOPS missing** — Log: "DEVOPS artifacts missing — using default environment matrix."

---

## Wave Decision Reconciliation

| DISCUSS Decision | DESIGN Decision | Status |
|---|---|---|
| `WrappedText` conforms to `View` with `body: Never` | DESIGN D1 confirms: separate struct, `body: Never` | ✓ CONSISTENT |
| `LayoutEngine.layoutNode` gets a `WrappedText` branch | DESIGN D3 confirms: direct cast `if let wt = view as? WrappedText` | ✓ CONSISTENT |
| ODQ-01 (line-string access) deferred to DESIGN wave | DESIGN D4 resolves: Option C — `wt.wrappedLines(measurer:maxWidth:)` called by renderer | ✓ RESOLVED — no contradiction |

**Reconciliation passed — 0 contradictions.**

---

## DWD-01: Walking Skeleton Strategy

**Decision**: Strategy A — Full In-Process (no external I/O)

**Rationale**: `WrappedText` is a pure Swift library feature. The only "adapter" is the injected `textMeasurer` closure, which is represented by an in-process stub (`width = fontSize × charCount`). No filesystem, network, subprocess, or paid API is involved. Strategy A is correct.

**Story map pre-answered**: Walking skeleton is skipped — the leaf view pattern is established. The minimum demonstrable slice (Slice 1, first test) proves compilation and runtime non-crash.

**Tagging**: All tests use `@testable import GameUI` with in-process stub measurer. No `@real-io` or `@requires_external` tags needed.

---

## DWD-02: Slice 3 Unblocked

**Decision**: Slice 3 (Renderer Guidance) is no longer blocked.

**Rationale**: DESIGN wave resolved ODQ-01 as Option C. The acceptance criterion for US-03 was updated: "The renderer calls `wt.wrappedLines(measurer:maxWidth:)` and zips the result with `node.children`; each element of the zip produces one draw call." Slice 3 acceptance tests are included in this DISTILL wave.

**Note**: The README documentation AC ("README Raylib integration example includes a WrappedText pattern-match branch") is a manual documentation gate and is not covered by automated tests. Verify by inspection before DELIVER completion.

---

## DWD-03: Scaffold Approach for Swift

**Decision**: `WrappedText.wrappedLines(measurer:maxWidth:)` scaffold returns `[]`. No crash, RED tests.

**Rationale**: The nWave Mandate 7 principle adapted to Swift: scaffold methods must return values that cause tests to fail (RED), not crash (BROKEN). In Python, `assertionFailure` maps to RED. In Swift, `assertionFailure()` crashes the process → BROKEN. Returning `[]` from `wrappedLines` produces RED tests: count assertions fail, string equality assertions fail.

**Scaffold marker**: `// SCAFFOLD: true` comment in `Sources/GameUI/WrappedText.swift`.

**Detect remaining scaffolds during DELIVER**:
```
grep -r "SCAFFOLD: true" Sources/
```

---

## Adapter Coverage Table

| "Adapter" | @real-io scenario | Status |
|---|---|---|
| `textMeasurer` closure (injected) | Stub measurer (`fontSize × charCount`) used in all Slice 1/2/3 tests | ✓ Covered |
| `textMeasurer` absent (nil) | Explicit test in Slice 2: "char-count fallback when no measurer is injected" | ✓ Covered |

No external adapters in this feature. `WrappedText` is a pure library component.

---

## Self-Review Checklist

- [x] 1. WS strategy declared (DWD-01: Strategy A)
- [x] 2. All tests use in-process stub measurer (Strategy A)
- [x] 3. No external adapters; `textMeasurer` injection tested in both present and nil cases
- [x] 4. InMemory doubles: stub measurer cannot model proportional fonts or kerning (acceptable for layout algorithm verification)
- [x] 5. No container needed (pure library, no services)
- [x] 6. All production modules imported by tests have scaffold files (`WrappedText.swift`)
- [x] 7. Scaffold includes `// SCAFFOLD: true` marker
- [x] 8. Scaffold `wrappedLines` returns `[]` (RED, not BROKEN — no assertionFailure crash in Swift)
- [x] 9. Tests are RED (not BROKEN) — verified by running `swift test`: 16 failures, 0 crashes
- [x] 10. Driving port is `LayoutEngine.layout(_:in:)` — all Slice 1/2 tests invoke it; Slice 3 also tests `wrappedLines` directly
- [x] 11. `textMeasurer` (only "adapter") covered with real injection in Slice 1/2 and nil in Slice 2

---

## Red Gate Snapshot

```
swift test 2026-05-09:

Suite "WrappedText — Core Word-Wrap"                     8 failures / 0 crashes
Suite "WrappedText — Robustness and Fallback"            5 failures / 0 crashes
Suite "WrappedText — Renderer Guidance (wrappedLines)"   3 failures / 0 crashes

Total new failures: 16
Pre-existing tests: all GREEN (0 regressions)
```

All 16 failures are RED (assertion failures on wrong values). Zero BROKEN tests.

---

## Outputs Created

```
Sources/GameUI/WrappedText.swift                                  — RED scaffold (SCAFFOLD: true)

Tests/GameUITests/acceptance/WrappedTextSlice1CoreTests.swift     — Slice 1: core word-wrap (11 tests)
Tests/GameUITests/acceptance/WrappedTextSlice2RobustnessTests.swift — Slice 2: robustness (6 tests)
Tests/GameUITests/acceptance/WrappedTextSlice3RendererTests.swift — Slice 3: renderer API (6 tests)

docs/feature/wrapped-text/distill/wave-decisions.md              — this file
```
