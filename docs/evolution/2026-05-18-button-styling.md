# Evolution: button-styling

**Date**: 2026-05-18
**Feature ID**: button-styling
**Status**: COMPLETE

---

## Feature Summary

Added `tag: String` semantic metadata to the `AnyButton` protocol and `Button<Content>` struct,
enabling game developers to declare a button's visual role at the call site and differentiate
it in their renderer without per-screen duplication or text-inspection hacks.

**Scope**: Single file — `Sources/GameUI/LeafViews.swift`.
**Test file**: `Tests/GameUITests/acceptance/ButtonTagTests.swift`.
**Result**: 129 tests passing. Adversarial review: APPROVED.

---

## Business Context

Persona: Riku Nakamura — game developer building SpaceSim menus with multiple button roles
(primary, secondary, destructive) that all rendered identically before this feature.

**North Star (KPI-BS-2)**: A theme-color change across all 12 SpaceSim screens requires editing
exactly 1 switch case in the renderer — 0 call-site changes. This was impossible before the tag.

**OKR contribution**:
- Game developers can differentiate >= 3 button roles in a single renderer switch (no per-screen duplication)
- New renderer authors discover standard tag vocabulary from Xcode Quick Help in < 10 minutes

**Guardrail upheld (KPI-BS-4)**: All existing `Button()` call sites compile without modification.
Tag defaults to `""` — brownfield code requires zero migration.

---

## Key Decisions

### D1: Feature Type
**Decision**: User-facing — game developer API and renderer inspection protocol.
**Rationale**: `tag:` surfaces as a new init parameter for game developers and a new protocol
requirement for renderer authors. Both are primary audiences.

### D2: Walking Skeleton
**Decision**: Brownfield — additive change to existing structures.
**Rationale**: `Button<Content>` and `AnyButton` already exist. The skeleton is the minimum
additive change: one property, one protocol requirement, one default parameter. No new
architectural layers needed. Estimated and delivered in <= 0.5 days.

### D3: UX Research Depth
**Decision**: Lightweight (happy path focus).
**Rationale**: The renderer inspection pattern is established (`isFocused` precedent). The API
shape was well-understood — same inspection site, same protocol, one new property. Full discovery
would not have surfaced different requirements.

### D4: JTBD Analysis
**Decision**: Full JTBD analysis performed despite lightweight UX depth.
**Rationale**: The central design tension (tag vs. color injection) required principled resolution.
Three jobs identified; Four Forces analysis per job; Opportunity Scoring for six outcome
statements. O-2 "minimise call-site edits when theme changes" = score 17 (highest). Option A (tag)
confirmed.

### Critical Design Choice: Option A (tag: String) vs. Option B (Color Injection)
**Decision**: Option A — `tag: String` on `AnyButton`.
**Evidence**:
- O-2 "minimise call-site edits when theme changes" = score 17. Option B fails O-2.
- O-3 "new roles require no library update" = score 13. Option B eliminates extensibility.
- Content/appearance separation is a core GameUI design principle. Option B breaks it.
- `isFocused` precedent: the existing pattern is `if let btn = view as? AnyButton { use btn.property }`.
  A `tag: String` is the natural extension.

### API Shape
**Decision**: `tag: String = ""` placed before `isFocused:` in the parameter list (ODQ-BS-03).
**Rationale**: Preserves backwards compatibility; both parameters have defaults. `String` chosen
over enum for extensibility — Job 3 requires no library update for new roles.

### Architectural Constraint
**Decision**: Layout engine must NOT read `tag`. Enforced by convention and regression test.
**Rationale**: Tag is passenger metadata for renderers. The layout test asserts that any tag
value produces identical frame geometry.

---

## Steps Completed

| Step | Name | Result |
|------|------|--------|
| 01-01 | Add tag: String to AnyButton and Button with traversal tests | PASS |
| 01-02 | Add doc comment to AnyButton.tag with standard vocabulary test | PASS |

**Phase**: 01 — Tag API (2 steps)
**Phases**: 1
**Total steps**: 2

### Step Detail

**01-01** (PREPARE → RED_ACCEPTANCE → RED_UNIT → GREEN → COMMIT — all PASS)
Extended `AnyButton` protocol with `var tag: String { get }`. Added `let tag: String` stored
property and `tag: String = ""` init parameter to `Button<Content>`. Acceptance tests verified
tag storage, default value, protocol access, layout invariance, isFocused orthogonality, and
tag traversal through `PaddingModifier` and `ContainerView`.

**01-02** (PREPARE → RED_ACCEPTANCE → RED_UNIT:SKIPPED/NOT_APPLICABLE → GREEN → COMMIT)
Added triple-slash doc comment above `var tag: String { get }` naming four standard values
(`""`, `"primary"`, `"secondary"`, `"destructive"`) and stating any String is valid. RED_UNIT
skipped: the custom tag round-trip test passes from 01-01 implementation; no additional unit
RED was possible for a doc comment step.

---

## Lessons Learned

1. **JTBD at narrow scope pays off**: Even for a single-property addition, the tension between
   tag (metadata) and color injection (state) warranted formal opportunity scoring. O-2 score 17
   gave the team a defensible, documented rationale rather than a convention argument.

2. **isFocused precedent reduces friction**: Having an established pattern (protocol property
   inspected via existential cast) meant the API shape was unambiguous. New features in GameUI
   benefit from documenting these patterns as explicit precedents.

3. **Default values as brownfield contracts**: `tag: String = ""` is the pattern for additive
   protocol requirements in this codebase. The empty string default is not incidental — it is
   the backward-compatibility guarantee. Document defaults in the doc comment (done in 01-02).

4. **Doc comment step as its own slice**: Treating documentation as a separate step (01-02)
   with its own acceptance criterion (doc comment text and round-trip test) ensures it is not
   dropped under time pressure. The test for a non-standard custom tag value is the acceptance
   gate for the open-ended contract.

5. **Mutation testing skipped by strategy**: Per CLAUDE.md `per-feature` strategy, Muter is not
   reliably available in this environment. Mutation testing was skipped per documented exception.

---

## Issues Encountered

No blocking issues. One SKIPPED phase:
- 01-02 RED_UNIT: NOT_APPLICABLE — custom tag test passes from 01-01 implementation; no
  additional unit RED possible for a pure doc comment step. This is expected for documentation
  slices.

---

## Migrated Permanent Artifacts

| Artifact | Permanent Location |
|----------|-------------------|
| `discuss/journey-button-styling.yaml` | `docs/ux/button-styling/journey-button-styling.yaml` |
| `discuss/journey-button-styling-visual.md` | `docs/ux/button-styling/journey-button-styling-visual.md` |

Note: No design/architecture docs, ADRs, or distill/walking-skeleton existed for this feature —
the solution was an additive single-file change requiring no separate architecture document.
The SSOT journeys were written directly to `docs/product/journeys/` during DISCUSS wave and
require no migration (already in permanent location).

---

## Production File Changed

- `Sources/GameUI/LeafViews.swift` — `AnyButton` protocol and `Button<Content>` struct extended
- `Tests/GameUITests/acceptance/ButtonTagTests.swift` — acceptance test suite created
