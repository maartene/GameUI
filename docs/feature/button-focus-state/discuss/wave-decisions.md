# DISCUSS Decisions — button-focus-state

## Key Decisions

- [D1] Feature type = User-facing: The flag is a UI control state property directly observable by gamepad/keyboard players through the renderer. (see: journey-button-focus-state-visual.md)
- [D2] Walking skeleton = No: `Button` already exists with established end-to-end path. Adding `isFocused: Bool` is a property addition, not new plumbing. (see: story-map.md)
- [D3] UX depth = Lightweight: The feature is tightly constrained with 5 pre-written ACs and hard constraints; full experience mapping provides no additional signal. (see: journey-button-focus-state.yaml)
- [D4] JTBD = Skipped: User motivation is explicit — gamepad/keyboard players need visual confirmation before pressing confirm. No competing jobs identified. (see: user-stories.md S-01)
- [D5] Single slice: The entire feature is one atomic Bool property addition with default. Splitting artificially would not reduce risk or deliver partial value. (see: story-map.md, slice-01-button-focus-flag.md)

## Requirements Summary

- Primary user need: A game developer needs `Button` to carry a passively-stored `isFocused: Bool` flag so the renderer can apply a visually distinct state (≥ 3:1 contrast) for gamepad/keyboard players — without GUIContext coupling.
- Walking skeleton scope: N/A — brownfield extension.
- Feature type: User-facing.

## Constraints Established

- `isFocused: Bool` defaults to `false` — no existing call site breaks
- `GUIContext` is not changed — focus index management stays in SpaceSim
- No new `FocusableButton` type — extend `Button<Content>` only
- `isFocused` lives on the value type — inspectable without a Raylib/rendering context
- **ODQ-01 RESOLVED**: `isFocused: Bool` is added to the `AnyButton` protocol — renderers cast to `AnyButton` and read `isFocused` directly; no `Button<Content>` down-cast needed

## Upstream Changes

None. No prior DISCOVER or DIVERGE waves existed for this feature.
