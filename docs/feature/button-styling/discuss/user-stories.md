<!-- markdownlint-disable MD024 -->
# User Stories — button-styling

## System Constraints

The following constraints apply to all stories in this feature:

- Swift 6.2 — no newer language features
- No Foundation import anywhere in `Sources/GameUI/`
- All new types are `struct` (no `class`)
- `Float` geometry only — no `CGFloat`, no `Double` for geometry
- Swift Testing framework (`@Test func \`...\`()`) — not XCTest
- Test names: backtick-quoted function names only
- No third-party dependencies
- Protocol-oriented value types consistent with existing codebase
- All changes are source-additive and backwards-compatible (brownfield)

---

## Design Decision Record

**Question**: Tag/metadata (Option A) vs. color injection (Option B)?

**Decision**: Option A — `tag: String` on `AnyButton`.

**Rationale**:
- JTBD opportunity scoring (see `jtbd-opportunity-scores.md`): O-2 "minimise call-site edits when
  theme changes" scores 17 (highest). Option B fails O-2 by scattering colors across call sites.
- Option A preserves GameUI's content/appearance separation. The renderer owns all visual decisions.
- Option B requires every renderer to handle `Optional<Color>` nil-means-default logic — a contract
  burden that conflicts with Job 3 (renderer extensibility without library updates).
- `String` tag mirrors the established `isFocused: Bool` pattern — same protocol, same cast, same
  inspection site in the renderer.

---

## US-BS-01: Tag Property on Button

### Problem

Riku Nakamura is a game developer building SpaceSim, a space-combat game with a main menu
containing three buttons: "Start Game", "Settings", and "Quit". He finds it confusing that
all three buttons must be drawn identically by his renderer, because `AnyButton` exposes no
semantic metadata other than `isFocused`. To differentiate them visually, Riku must inspect
the text content of each button's child view — a fragile workaround that breaks when he
renames "Quit" to "Exit".

### Who

- Riku Nakamura | Game developer, SpaceSim | Motivated to ship a polished main menu where
  players immediately recognise "Start Game" as the primary action

### Solution

Add `tag: String = ""` to `Button<Content>`'s initialiser and expose it via a new
`var tag: String { get }` requirement on the `AnyButton` protocol. The tag is passive
metadata: the layout engine ignores it; the renderer reads it at render time via the
existing `view as? AnyButton` cast.

### Elevator Pitch

**Before**: Riku's SpaceSim renderer has to parse button text content to decide which style
to apply — `if btn.anyContent is Text("Quit")` — which is fragile and breaks on rename.

**After**: Riku writes `Button(tag: "destructive")` and his renderer switch on `btn.tag`
applies warning-red styling. Renaming the label does not affect rendering.

**Decision enabled**: Riku can confidently rename any button label without fearing visual
regressions. He can also change the destructive button colour for all 12 SpaceSim screens
by editing one line of the renderer.

### Domain Examples

#### 1: Primary Action Button (Happy Path)
Riku declares `Button(tag: "primary", isFocused: focusedIndex == 0) { Text("Start Game") }
action: { startGame() }`. The renderer casts the view to `AnyButton`, reads `btn.tag == "primary"`,
and draws the button with accent-blue background. "Start Game" is visually prominent.

#### 2: Destructive Button with isFocused Combined
Riku declares `Button(tag: "destructive", isFocused: focusedIndex == 2) { Text("Quit") }
action: { quit() }`. The renderer reads both `btn.isFocused == true` (keyboard focus ring)
and `btn.tag == "destructive"` (warning-red background) independently. Both apply simultaneously.

#### 3: Legacy Button Without Tag (Backwards Compatibility)
An existing SpaceSim screen has `Button { Text("Confirm") } action: { confirm() }` (no `tag`
argument). After the feature ships, this call site compiles unchanged. The renderer's `default:`
case handles `tag == ""` with the existing white/unstyled appearance. Zero migration required.

### UAT Scenarios (BDD)

#### Scenario: Game developer tags button with a semantic role and renderer reads it
Given Riku declares `Button(tag: "primary")` in SpaceSim's MainMenuView
When the button is constructed
Then `btn.tag` equals `"primary"` when cast to `AnyButton`
And the tag is accessible without any additional protocol cast

#### Scenario: Button without tag argument uses empty string default
Given Riku declares `Button()` without a `tag` argument
When the button is constructed
Then `btn.tag` equals `""`
And the call site requires no code change

#### Scenario: Tag and isFocused are independent — both readable simultaneously
Given Riku declares `Button(tag: "destructive", isFocused: true)`
When the button is cast to `AnyButton`
Then `btn.tag` equals `"destructive"`
And `btn.isFocused` equals `true`
And changing `isFocused` does not affect `tag`, and vice versa

#### Scenario: Tag passes through layout engine with no effect on geometry
Given a `Button(tag: "primary")` and a `Button(tag: "")` with identical content and constraints
When both are processed by the layout engine
Then both produce `LayoutNode` frames with identical `width` and `height`

#### Scenario: Renderer differentiates multiple button roles in one view hierarchy
Given a VStack containing `Button(tag: "primary")`, `Button(tag: "secondary")`,
and `Button(tag: "destructive")`
And the layout engine has produced a `LayoutTree` from this view
When the renderer casts each leaf view node to `AnyButton`
Then the first button's tag equals `"primary"`
And the second button's tag equals `"secondary"`
And the third button's tag equals `"destructive"`

### Acceptance Criteria

- [ ] `Button(tag: "primary").tag == "primary"` — tag stored correctly on construction
- [ ] `Button().tag == ""` — default value is empty string; backwards-compatible
- [ ] `Button(tag: "primary") as? AnyButton` returns non-nil; `.tag == "primary"`
- [ ] Layout geometry (width, height) is identical for Button with any tag vs. Button with ""
- [ ] `isFocused` and `tag` are independently readable and do not affect each other
- [ ] A VStack of three tagged buttons produces three AnyButton-castable nodes in the LayoutTree
- [ ] No Foundation import added to `LeafViews.swift`
- [ ] All new code is `struct`-based; no classes introduced

### Outcome KPIs

- **Who**: Riku Nakamura (game developer building SpaceSim with ≥2 button types per screen)
- **Does what**: Declares button roles at the call site and differentiates them in the renderer
  without inspecting button label text
- **By how much**: Renderer code differentiating 3 button types requires exactly 1 switch
  statement with N cases — zero per-screen duplication
- **Measured by**: Code review of SpaceSim renderer after feature adoption
- **Baseline**: Currently requires text-content inspection or identical rendering for all buttons

### Technical Notes

- File: `Sources/GameUI/LeafViews.swift`
- Change 1: Add `var tag: String { get }` to `AnyButton` protocol
- Change 2: Add `let tag: String` stored property to `Button<Content>`
- Change 3: Add `tag: String = ""` parameter to `Button<Content>.init` (before `isFocused:`)
- Change 4: Implement `AnyButton.tag` on `Button<Content>` as `{ tag }`
- Layout engine: no changes
- HitTest.swift: no changes
- Sendability: `tag` is a `String` (value type, `Sendable`) — no concurrency annotations needed
- Parameter order suggestion (ODQ-BS-03): `tag:` before `isFocused:` to match semantic role
  declaration before interaction state

---

## US-BS-02: Standard Tag Vocabulary

### Problem

Riku Nakamura wants to add button styling to SpaceSim. He knows `AnyButton.tag` exists
(from US-BS-01) but does not know which tag values to use for a primary vs. secondary vs.
destructive button. He must read the source code or ask on a forum to discover the convention.
This friction delays adoption and produces inconsistent tag vocabulary across different games
using GameUI.

### Who

- Riku Nakamura | First-time adopter of `AnyButton.tag` | Motivated to start quickly with
  a clear, documented convention

### Solution

Add a doc comment to `AnyButton.tag` in `LeafViews.swift` documenting the four standard tag
values (`""`, `"primary"`, `"secondary"`, `"destructive"`) as conventions, with an explicit
statement that any `String` value is valid. Include a renderer switch example in a playground
or README snippet.

### Elevator Pitch

**Before**: Riku opens source code to discover what string values are meaningful for `btn.tag`.
He invents his own ("primaryButton", "main") which diverges from the community convention.

**After**: Xcode shows Riku the doc comment inline as he types `Button(tag:`. He sees the
four standard values and picks `"primary"` in seconds.

**Decision enabled**: Riku can adopt the tag API immediately without reading source code.
Renderer authors across the community converge on the same standard vocabulary, making
community-shared renderers interoperable.

### Domain Examples

#### 1: Xcode Quick Help (Happy Path)
Riku types `Button(tag:` in Xcode. Quick Help shows: "Semantic role tag. Standard values:
`""` (unstyled), `"primary"` (principal CTA), `"secondary"` (supporting action),
`"destructive"` (irreversible/dangerous). Any String value is valid."

#### 2: Community Renderer Interoperability
The "neon-gameui" community renderer handles `"primary"`, `"secondary"`, and `"destructive"`.
Riku uses these three values in SpaceSim and the neon renderer applies correct styles without
Riku reading the renderer source.

#### 3: Custom Category Without Library Update
Riku needs a `"highlighted"` button for tutorial flow. He uses `Button(tag: "highlighted")`.
His custom renderer adds a `case "highlighted":` to its switch. No GameUI library update
needed. The doc comment's extensibility statement explicitly covers this.

### UAT Scenarios (BDD)

#### Scenario: Standard tag vocabulary is discoverable from API documentation
Given the `AnyButton.tag` property has a doc comment
When a developer reads the doc comment (via Xcode Quick Help or source)
Then the comment lists all four standard values: `""`, `"primary"`, `"secondary"`, `"destructive"`
And the comment states that any String value is valid

#### Scenario: Custom tag values are valid without library changes
Given a Button declared with `tag: "highlighted"` (a non-standard value)
When the button is constructed
Then the tag property equals `"highlighted"` without compilation error or runtime warning
And no GameUI library update is required to support the new value

### Acceptance Criteria

- [ ] `AnyButton.tag` has a Swift doc comment (`///`) listing all four standard values
- [ ] Doc comment includes the statement that any `String` value is valid
- [ ] `Button(tag: "highlighted")` compiles and carries `tag == "highlighted"` — custom values accepted
- [ ] Doc comment is verified accurate by code review

### Outcome KPIs

- **Who**: First-time adopters of `AnyButton.tag` in GameUI
- **Does what**: Discover and use the standard tag vocabulary from API documentation without
  reading source code or seeking external help
- **By how much**: Time-to-first-use reduced; discoverability measurable by community adoption
  of standard vocabulary (qualitative at this stage)
- **Measured by**: Code review + community renderer interoperability (qualitative)
- **Baseline**: Currently no documented convention; developers must infer from source

### Technical Notes

- File: `Sources/GameUI/LeafViews.swift`
- Change: Add `///` doc comment to `AnyButton.tag` property declaration
- No runtime change; no test coverage requirement beyond review
- Depends on US-BS-01 (tag property must exist before it can be documented)
