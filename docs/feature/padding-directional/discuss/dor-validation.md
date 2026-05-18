# Definition of Ready Validation — padding-directional

## Story: US-PDR-01 — Directional Padding Layout

| DoR Item | Status | Evidence |
|----------|--------|----------|
| 1. Problem statement clear, domain language | PASS | "Alex must nest `.padding()` calls or accept uniform insets — no single-call API for x/y asymmetry" — specific pain, no technical jargon |
| 2. User/persona with specific characteristics | PASS | Alex Reyes — game developer building HUD dialogue boxes; Priya Sharma — letterbox header; Tomás Dvořák — badge edge-case |
| 3. 3+ domain examples with real data | PASS | Three examples with named personas, concrete sizes (100×50, 80×40, 60×40), and specific padding values (x: 20 y: 10, x: 16 y: 0, x: -5 y: 2) |
| 4. UAT scenarios in Given/When/Then (3-7) | PASS | 7 BDD scenarios with concrete dimensions and expected values; within 3-7 range |
| 5. AC derived from UAT | PASS | All 7 AC items trace directly to one of the 7 UAT scenarios |
| 6. Right-sized (1-3 days, 3-7 scenarios) | PASS | Estimated 2-3 hours; 7 scenarios — within bounds |
| 7. Technical notes: constraints/dependencies | PASS | Swift 6.2, no Foundation, Float geometry, dispatch order risk, `outerSizeForPaddedContent` note |
| 8. Dependencies resolved or tracked | PASS | No external dependencies; protocol declaration is the only intra-slice dependency (implementation order) |
| 9. Outcome KPIs defined with measurable targets | PASS | KPI-1 through KPI-4 in outcome-kpis.md; 7/7 AC pass = measurable target |

### DoR Status: PASSED

---

## Story: US-PDR-02 — Hit-Test Traversal Through Directional Padding

| DoR Item | Status | Evidence |
|----------|--------|----------|
| 1. Problem statement clear, domain language | PASS | "hitTestButton returns nil for taps on directional-padded buttons — no AnyDirectionalPaddingModifier branch" — specific observable failure |
| 2. User/persona with specific characteristics | PASS | Alex Reyes wiring pointer input to HUD buttons; Priya Sharma VStack scenario; Tomás Dvořák outside-frame nil scenario |
| 3. 3+ domain examples with real data | PASS | Three examples with named personas, concrete frame positions, tap coordinates, and expected return values |
| 4. UAT scenarios in Given/When/Then (3-7) | PASS | 4 BDD scenarios — within 3-7 range |
| 5. AC derived from UAT | PASS | All 4 AC items trace directly to one of the 4 UAT scenarios |
| 6. Right-sized (1-3 days, 3-7 scenarios) | PASS | Estimated 1 hour implementation + 1.5 hours tests; 4 scenarios — within bounds |
| 7. Technical notes: constraints/dependencies | PASS | `hitTestNode` pattern-match, no changes to `hitTestButton` signature, dispatch order note |
| 8. Dependencies resolved or tracked | PASS | Depends on US-PDR-01 protocol declaration (same slice, implementation order only) |
| 9. Outcome KPIs defined with measurable targets | PASS | KPI-3 (4/4 hit-test AC), KPI-5 (0 false negatives) in outcome-kpis.md |

### DoR Status: PASSED

---

## Slice-Level DoR Check

| Check | Status | Evidence |
|-------|--------|----------|
| All stories in slice have passed individual DoR | PASS | Both US-PDR-01 and US-PDR-02 above |
| Slice has at least one user-visible story | PASS | Both stories are user-facing API changes — `.padding(x:y:)` is directly callable by the game developer |
| No unresolved red cards / open questions | PASS | All design questions resolved in wave-decisions.md; no deferred unknowns |
| Elevator Pitch present in all stories | PASS | Both US-PDR-01 and US-PDR-02 contain Before / After / Decision enabled sections |
| Elevator Pitch references user-invocable entry point | PASS | US-PDR-01: `LayoutEngine.layout(view, in: constraints)` — game developer's primary entry; US-PDR-02: `hitTestButton(view:node:at:)` — game developer's input entry |
| Elevator Pitch "After" describes observable output | PASS | US-PDR-01: `LayoutTree.root.frame.size`; US-PDR-02: button index returned |
| Handoff package complete | PASS | journey visual + YAML + .feature + shared-artifacts-registry + story-map + prioritization + slice-01 brief + user-stories + outcome-kpis + wave-decisions |

### Slice DoR Status: PASSED — Ready for DESIGN wave handoff
