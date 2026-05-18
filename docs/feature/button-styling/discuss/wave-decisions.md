# Wave Decisions — button-styling DISCUSS

## Wave: DISCUSS
## Date: 2026-05-18
## Agent: nw-product-owner (Luna)

---

## D1: Feature Type
**Decision**: User-facing — game developer API + renderer inspection
**Rationale**: The change surfaces as a new init parameter (`tag:`) visible to game developers and
a new protocol requirement (`AnyButton.tag`) visible to renderer authors. Both audiences are
primary users of this feature.

---

## D2: Walking Skeleton
**Decision**: Brownfield — evaluate existing structure first
**Rationale**: `Button<Content>` and `AnyButton` already exist and are working. The walking skeleton
is the minimum additive change (one property, one protocol requirement, one default parameter) that
enables the end-to-end capability. No new architectural layers needed.
**Walking Skeleton Identified**: Add `tag: String = ""` to `Button<Content>` + `var tag: String { get }`
to `AnyButton`. Single file. ≤ 0.5 days.

---

## D3: UX Research Depth
**Decision**: Lightweight (happy path focus)
**Rationale**: The renderer pattern is already established (`isFocused` precedent). The API shape
is well-understood (same inspection site, same protocol, one new property). A full discovery
conversation would not surface substantially different requirements. Happy path documented;
one error path (missing tag → default) included.

---

## D4: JTBD Analysis
**Decision**: YES — full JTBD analysis performed
**Rationale**: The central tension (tag vs. color injection) required principled resolution.
Three jobs identified; Four Forces analysis for each; Opportunity Scoring for six outcome
statements. Result: Option A (tag) confirmed with O-2 score 17 as the highest-priority outcome.

---

## Critical Design Decision: Option A (Tag) vs. Option B (Color Injection)
**Decision**: Option A — `tag: String` on `AnyButton`
**Resolved By**: JTBD opportunity scoring (see `jtbd-opportunity-scores.md`)
**Key Evidence**:
- O-2 "minimise call-site edits when theme changes" = score 17 (highest). Option B fails O-2.
- O-3 "new roles require no library update" = score 13. Option B eliminates extensibility.
- Content/appearance separation is a core GameUI design principle. Option B breaks it.
- `isFocused` precedent: the existing pattern is `if let btn = view as? AnyButton { use btn.property }`.
  A `tag: String` is the natural extension of this pattern.

---

## Missing DISCOVER/DIVERGE Artifacts
**Risk Noted**: No `recommendation.md`, `job-analysis.md`, `vision.md`, or `project-brief.md`
exist for this feature. JTBD analysis was conducted in DISCUSS wave as compensating control (D4 = YES).
**Mitigation**: Three job stories documented; Four Forces for each; Opportunity Scoring table produced.
Job traceability references embedded in user stories. Risk level: LOW — the problem statement was
unambiguous and the API space is narrow.

---

## Scope Assessment
**Result**: PASS — 2 stories, 1 bounded context, ≤ 1 day total effort
**Walking Skeleton**: Slice 01 (≤ 0.5 days) — tag API
**Release 1**: Slice 02 (≤ 0.25 days) — documentation convention

---

## Handoff Package for DESIGN Wave (solution-architect)

### Artifacts
- `discuss/journey-button-styling-visual.md` — visual journey narrative with ASCII flow
- `discuss/journey-button-styling.yaml` — structured journey schema with Gherkin embedded
- `discuss/journey-button-styling.feature` — Gherkin scenarios for DISTILL wave
- `discuss/story-map.md` — backbone + walking skeleton + release slices
- `discuss/prioritization.md` — priority rationale
- `discuss/user-stories.md` — LeanUX stories with UAT and AC
- `discuss/outcome-kpis.md` — measurable KPIs with baselines
- `discuss/dor-validation.md` — DoR 9-item validation (both stories: PASSED)
- `discuss/shared-artifacts-registry.md` — integration checkpoint registry
- `slices/slice-01-tag-api.md` — Walking Skeleton brief
- `slices/slice-02-documentation.md` — Documentation Convention brief

### Key Design Input for solution-architect
1. `tag: String = ""` is the API shape. Parameter order: `tag:` before `isFocused:` (ODQ-BS-03).
2. File: `Sources/GameUI/LeafViews.swift` only. No other files require changes for US-BS-01.
3. `AnyButton.tag` must be a protocol requirement (not a default extension method) so renderers
   can rely on it being present for any `AnyButton` instance.
4. `String` is chosen over enum for extensibility (Job 3). No newtype needed in GameUI itself.
5. Layout engine must NOT read `tag`. Architectural enforcement: no `tag` reference in
   `LayoutEngine.swift` or `HitTest.swift`.

### SSOT Updates
- `docs/product/journeys/button-styling.yaml` — created (mirrors feature journey schema)
- `docs/product/journeys/button-styling-visual.md` — created (mirrors feature visual journey)
