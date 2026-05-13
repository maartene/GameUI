# Shared Artifacts Registry — button-focus-state

| Artifact       | Type            | Source of Truth                         | Consumers                                 | Risk   |
|----------------|-----------------|-----------------------------------------|-------------------------------------------|--------|
| `isFocused`    | `Bool` property | `Button.isFocused` stored property      | Renderer (SpaceSim), Swift Testing specs  | LOW    |
| `AnyButton`    | Protocol        | `LeafViews.swift` — `AnyButton` protocol | `LayoutEngine.layoutNode`, user renderers | LOW — ODQ-01 resolved: `isFocused` added to protocol |
| `action`       | Closure         | `Button.action` / `AnyButton.anyAction` | Consumer (SpaceSim), tests                | LOW    |

## Notes

- `isFocused` is a passive stored property. It is set once at construction and never mutated.
- `AnyButton` is the single protocol through which `LayoutEngine` and renderers access `Button` internals without knowing the concrete `Content` type. Whether `isFocused` is added to `AnyButton` or accessed via a concrete cast is an open design question (ODQ-01 in journey YAML) deferred to DESIGN.
- `action` is unchanged by this feature — it fires only when the consumer explicitly calls it.
