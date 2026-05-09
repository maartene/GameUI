# Definition of Ready Validation: wrapped-text

Validation date: 2026-05-09

---

## US-01: WrappedText Core Word-Wrap Layout

| DoR Item | Status | Evidence |
|----------|--------|----------|
| 1. Problem statement clear, domain language | PASS | "Riku finds it painful to manually split long strings into fixed-length lines — line lengths change whenever font size or panel width changes." Domain language: HUD panels, WrappedText, LayoutEngine, child LayoutNode. |
| 2. User/persona with specific characteristics | PASS | "Riku Nakamura — game developer building HUD panels and dialogue boxes in Swift using GameUI + Raylib." Role, tool, and context specified. |
| 3. 3+ domain examples with real data | PASS | Example 1: 47-word item description at fontSize 14, maxWidth 200, Raylib measurer → 3 children. Example 2: "Collect 10 herbs" at fontSize 16, maxWidth 300 → 1 child. Example 3: "Go now." at fontSize 20, maxWidth 200 → 1 child (no spurious second line). |
| 4. UAT in Given/When/Then (3–7 scenarios) | PASS | 6 scenarios covering: multi-line split, stacked origins, root height, single-line, View protocol conformance, exact-fit boundary. |
| 5. AC derived from UAT | PASS | All 10 AC items trace directly to UAT scenarios (including determinism AC added post-review). |
| 6. Right-sized (1–3 days, 3–7 scenarios) | PASS | 1 day effort, 5 scenarios. |
| 7. Technical notes: constraints/dependencies | PASS | No Foundation; `body: Never` pattern; greedy algorithm; root width = maxWidth; LayoutEngine branch placement documented. |
| 8. Dependencies resolved or tracked | PASS | No dependencies — greenfield addition. |
| 9. Outcome KPIs defined with measurable targets | PASS | KPI-1: < 30 min to working panel, measured by unit test pass rate and developer integration time. Baseline documented. |

### DoR Status: PASSED

---

## US-02: WrappedText Robustness and Fallback

| DoR Item | Status | Evidence |
|----------|--------|----------|
| 1. Problem statement clear, domain language | PASS | "Without this story, any single-word content wider than maxWidth causes an infinite loop." Domain language: char-count fallback, unbreakable word, greedy loop. |
| 2. User/persona with specific characteristics | PASS | "Riku Nakamura — prototyping without font metrics; production with unusual content (no spaces, empty strings)." Two sub-contexts documented. |
| 3. 3+ domain examples with real data | PASS | Example 1: "Short text for testing fallback" fontSize 10, no measurer, maxWidth 100 → at least 1 child. Example 2: "AncientRelicOfThePast" fontSize 14, maxWidth 50 → 1 child, no loop. Example 3: content "" → 0 children, height 0. |
| 4. UAT in Given/When/Then (3–7 scenarios) | PASS | 4 scenarios: char-count fallback, unbreakable word, empty content, near-zero maxWidth. |
| 5. AC derived from UAT | PASS | All 5 AC items trace to UAT scenarios. |
| 6. Right-sized (1–3 days, 3–7 scenarios) | PASS | 1 day effort, 4 scenarios. |
| 7. Technical notes: constraints/dependencies | PASS | Char-count formula documented; unbreakable word guard; empty string guard; near-zero maxWidth handled by unbreakable word path. Depends on US-01. |
| 8. Dependencies resolved or tracked | PASS | Depends on US-01 (tracked). US-01 is in same feature, same sprint. |
| 9. Outcome KPIs defined with measurable targets | PASS | KPI-2: 0 crashes from boundary inputs, measured by Slice 2 test suite (4 scenarios green). Baseline: crash risk without this story. |

### DoR Status: PASSED

---

## US-03: WrappedText Renderer Guidance

| DoR Item | Status | Evidence |
|----------|--------|----------|
| 1. Problem statement clear, domain language | PASS | "Riku reads LayoutEngine.swift internals to understand how to recover line strings from a WrappedText layout tree. He makes a mistake (re-splitting differently) and some lines are drawn with wrong content." |
| 2. User/persona with specific characteristics | PASS | "Riku Nakamura — game developer extending an existing GameUI renderer integration (Raylib)." Role and specific integration context specified. |
| 3. 3+ domain examples with real data | PASS | Example 1: Raylib renderer `zip(wt.lines, node.children)` pattern. Example 2: SDL2 renderer following same convention. Example 3: empty `WrappedText` → 0 draw calls, no crash. |
| 4. UAT in Given/When/Then (3–7 scenarios) | PASS | 3 scenarios: README coverage, `lines` property access, draw call count. |
| 5. AC derived from UAT | PASS | All 4 AC items trace to UAT scenarios. |
| 6. Right-sized (1–3 days, 3–7 scenarios) | PASS | 0.5 day effort, 3 scenarios. |
| 7. Technical notes: constraints/dependencies | PASS | Open design question documented (Option A vs C); both options' implications noted; dependency on DESIGN wave decision flagged. |
| 8. Dependencies resolved or tracked | PASS | Depends on US-01 (tracked), US-02 (tracked), and DESIGN wave decision on line-string access (tracked in shared-artifacts-registry.md as open design question). |
| 9. Outcome KPIs defined with measurable targets | PASS | KPI-3: < 15 min renderer integration without reading engine source. Measured by developer self-report and README example verification. |

### DoR Status: PASSED (with noted dependency on DESIGN wave decision)

---

## Summary

| Story | DoR Status | Notes |
|-------|-----------|-------|
| US-01 | PASSED | Ready for DESIGN wave |
| US-02 | PASSED | Ready for DESIGN wave; depends on US-01 |
| US-03 | PASSED | Ready for DESIGN wave; BLOCKED on design decision for line-string access — DESIGN wave must resolve before implementation |
