# Prioritization: button-styling

## Release Priority

| Priority | Slice | Target Outcome | KPI Link | Rationale |
|---|---|---|---|---|
| P1 | Walking Skeleton (Slice 01) | Renderer differentiates buttons by tag | KPI-BS-1, KPI-BS-2 | Core capability. Resolves O-1 (score 16) + O-2 (score 17). Single file change, ≤ 0.5 days. No risk. Ships first. |
| P2 | Documentation Convention (Slice 02) | Renderer authors discover tag vocabulary | KPI-BS-3 | Discoverability improvement. Zero runtime risk. Depends on Slice 01 being merged. |

## Backlog

| Story | Slice | Priority | Outcome Link | Dependencies |
|---|---|---|---|---|
| US-BS-01: Tag Property on Button | WS (Slice 01) | P1 | KPI-BS-1, KPI-BS-2 | None |
| US-BS-02: Standard Tag Vocabulary | R1 (Slice 02) | P2 | KPI-BS-3 | US-BS-01 |

> **Note**: Story IDs assigned in Phase 3 (Requirements). Prioritization may be refined after
> outcome-kpis.md is produced. Current scores are estimates.

## Value / Effort Matrix

```
High Value |  US-BS-01 (WS)  |                   |
           |   Quick Win     |                   |
           |                 |                   |
Low Value  |                 |   US-BS-02 (docs) |
           |                 |   Fill-in         |
           +-----------------+-------------------+
                Low Effort          High Effort
```

Both stories are low effort. US-BS-01 is high value (moves north-star KPI). US-BS-02 is low-
medium value (discoverability improvement, no KPI movement on its own).

## Riskiest Assumption

The riskiest assumption is: "Adding `tag` to `AnyButton` does not break any existing renderer
or call site." Mitigation: default value `""` ensures no compilation breakage. Regression
test in Slice 01 verifies layout geometry is tag-invariant.

Slice 01 validates this assumption. Slice 02 can safely follow.
