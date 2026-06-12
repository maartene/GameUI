# Wave Decisions: wrapped-text-max-lines

## Feature
`wrapped-text-max-lines` — Add `maxLines: Int?` parameter to `WrappedText` to reserve a fixed vertical area regardless of actual line count.

## Date
2026-06-12

## Pre-Answered Decisions

| # | Decision | Answer | Rationale |
|---|----------|--------|-----------|
| 1 | Feature type | User-facing (UI component) | Extends the GameUI declarative DSL |
| 2 | Walking skeleton | Skipped | Brownfield; leaf-view pattern is established via wrapped-text feature |
| 3 | UX research depth | Lightweight | Behaviour fully specified in feature request; no ambiguity |
| 4 | JTBD analysis | Skipped | Job is unambiguous: reserve a fixed vertical area for variable-length narrative text so surrounding layout elements never jump |

## Prior Wave Context

DIVERGE artifacts are not present for this feature. The job statement is grounded directly in the feature request and backed by the existing `wrapped-text` journey SSOT. Risk: LOW — the job and acceptance criteria are explicit in the request. Noted here per DoR item 8.

## Risks Noted

| Risk | Severity | Mitigation |
|------|----------|------------|
| No DIVERGE recommendation present | LOW | Job is explicit and unambiguous; grounded in feature request and prior wrapped-text SSOT |
| `RecordingGameUIAdapter` traversal limitation with FrameModifier | HIGH | Mitigated by design constraint: `maxLines` MUST be intrinsic to `WrappedText`, not a wrapper modifier. This avoids the traversal issue entirely. |
| `maxLines: 0` semantics | MEDIUM | Treated as "zero-height reserved area": 0 children, `frame.size.height == 0`. Documented explicitly in US-05 edge cases. |
| Clip behaviour (ceiling) with exact multiples | LOW | When content wraps to exactly `maxLines`, no clipping occurs. Test explicitly in UAT scenarios. |

## Scope Assessment

PASS — 2 user stories, 1 bounded context (`GameUI` WrappedText + LayoutEngine), estimated 1–2 days total.

## Architecture Notes (carry into DESIGN wave)

- `maxLines: Int?` added as an optional property on `WrappedText` struct (default `nil`)
- `layoutWrappedTextNode` computes `lines` via existing greedy algorithm, then clips to `maxLines` when non-nil
- Reserved height = `maxLines * lineHeight` regardless of actual line count (floor + ceiling)
- When `maxLines == nil`, behaviour is identical to current implementation (sizes to content)
- `maxLines` must be intrinsic — NOT implemented as a `.frame(height:)` modifier
- No Foundation, no CGFloat, pure Swift 6.2 + `Float` geometry
- No new dependencies
