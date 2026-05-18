# DISTILL Decisions — hit-test-button

## Key Decisions

- [DWD-01] **WS Strategy: Strategy A (pure in-memory).** `hitTestButton` is a pure
  library function with no I/O, no filesystem access, no network, and no subprocess
  invocations. All test data is constructed inline using `Button`, `VStack`, `HStack`,
  `FrameModifier`, and `LayoutEngine`. No test doubles are needed beyond a spy closure
  for AC-07.

- [DWD-02] **Scaffold behaviour: nil-returning stub.** `HitTest.swift` contains a
  single-line `return nil` body. Tests expecting a non-nil index (0, 1, 2) are RED.
  Tests expecting `nil` are GREEN by coincidence — acceptable because the scaffold
  demonstrates that ALL code compiles before any production logic exists.

- [DWD-03] **AC-07 scaffold behaviour.** The "traversal never invokes button action"
  test passes on the scaffold because the scaffold never calls any code at all. This
  is an acceptable GREEN-on-scaffold case. It is kept `.disabled` so the crafter
  explicitly enables it and verifies it in the context of real traversal logic.
  Mutation testing targeting `anyAction` call sites provides the post-implementation
  enforcement.

- [DWD-04] **No Gherkin `.feature` files.** This project uses Swift Testing
  (`@Test`, `#expect`, `#require`). All acceptance scenarios are in
  `HitTestButtonTests.swift`. The BDD intent from `user-stories.md` and
  `button-hover.yaml` is expressed directly in Swift test names and inline comments.

- [DWD-05] **Reconciliation: 0 contradictions.** DISCUSS and DESIGN wave decisions
  are fully consistent. Key alignment points: free function placement (both waves
  confirm `HitTest.swift`), inclusive boundary (both waves confirm `<=` fix to
  `Rect.contains`), no new protocols or types (both waves confirm reuse-only approach).

- [DWD-06] **ODQ-01 sequencing.** The `Rect.contains` fix (`<` → `<=`) is a
  prerequisite for the AC-06 boundary tests (Tests 11 and 12). Those two tests carry
  the message "requires ODQ-01 Rect.contains fix first" in their `.disabled` label.
  The crafter must apply the fix before enabling those two tests.

- [DWD-07] **Test file location.** The design wave's handoff document listed
  `Tests/GameUITests/HitTestButtonTests.swift`. The DISTILL wave places the file
  under the `acceptance/` subfolder, consistent with the convention established by
  `WrappedTextSlice1CoreTests.swift` and the Phase acceptance suites. This is a
  structural preference, not a contradiction.

## Test File

`Tests/GameUITests/acceptance/HitTestButtonTests.swift`

## Scaffold File

`Sources/GameUI/HitTest.swift`

## RED State Analysis

| # | Test name | Expected result | Scaffold result | State |
|---|---|---|---|---|
| 1 | Walking skeleton — cursor over single button | 0 | nil | RED |
| 2 | Cursor over first of two buttons | 0 | nil | RED |
| 3 | Cursor over second of two buttons | 1 | nil | RED |
| 4 | Cursor in gap between two buttons | nil | nil | GREEN (disabled) |
| 5 | Cursor far outside all buttons | nil | nil | GREEN (disabled) |
| 6 | View tree with no buttons | nil | nil | GREEN (disabled) |
| 7 | Three buttons indexed 0, 1, 2 | 0, 1, 2 | nil | RED (disabled) |
| 8 | Button inside nested VStack | 1 | nil | RED (disabled) |
| 9 | Buttons inside HStack | 0, 1 | nil | RED (disabled) |
| 10 | Button inside FrameModifier | 1 | nil | RED (disabled) |
| 11 | Top-left boundary hit (ODQ-01) | 0 | nil | RED (disabled) |
| 12 | Bottom-right boundary hit (ODQ-01) | 0 | nil | RED (disabled) |
| 13 | Traversal never invokes action | callCount == 0 | callCount == 0 | GREEN (disabled) |

Notes:
- Test 1 (walking skeleton) is the only enabled test. It is RED.
- Tests 4, 5, 6, 13 are GREEN-on-scaffold by coincidence. They remain disabled until
  their slot in the TDD sequence.
- Tests 2–3, 7–12 are RED. Each requires real traversal logic to pass.

## Mandate Compliance Evidence

**CM-A (Hexagonal Boundary):** All tests invoke through `hitTestButton(view:node:at:)`,
the public free function in `HitTest.swift`. No internal component (e.g., the private
`hitTestNode` helper) is tested directly. Import: `@testable import GameUI` — no
internal type is constructed except through the public API.

**CM-B (Business Language):** Test names use domain terms: "cursor over button",
"returns index", "gap between buttons", "top-left corner", "traversal never invokes
action". No HTTP, no database, no JSON, no class names.

**CM-C (User Journey Completeness):** Walking skeleton answers "Can Riku call
hitTestButton and receive the index of the button his cursor is over?" — demo-able
to a stakeholder. Focused scenarios cover AC-02 through AC-07 systematically.

**CM-D (Pure Function):** `hitTestButton` is a pure function (no I/O, no side effects).
Strategy A applies: all tests are direct calls, no adapter layer, no fixture
parametrisation. No impure code exists in the feature boundary.
