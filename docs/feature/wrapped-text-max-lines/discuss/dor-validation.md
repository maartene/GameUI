# Definition of Ready Validation: wrapped-text-max-lines

## Story: US-04

| DoR Item | Status | Evidence |
|----------|--------|----------|
| Problem statement clear, domain language | PASS | "Riku finds it painful to express 'reserve space for 3 lines' because the workaround buries intent in pixel math and breaks when font size changes." Domain terms: `WrappedText`, `maxLines`, `lineHeight`, narration area, HUD panel. |
| User/persona with specific characteristics | PASS | Riku Nakamura, game developer building SpaceSim narrative screens. Context: fixed-area body text, variable narration length. |
| 3+ domain examples with real data | PASS | Example 1: "Battle stations!" (1 line, floor), Example 2: "The station's emergency klaxon..." (5 lines, ceiling), Example 3: `maxLines: nil` (existing behaviour, no regression). All use real content and concrete numbers. |
| UAT scenarios in Given/When/Then (3–7 scenarios) | PASS | 5 scenarios: floor, ceiling, exact fit, nil (regression), stability across varying content. All in Given/When/Then. All scenario titles express user-observable outcomes, not implementation details. |
| AC derived from UAT | PASS | 8 AC items, each traceable to a UAT scenario. Observable outcomes only (frame dimensions, child counts). No implementation prescriptions. |
| Right-sized (1–3 days, 3–7 scenarios) | PASS | Estimated 1 day. 5 scenarios. Single demo-able behaviour: stable height. |
| Technical notes: constraints/dependencies | PASS | Intrinsic property constraint documented (test seam note). `lineHeight` source documented. Implementation sketch in Technical Notes section. Dependencies on US-01–03 explicit. |
| Dependencies resolved or tracked | PASS | US-01, US-02, US-03 all merged (per git history: `wrapped-text` feature is DELIVER-complete). No external dependencies. |
| Outcome KPIs defined with measurable targets | PASS | KPI-1: all US-04 UAT scenarios green (100% pass rate). Baseline: pixel-math workaround. Measurement: CI test run at Slice 01 merge. |

### DoR Status: PASSED

---

## Story: US-05

| DoR Item | Status | Evidence |
|----------|--------|----------|
| Problem statement clear, domain language | PASS | "Riku needs `maxLines: 0` and `maxLines: 1` to behave safely; needs empty content with `maxLines` to still reserve height." Domain terms: zero-height, hidden panel, single-line status. |
| User/persona with specific characteristics | PASS | Riku Nakamura, same persona. Context: hidden/collapsed narration areas, single-line status line, empty-content fade-in state. |
| 3+ domain examples with real data | PASS | Example 1: `maxLines: 0` (hidden panel, fade-in not triggered), Example 2: `maxLines: 1` + long status string (single-line clip), Example 3: `maxLines: 3` + `content: ""` (reserved empty area). All use realistic SpaceSim context. |
| UAT scenarios in Given/When/Then (3–7 scenarios) | PASS | 4 scenarios: zero height, single-line clip, empty content floor, unbreakable word with `maxLines: 1`. All in Given/When/Then. |
| AC derived from UAT | PASS | 6 AC items, each traceable to a UAT scenario. All observable (frame dimensions, child counts, no-crash). |
| Right-sized (1–3 days, 3–7 scenarios) | PASS | Estimated 0.5 days. 4 scenarios. Single demo-able behaviour: boundary safety. |
| Technical notes: constraints/dependencies | PASS | `prefix(0)` natural behaviour noted. Empty-content height guard documented explicitly. Depends on US-04. |
| Dependencies resolved or tracked | PASS | Depends on US-04 (Slice 01). US-04 is in the same sprint and must be merged first. Tracked in prioritization.md. |
| Outcome KPIs defined with measurable targets | PASS | KPI-2: all US-05 UAT scenarios green (0 crashes from boundary inputs). Baseline: undefined behaviour for `maxLines: 0`. Measurement: CI test run at Slice 02 merge. |

### DoR Status: PASSED

---

## Anti-Pattern Review

| Anti-Pattern | Checked | Finding |
|---|---|---|
| Implement-X titles | PASS | US-04 title: "WrappedText maxLines Layout Reservation" (user outcome). US-05 title: "WrappedText maxLines Edge Cases" (domain behaviour). |
| Generic data | PASS | "Battle stations!", "The station's emergency klaxon...", "AncientRelicOfThePast", "Shields at 42%..." — real SpaceSim/game content. |
| Technical AC | PASS | All AC state observable frame dimensions and child counts. No "use prefix()" or "use Int?" prescriptions. |
| Technical scenario titles | PASS | No class names, method names, or protocol names in scenario titles. All titles describe user-observable outcomes. |
| Oversized stories | PASS | US-04: 5 scenarios, ~1 day. US-05: 4 scenarios, ~0.5 days. Both well within 3–7 scenario and 1–3 day bounds. |
| Abstract requirements | PASS | All requirements have 3+ concrete domain examples with real content and numeric targets. |

---

## Scope Assessment: PASS

2 user stories, 1 bounded context (GameUI WrappedText + LayoutEngine), estimated 1.5 days total.
