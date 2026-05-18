# Slice 02 — Standard Tag Vocabulary Documentation

## Slice Name
Documentation Convention: Standard tag vocabulary in `AnyButton` API comments

## Outcome Delivered
New renderer authors discover the standard tag values without reading source code. The API is
self-documenting. Job 3 (extensibility) is explicitly signalled: any String value is valid.

## Effort Estimate
≤ 0.25 days

## Scope
- **File changed**: `Sources/GameUI/LeafViews.swift` — doc comment on `AnyButton.tag`
- **No runtime behaviour change**
- **No new types**

## Doc Comment Content (Intent)

The `tag` property carries semantic role metadata for renderer use. Standard vocabulary (conventions,
not constraints):

- `""` — untagged (default); renderer applies fallback/default style
- `"primary"` — principal call-to-action button
- `"secondary"` — supporting action, lower visual weight
- `"destructive"` — dangerous or irreversible action (warn visually)

Any `String` value is valid. Renderer authors may define additional categories without GameUI
library changes. See documentation for an example renderer switch pattern.

## Brownfield Impact
None — documentation-only change.

## Acceptance Criteria (Summary)
- `AnyButton.tag` has a doc comment describing all four standard values
- Doc comment states that any String value is valid (extensibility statement)

## Dependencies
Slice 01 must be merged first (tag property must exist before it can be documented).

## Stories Contained
- US-BS-02: Standard Tag Vocabulary (see user-stories.md)

## Test Coverage Required
None beyond code review. Documentation correctness is verified by reviewer, not automated tests.
