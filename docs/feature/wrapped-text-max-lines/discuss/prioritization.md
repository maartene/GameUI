# Prioritization: wrapped-text-max-lines

## Release Priority

| Priority | Release | Target Outcome | KPI | Rationale |
|----------|---------|---------------|-----|-----------|
| 1 | Slice 01 — Core maxLines | Layout height is stable across all content lengths | KPI-1: All US-04 scenarios green | Delivers the primary stated job. Unblocks SpaceSim narrative screen use case. Validates the riskiest assumption: that `maxLines × lineHeight` as reserved height is the right contract. |
| 2 | Slice 02 — Edge Cases | Any boundary `maxLines` value is safe and predictable | KPI-2: All US-05 scenarios green | Robustness layer required before DELIVER. Edge-case semantics must be defined to avoid implementation ambiguity. Both slices share the same property and function — expected to ship together. |

---

## Backlog

| Story | Release | Priority | Outcome Link | Dependencies |
|-------|---------|----------|-------------|--------------|
| US-04: maxLines Layout Reservation | Slice 01 | P1 | KPI-1 (stable height) | US-01, US-02, US-03 (all merged) |
| US-05: maxLines Edge Cases | Slice 02 | P2 | KPI-2 (boundary safety) | US-04 |

---

## MoSCoW

| Category | Story | Rationale |
|----------|-------|-----------|
| Must Have | US-04 | Core stated requirement; without it the feature has no value |
| Must Have | US-05 | Edge-case semantics required before implementation; `maxLines: 0` and empty-content behaviour must be defined |

---

## Value / Effort

| Story | Value | Effort | Score (V×U/E) | Notes |
|-------|-------|--------|----------------|-------|
| US-04 | 5 | 2 | 12.5 | High value (eliminates layout shift), low effort (single property + one function change) |
| US-05 | 3 | 1 | 15.0 | Medium value, very low effort (natural outcome of `prefix` semantics + one explicit guard) |

Both stories are quick wins. US-04 first because US-05 depends on it.

---

> **Note**: Story IDs (US-04, US-05) continue the sequence from the `wrapped-text` feature (US-01 through US-03).
