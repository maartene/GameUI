# JTBD Opportunity Scores — button-styling

## Scoring Method

Opportunity Score (Ulwick) = Importance + max(0, Importance − Satisfaction)

Scale: 1–10 for both Importance and Satisfaction. Score ≥ 10 indicates high-opportunity outcome.

Scores are estimates from problem statement analysis and prior-wave context (no formal user interviews;
D4 = lightweight JTBD). Confidence: MEDIUM.

---

## Outcome Statements Scored

| # | Outcome Statement | Importance | Satisfaction (current) | Opportunity Score | Priority |
|---|---|---|---|---|---|
| O-1 | Minimize the time for a renderer to differentiate button appearance by role | 9 | 2 | **16** | P1 |
| O-2 | Minimize the number of call-site changes when a theme color is updated | 9 | 1 | **17** | P1 |
| O-3 | Minimize the risk that a new button role requires a GameUI library update | 8 | 3 | **13** | P2 |
| O-4 | Minimize cognitive effort for a developer adding a styled button for the first time | 8 | 4 | **12** | P2 |
| O-5 | Minimize the risk of silent visual bugs when button metadata is absent | 7 | 5 | **9** | P3 |
| O-6 | Minimize the boilerplate needed to pass styling information through the layout engine | 8 | 3 | **13** | P2 |

---

## Ranked Opportunities Table

| Rank | Outcome | Score | Addressed by |
|---|---|---|---|
| 1 | O-2: Theme changes require zero call-site edits | 17 | Option A tag: renderer owns all visual logic |
| 2 | O-1: Renderer differentiates buttons by role without text-inspection | 16 | Option A tag: `AnyButton.tag` inspected in renderer switch |
| 3 | O-3: New roles require no library update | 13 | `String` tag is open-ended |
| 3 | O-6: Styling passes through layout engine transparently | 13 | Tag is passive metadata on `AnyButton`; layout ignores it |
| 5 | O-4: First-time ergonomics are simple | 12 | `Button(tag: "primary")` is one argument |
| 6 | O-5: Missing metadata has safe default | 9 | Default `tag: ""` → renderer treats as unstyled |

---

## JTBD-to-Story Bridge

### Bridge 1: Core Tag API (O-1, O-2, O-6)

Story focus: Add `tag: String` to `AnyButton` protocol and `Button<Content>` struct. Default is `""`.
This single change resolves O-1 (renderers can now differentiate), O-2 (theming centralised in
renderer), and O-6 (tag passes through layout without ceremony).

### Bridge 2: Documented Tag Convention (O-3, O-4)

Story focus: Document standard tag vocabulary ("", "primary", "secondary", "destructive") in
`AnyButton` API comment. Not a closed enum — a convention. Resolves O-3 (open to extension) and
O-4 (first-time ergonomics: "use one of these or invent your own").

### Bridge 3: Backwards-Compatible Default (O-5)

Story focus: `Button()` with no `tag` argument gets `tag: ""`. Renderers that do not inspect `tag`
are unaffected. Renderers that do inspect it treat `""` as "no style" and apply a default.
Resolves O-5 (no silent bugs from missing tag — empty string is explicit and documentable).

---

## Design Decision: Option A Confirmed

The opportunity score table confirms Option A (tag/metadata). O-2 scores highest: central theming
is the biggest unmet need. Option B (color injection) would score LOW for O-2 (colors scattered
across call sites) and ZERO for O-3 (every new "color preset" is a call-site pattern, not a
renderer extension). Option A dominates across all six outcomes.

**Recommended API shape** (for DESIGN wave input):

```
// On AnyButton protocol:
var tag: String { get }

// On Button<Content>:
init(tag: String = "", isFocused: Bool = false, action: ..., content: ...) { ... }
```

The tag is passive metadata. It is not interpreted by the layout engine. Renderers inspect it
at render time via the established `if let btn = view as? AnyButton` pattern.
