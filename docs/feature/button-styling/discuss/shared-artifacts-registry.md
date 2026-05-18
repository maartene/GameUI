# Shared Artifacts Registry — button-styling

## Purpose

Every `${variable}` referenced in journey mockups and YAML schemas has a single source of truth
documented here. This registry is the horizontal integration check: if any consumer reads a stale
or incorrect source, the failure is traced here.

---

## Registry

### buttonTag

| Field | Value |
|---|---|
| **Name** | `buttonTag` |
| **Source of Truth** | `Button<Content>.tag` — a `let` stored property initialised from the `tag:` constructor parameter |
| **Type** | `String` |
| **Default Value** | `""` (empty string) — enables backwards-compatible call sites |
| **Owner** | `button-styling` feature / `Sources/GameUI/LeafViews.swift` |
| **Protocol Exposure** | `AnyButton.tag: String { get }` — protocol requirement added by this feature |
| **Integration Risk** | LOW — tag is read-only metadata; no mutation after init; no layout engine reads |

**Consumers:**

| Consumer | Step | How Used |
|---|---|---|
| `Button<Content>` init | Step 1 | Stored as `self.tag` |
| `AnyButton.tag` protocol | Step 1→3 | Bridge from concrete type to renderer-facing protocol |
| `LayoutEngine.layout()` | Step 2 | **Does not consume** — tag passes through untouched |
| Renderer switch statement | Step 3 | `switch btn.tag` → selects draw color/style |

**Validation:** Confirmed consistent across steps 1–3. The tag value set at construction time
(step 1) must equal the tag value read by the renderer (step 3). The layout engine (step 2) must
not modify or suppress the tag.

---

### isFocused (pre-existing, from button-focus-state)

| Field | Value |
|---|---|
| **Name** | `isFocused` |
| **Source of Truth** | `Button<Content>.isFocused` — `let` stored property |
| **Protocol Exposure** | `AnyButton.isFocused: Bool { get }` |
| **Owner** | `button-focus-state` feature |
| **Integration Risk** | LOW — pre-existing, validated in prior feature |

**Relationship to `buttonTag`:** Both are metadata properties on `AnyButton`. Both are read-only.
Neither affects the other. A renderer reads both independently:

```swift
if let btn = view as? AnyButton {
    let focused = btn.isFocused   // from button-focus-state
    let role    = btn.tag         // from button-styling (this feature)
    // combine: focused primary button gets a bright blue + focus ring
}
```

---

### anyContent (pre-existing)

| Field | Value |
|---|---|
| **Name** | `anyContent` |
| **Source of Truth** | `Button<Content>.content` — exposed via `AnyButton.anyContent` |
| **Protocol Exposure** | `AnyButton.anyContent: any View { get }` |
| **Owner** | original `Button` implementation |
| **Integration Risk** | LOW — pre-existing, unchanged by this feature |

**Relationship to this feature:** `anyContent` is the button's child view (e.g., `Text("Start
Game")`). The renderer recurses into `anyContent` after drawing the button background. The tag
mechanism removes any need for the renderer to inspect `anyContent`'s text to infer button role.

---

## Integration Validation Summary

| Check | Expected | Risk |
|---|---|---|
| `Button(tag: "primary").tag == "primary"` | PASS | LOW |
| `Button().tag == ""` | PASS (default) | LOW |
| Layout geometry identical for all tag values | PASS | LOW |
| `AnyButton.tag` readable via protocol cast | PASS | LOW |
| Layout engine does not branch on `tag` | PASS | LOW (architectural rule) |
| `isFocused` and `tag` are independent | PASS | LOW |

---

## Open Design Questions

| ID | Question | Status |
|---|---|---|
| ODQ-BS-01 | Should `tag` be `String` or a newtype/typealias? | RESOLVED: raw `String` — keeps API open (Job 3). A typealias can be added by the game developer in their own module without GameUI changes. |
| ODQ-BS-02 | Should the standard tag vocabulary be defined in GameUI as constants? | RESOLVED: No. Constants in GameUI would anchor the vocabulary to a library version. API documentation describes the convention; game developers and renderer authors define their own constants in their own modules. |
| ODQ-BS-03 | Should `tag` appear before or after `isFocused` in the `Button` init signature? | OPEN — for DESIGN wave. Suggested order: `tag:` first (semantic role declared first), then `isFocused:`, then `action:`, then `content:`. Mirrors the existing precedent: `isFocused` was appended before `action:`. |
