# Prioritization: wrapped-text

## Release Priority

| Priority | Slice | Target Outcome | KPI | Rationale |
|----------|-------|---------------|-----|-----------|
| 1 | Slice 1: Core Word-Wrap | Developer gets correct per-line child nodes with injected measurer | Developer completes working multi-line HUD panel in one session | Validates core assumption; nothing else works without it |
| 2 | Slice 2: Robustness & Fallback | Edge inputs do not crash or loop; char-count fallback works | 100% of error-path scenarios pass | Prevents production crashes; low effort, high reliability value |
| 3 | Slice 3: Renderer Guidance | Developer can integrate custom renderer without reading engine source | README example covers WrappedText case | Depends on design decision from DESIGN wave on line-string access |

## Value / Effort Matrix

| Story | Value (1-5) | Urgency (1-5) | Effort (1-5) | Score (V×U/E) | Priority |
|-------|-------------|--------------|-------------|----------------|----------|
| US-01: WrappedText View + Layout (Slice 1) | 5 | 5 | 2 | 12.5 | P1 |
| US-02: Robustness & Fallback (Slice 2) | 4 | 4 | 2 | 8.0 | P2 |
| US-03: Renderer Guidance (Slice 3) | 3 | 2 | 1 | 6.0 | P3 |

## Backlog

| Story | Slice | MoSCoW | Outcome Link | Dependencies |
|-------|-------|--------|-------------|--------------|
| US-01 | Slice 1 | Must Have | KPI-1: working multi-line HUD panel | None |
| US-02 | Slice 2 | Must Have | KPI-2: zero crash from edge inputs | US-01 |
| US-03 | Slice 3 | Should Have | KPI-3: renderer integration without source-reading | US-01, DESIGN wave design decision |

> **Note**: Story IDs are assigned here in Phase 2.5 and confirmed in Phase 4 (user-stories.md). Revisit if stories are split or merged.

## Riskiest Assumption

The riskiest assumption is that the greedy word-wrap algorithm produces layout output that downstream renderers can consume correctly — specifically that the renderer has access to the per-line strings. This is the **open design question** identified in shared-artifacts-registry.md. Slice 3 depends on the DESIGN wave resolving it. Slices 1 and 2 are independent of this choice.
