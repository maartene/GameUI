# Wave Decisions: wrapped-text

## Feature
`wrapped-text` — Add `WrappedText` component with word-wrap layout to GameUI.

## Date
2026-05-09

## Pre-Answered Decisions

| # | Decision | Answer | Rationale |
|---|----------|--------|-----------|
| 1 | Feature type | User-facing (UI component) | Extends the GameUI declarative DSL for game developers |
| 2 | Walking skeleton | Skipped | Feature is isolated; clear pattern for adding leaf views already exists in the codebase |
| 3 | UX research depth | Lightweight | Happy path is clear; focus on correct word-wrap behaviour and boundary cases |
| 4 | JTBD analysis | Skipped | Job is unambiguous: render long text without overflowing a constrained area |

## SSOT Bootstrapping

No prior `docs/product/` or `docs/feature/` artifacts were found. This DISCUSS wave bootstraps the SSOT.

## Risks Noted

| Risk | Severity | Mitigation |
|------|----------|------------|
| No DIVERGE recommendation present | LOW | Job statement is unambiguous from feature request; documented in journey artifacts as grounding |
| `textMeasurer` fallback accuracy | MEDIUM | Character-count fallback (same as `Text`) is a known approximation; noted in AC for renderer-injected measurer as the happy path |
| Renderer pattern-match: consumers must handle `WrappedText` | MEDIUM | Noted in technical constraints and user story dependencies; downstream renderers (e.g., Raylib) need a new branch |

## Scope Assessment

PASS — 3 user stories, 1 bounded context (`GameUI` layout engine + `WrappedText` view), estimated 2–3 days total.

## Architecture Notes (carry into DESIGN wave)

- `WrappedText` must conform to `View` with `body: Never` (leaf primitive pattern)
- `LayoutEngine.layoutNode` needs a new branch: `if let wrapped = view as? WrappedText`
- Word-wrap output: one child `LayoutNode` per line, stacked vertically at correct origins
- No Foundation, no CGFloat, pure Swift 6.2 + `Float` geometry
- Left-aligned only in this pass; alignment parameter deferred
