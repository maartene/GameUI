# Morgan Guide Session — WrappedText Feature

## Project
GameUI — pure Swift layout engine, no Foundation, no CGFloat, Linux-compatible.

## Interaction Mode
Guide (collaborative, question-by-question)

## Question Log

### Q1: Quality Attributes Priority Order
**Asked**: What quality attributes matter most, and in what order?
**Answer (user)**: Swap positions 1 and 2.

**Recorded priority order**:
1. Safety — no crash or infinite loop from any input
2. Correctness — no child exceeds maxWidth; deterministic
3. Maintainability — renderer author adds WrappedText support in < 15 min
4. Purity — no Foundation, no CGFloat, Linux-compatible

### Q2: Constraints and "Done"
**Asked**: pending (this session)
**Answer**: pending

## Running Architecture Notes

- Existing layout pipeline: declare → layout → render (pure, side-effect-free)
- Text layout today: `layoutTextNode` calls injected `textMeasurer` closure or falls back to `fontSize * charCount` placeholder
- No existing wrapping logic anywhere in the codebase
- All sizes are `Float` (not CGFloat) — purity constraint already enforced
- No Foundation imports visible in `LayoutEngine.swift`
