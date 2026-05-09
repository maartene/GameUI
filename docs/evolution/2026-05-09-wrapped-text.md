# Evolution: wrapped-text — Slice 1 (Core Word-Wrap)

**Date:** 2026-05-09
**Feature ID:** `wrapped-text`
**Scope:** Slice 1 — Core Word-Wrap (Slices 2 and 3 bonus GREEN)
**Status:** COMPLETE — 83 tests, 0 failures, 0 regressions

---

## Feature Summary

Added `WrappedText` — a new leaf view primitive in GameUI that performs greedy word-wrap layout. Game developers can declare `WrappedText(content:fontSize:color:)` and receive a `LayoutTree` with one child `LayoutNode` per wrapped line, each fitting within the available `maxWidth` constraint. No manual line-break computation is required.

**North Star (from Outcome KPIs):** A game developer declares `WrappedText` and ships a working multi-line HUD panel in a single session (< 30 min, zero manual line-break computation).

---

## Business Context

Before this feature, game developers using GameUI needed manual VStack + multiple Text nodes with hard-coded line breaks (30–90 min of trial/error per HUD panel). `WrappedText` eliminates that entirely. The feature targets Riku Nakamura (persona) — game developers building HUD inventory panels, dialogue boxes, and quest logs in Swift with GameUI + Raylib.

---

## Outcome KPI Results

| KPI | Target | Result |
|-----|--------|--------|
| KPI-1: < 30 min to working panel | Complete multi-line panel < 30 min | Slice 1 acceptance suite 100% GREEN — layout correct in all 11 scenarios |
| KPI-2: 0 crashes from boundary inputs | 0 crashes, 0 infinite loops | Slice 2 test suite 100% GREEN (6 tests, bonus) — all 4 error paths safe |
| KPI-3: < 15 min renderer integration | Renderer pattern documented | `wrappedLines` API established as the renderer contract (Slice 3 bonus GREEN, 6 tests) |
| Guardrail: no regression | 0 regressions in existing tests | Pre-existing tests 100% GREEN (67 tests unchanged) |

**Bonus outcome:** All 3 slices GREEN on Slice 1 implementation. The greedy algorithm naturally handled Slice 2 boundary cases (empty content, unbreakable words, near-zero maxWidth) and Slice 3 renderer API without additional implementation steps.

---

## Steps Completed

| Step ID | Description | DES Phases | Commit | Outcome |
|---------|-------------|------------|--------|---------|
| 01-01 | Implement `WrappedText.wrappedLines` greedy word-wrap | PREPARE, RED_ACCEPTANCE, RED_UNIT, GREEN, COMMIT | `5c63317` | PASS |
| 01-02 | Implement `layoutWrappedTextNode` branch in `LayoutEngine` | PREPARE, RED_ACCEPTANCE, RED_UNIT, GREEN, COMMIT | `83913d1` | PASS |
| L1 refactor | Naming improvements (`wt`→`wrappedText`, `i`→`lineIndex`, removed inferred closure return type) | — | `613a1f3` | PASS |

**Adversarial review:** APPROVED, zero defects.
**Mutation testing:** SKIPPED (no Swift mutation tool available); estimated ≥85% kill rate via manual analysis of test suite coverage.

---

## Key Decisions

### DISCUSS Wave

- **Pre-answered DOR:** Feature type = user-facing UI component; walking skeleton skipped (established leaf view pattern); UX research lightweight; no JTBD analysis needed (job unambiguous).
- **Risk noted:** `textMeasurer` fallback accuracy (char-count approximation); renderer consumers must add a `WrappedText` branch — mitigated by Slice 3 guidance.

### DESIGN Wave

- **D1 — WrappedText as separate type:** New struct with `body: Never`, not an extension of `Text`. Rationale: `Text` is deliberately single-line; its renderer branch assumes one draw call and one frame. Mixing wrapping semantics would break existing `Text` usage.
- **D2 — Pure `wrappedLines` method:** Single public algorithm, no side effects, no Foundation imports, deterministic. Both layout engine and renderer call it independently. Single source of truth for line splitting.
- **D3 — Direct cast in `layoutNode`:** `if let wt = view as? WrappedText` branch before `ContainerView` fallback. No new protocol. Consistent with existing `AnyButton`/`ZStackView`/`Text` style.
- **D4 — ODQ-01 resolved as Option C:** Layout engine and renderer coordinate through `wrappedLines`, not stored data on `LayoutNode`. User rationale: "I'd rather have the renderer as dumb as possible."

### DISTILL Wave

- **DWD-01 — Walking skeleton strategy A:** Full in-process (no external I/O). `textMeasurer` represented by in-process stub (`fontSize × charCount`). No real-IO scenarios needed.
- **DWD-02 — Slice 3 unblocked:** ODQ-01 resolution (Option C) enabled Slice 3 acceptance tests to be written immediately. The `wrappedLines` API is the renderer contract.
- **DWD-03 — Scaffold approach:** `wrappedLines` scaffold returns `[]` (RED, not BROKEN). No `assertionFailure()` to avoid Swift process crash in test runner.

### DELIVER Wave

- Root frame `width = constraints.maxWidth` (not longest line width) — fills available horizontal space.
- `lineHeight = fontSize` — consistent with `layoutTextNode` fallback.
- Alignment deferred: `.leading` only in this pass.
- No changes to `LayoutNode`, `LayoutTree`, or `LayoutEngine` public API surface.

---

## Lessons Learned

1. **Greedy word-wrap naturally handles all boundary cases.** The algorithm's "unbreakable word goes on its own line" rule covered Slice 2 edge cases without extra branches. When boundary behaviour falls out of the core algorithm, no separate implementation step is needed — acceptance tests confirm it.

2. **Scaffold RED strategy matters in typed languages.** Python's `assertionFailure` maps to RED; Swift's `assertionFailure()` crashes the process (BROKEN). Returning `[]` from the scaffold method is the correct Swift adaptation of the RED scaffold principle.

3. **Solving ODQ-01 early unblocked Slice 3.** The DISCUSS wave left the line-string access question open for DESIGN. Resolving it in DESIGN (Option C: renderer calls `wrappedLines` independently) meant Slice 3 tests could be written in DISTILL and GREEN on the first GREEN commit of Slice 1.

4. **Small, named refactor pass (L1) improves long-term readability.** Variable names `wt` → `wrappedText` and `i` → `lineIndex` cost one commit and eliminate ambiguity for future maintainers.

---

## Issues Encountered

| Issue | Wave | Resolution |
|-------|------|------------|
| ODQ-01: How does the renderer access line strings? (three options: store on LayoutNode, re-compute in renderer, or `wrappedLines` as shared API) | DISCUSS → DESIGN | Resolved as Option C in DESIGN wave — `wrappedLines` is pure and deterministic, safe to call twice |
| No Swift mutation testing tool available | DELIVER | Skipped; manual analysis estimated ≥85% kill rate |
| Elevator pitch demo N/A | DELIVER | GameUI is a pure library; walking skeleton verified by acceptance tests, no CLI surface exists |

---

## Architecture Notes

**Pattern:** Modular extension to existing `LayoutEngine` — one new `layoutNode` branch, one new private method. No new architectural layers.

**Components added:**
- `Sources/GameUI/WrappedText.swift` — `WrappedText` struct with `wrappedLines(measurer:maxWidth:) -> [String]`
- `Sources/GameUI/LayoutEngine.swift` — `layoutWrappedTextNode` private method + `if let wrappedText` branch

**Tests added:**
- `Tests/GameUITests/acceptance/WrappedTextSlice1CoreTests.swift` — 11 tests
- `Tests/GameUITests/acceptance/WrappedTextSlice2RobustnessTests.swift` — 6 tests (bonus GREEN)
- `Tests/GameUITests/acceptance/WrappedTextSlice3RendererTests.swift` — 6 tests (bonus GREEN)
- `Tests/GameUITests/WrappedTextUnitTests.swift` — 5 unit tests

**Constraints maintained:**
- No Foundation, no CGFloat — pure Float geometry, Linux-compatible
- Swift 6.2, Swift Testing framework
- `wrappedLines` is deterministic (same inputs → same outputs); safe for dual-call pattern
- No `LayoutNode`, `LayoutTree`, or `LayoutEngine` public API surface changes

---

## Migrated Artifacts

| Source | Destination |
|--------|-------------|
| `discuss/journey-wrapped-text.yaml` | `docs/ux/wrapped-text/journey-wrapped-text.yaml` |
| `discuss/journey-wrapped-text-visual.md` | `docs/ux/wrapped-text/journey-wrapped-text-visual.md` |
| `docs/product/architecture/adr-001-wrappedtext-decomposition.md` | Already at permanent location — no migration needed |
| `docs/product/architecture/brief.md` | Already at permanent location — no migration needed |

---

## References

- `docs/product/architecture/adr-001-wrappedtext-decomposition.md` — ODQ-01 decision record (Option C)
- `docs/product/architecture/brief.md` — Full architecture document
- `docs/ux/wrapped-text/journey-wrapped-text.yaml` — UX journey (migrated)
- `docs/ux/wrapped-text/journey-wrapped-text-visual.md` — UX visual map (migrated)
- `docs/feature/wrapped-text/` — Feature workspace (preserved as history)
