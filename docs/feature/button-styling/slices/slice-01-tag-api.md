# Slice 01 — Tag API (Walking Skeleton)

## Slice Name
Walking Skeleton: `tag` property on `AnyButton` and `Button<Content>`

## Outcome Delivered
A renderer can differentiate two `Button` instances by semantic role using `AnyButton.tag`.
A game developer can declare `Button(tag: "primary")` at the call site. Theme changes require
zero call-site edits — the renderer switch is the single point of change.

## Effort Estimate
≤ 0.5 days

## Scope
- **File changed**: `Sources/GameUI/LeafViews.swift`
- **AnyButton protocol**: add `var tag: String { get }` requirement
- **Button<Content> struct**: add `let tag: String` stored property + `tag: String = ""` init parameter
- **No layout engine changes**
- **No new files**

## Brownfield Impact
Backwards-compatible. All existing `Button()` call sites compile without modification because
`tag` defaults to `""`.

## Acceptance Criteria (Summary)
- `Button(tag: "primary").tag == "primary"` — tag stored correctly
- `Button().tag == ""` — default value present
- `AnyButton.tag` readable via protocol cast
- Layout geometry identical for any tag value
- `isFocused` and `tag` are independent

## Dependencies
None — brownfield additive change.

## Stories Contained
- US-BS-01: Tag Property on Button (see user-stories.md)

## Test Coverage Required
- Unit: tag stored correctly (constructor carries tag)
- Unit: default tag is ""
- Unit: isFocused and tag are orthogonal
- Acceptance: layout geometry tag-invariant
- Acceptance: renderer can read tag via AnyButton cast
