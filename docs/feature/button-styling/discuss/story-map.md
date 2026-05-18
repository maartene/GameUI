# Story Map: button-styling

## User: Riku Nakamura — game developer building SpaceSim menus
## Goal: Declare semantic button roles so the renderer can apply distinct visual styles without per-screen duplication

---

## Brownfield Assessment

`Button<Content>` and `AnyButton` already exist. This feature is a pure additive extension:
one new stored property (`tag: String`) on `Button<Content>` and one new protocol requirement
(`var tag: String { get }`) on `AnyButton`. The walking skeleton is small by design.

---

## Backbone

| Declare Role | Pass Through Layout | Inspect at Render |
|---|---|---|
| Add `tag:` to `Button` init | Layout engine ignores tag | Renderer reads `AnyButton.tag` |
| Default `tag: ""` for back-compat | Geometry unchanged | Switch on tag → apply style |
| AnyButton exposes `tag` | Tag survives layout pass | Handle unknown tags gracefully |

---

## Story Map Grid

```
Activity:     [Declare Role]      [Pass Through Layout]   [Inspect at Render]
              ─────────────────   ─────────────────────   ───────────────────
Walking       Add tag to Button   Layout tag-transparent   Renderer reads tag
Skeleton:     + AnyButton.tag     (regression test only)   via AnyButton cast
              ─────────────────   ─────────────────────   ───────────────────
Release 1:    (covered by WS)     (covered by WS)          Document standard
                                                           tag vocabulary in
                                                           AnyButton API docs
```

---

### Walking Skeleton (Slice 1)

**Minimum change that lets a renderer differentiate two buttons:**

1. Add `tag: String = ""` parameter to `Button<Content>` init
2. Store as `let tag: String` on `Button<Content>`
3. Add `var tag: String { get }` to `AnyButton` protocol
4. Implement `anyTag` on `Button<Content>` as `tag` property

This is a two-type change (one struct, one protocol) in one file (`LeafViews.swift`). No
layout engine changes. No new files. Renderer can immediately inspect `btn.tag`.

**Outcome delivered:** A renderer author can write `switch btn.tag` and differentiate buttons
by semantic role. The game developer can declare `Button(tag: "primary")`. Theme changes
require zero call-site edits.

### Release 1: Documentation Convention (Slice 2)

**What it adds:**

- `AnyButton.tag` API comment documents the standard vocabulary: `""`, `"primary"`,
  `"secondary"`, `"destructive"` as conventions (not constraints).
- Developer documentation example showing a renderer switch with all four standard cases.

**Outcome delivered:** New renderer authors have a clear starting point. The tag system is
discoverable without reading source code. Job 3 (extensibility) is served: the documentation
explicitly states that any `String` value is valid.

---

## Scope Assessment: PASS

- Stories: 2 (Walking Skeleton + Documentation Convention)
- Bounded contexts: 1 (`LeafViews.swift` / `AnyButton`)
- Walking skeleton integration points: 1 (AnyButton protocol + Button struct)
- Estimated effort: Walking Skeleton ≤ 0.5 days; Documentation Convention ≤ 0.25 days
- Total estimated effort: < 1 day
- Single independent user outcome: "Renderer can differentiate buttons by semantic role"

This is correctly sized for a brownfield additive feature. No splitting required.

---

## Priority Rationale

| Priority | Slice | Outcome | Rationale |
|---|---|---|---|
| P1 | Walking Skeleton | Renderer differentiates buttons by tag | Core capability; unblocks all use cases. O-1 (score 16) + O-2 (score 17) resolved in one change. |
| P2 | Documentation Convention | Renderer authors know standard tag values | Enables discovery (O-4, score 12). Zero code risk — docs only. Separate from WS so WS can ship immediately. |

Walking Skeleton ships first. Documentation Convention can be merged alongside or immediately
after — it has no runtime risk and no test coverage requirement beyond review.
