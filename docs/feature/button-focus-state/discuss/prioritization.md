# Prioritization — button-focus-state

## Slice Execution Order

| Priority | Slice | Rationale                                                                                     |
|----------|-------|-----------------------------------------------------------------------------------------------|
| 1        | 01 — button-focus-flag | Only slice. Learning leverage is highest here: confirms or refutes whether a simple Bool property is sufficient, or whether the AnyButton protocol change introduces unexpected complexity. |

## Rationale

The single slice resolves the only open uncertainty in this feature: **can `isFocused` be a plain stored property on `Button` without any changes to `GUIContext` or `LayoutEngine`?** If yes, the feature is trivial. If no (e.g. protocol conformance issues surface), we learn that on the smallest possible surface.

No dependency chain or dogfood cadence considerations apply — this is the sole deliverable.
