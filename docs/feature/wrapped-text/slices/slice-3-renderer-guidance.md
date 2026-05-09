# Slice 3: Renderer Guidance

## Slice ID
`wrapped-text/slice-3`

## Outcome Target
A developer integrating a custom renderer (e.g., Raylib) can walk a `WrappedText` layout tree and emit correct per-line draw calls without reading the `LayoutEngine` source code.

## Learning Hypothesis
We believe that resolving the line-string access design question (shared-artifacts-registry.md open question) and updating the README Raylib integration example will enable developers to add `WrappedText` to an existing renderer integration in under 30 minutes.

We will know this is true when:
- The README example includes a `WrappedText` branch in the renderer pattern-match
- The design decision on line-string access is implemented (Option A: `WrappedText.lines` or Option C: child view nodes)
- A developer (Riku) can follow the example without needing to inspect internal source

## User Story
US-03 — WrappedText Renderer Guidance (Documentation + Design Decision Implementation)

## Effort Estimate
0.5 day (pending DESIGN wave decision on line-string access)

## Acceptance Tests
- README Raylib integration example contains a `WrappedText` branch
- The example shows how to retrieve per-line strings and draw them at child node origins
- The pattern is consistent with existing `Text` and `Rectangle` renderer branches

## Dependencies
- Slice 1 (US-01) must be complete
- DESIGN wave must resolve the line-string access design question (open question in shared-artifacts-registry.md)

## Status
BLOCKED pending DESIGN wave decision on line-string access approach.
