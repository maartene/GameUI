// ProgressBar Slice 1 — Declare and Fill Acceptance Tests
// Driving port (declaration): ProgressBar.init(value:label:fillColor:trackColor:)
// Driving port (layout):      LayoutEngine.layout(_:in:)
// Driving port (hit test):    hitTestButton(view:node:at:)
// Driving port (render):      ProgressBar.clampedValue
// US-01: Declare a Progress Bar with Chosen Colors  (AC-01 … AC-07)
//
// No textMeasurer is injected: ProgressBar carries no text and never consults one.
// Enable tests one at a time in DELIVER; each maps to one TDD cycle.

import Testing
@testable import GameUI

@Suite("ProgressBar — Declare and Fill")
struct ProgressBarSlice1DeclareAndFillTests {

    // -------------------------------------------------------------------------
    // AC-01: Declared properties are carried verbatim
    // Shield charge at 65%, green fill on a dark track.
    // -------------------------------------------------------------------------

    @Test func `ProgressBar carries value label fillColor and trackColor as declared`() {
        let bar = ProgressBar(value: 0.65, label: "Shield charge", fillColor: .green, trackColor: .darkGray)
        #expect(bar.value == 0.65)
        #expect(bar.label == "Shield charge")
        #expect(bar.fillColor == .green)
        #expect(bar.trackColor == .darkGray)
    }

    // -------------------------------------------------------------------------
    // AC-02: Colours are optional at the call site and default to green on darkGray
    // -------------------------------------------------------------------------

    @Test func `ProgressBar declared without colours defaults to green fill on darkGray track`() {
        let bar = ProgressBar(value: 0.4, label: "Loading")
        #expect(bar.fillColor == .green)
        #expect(bar.trackColor == .darkGray)
    }

    // -------------------------------------------------------------------------
    // AC-03: A framed ProgressBar is sized by its frame, and is itself childless
    // The frame node carries exactly one child — the bar. The bar carries none.
    // (Corrected in DESIGN — see design/upstream-changes.md UC-01.)
    // -------------------------------------------------------------------------

    @Test func `framed ProgressBar is sized by its frame and the bar node itself has no children`() throws {
        let bar = ProgressBar(value: 0.65, label: "Shield charge").frame(width: 200, height: 20)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)
        let tree = LayoutEngine().layout(bar, in: constraints)
        #expect(tree.root.frame.size == Size(width: 200, height: 20))
        try #require(tree.root.children.count == 1)
        #expect(tree.root.children[0].frame.size == Size(width: 200, height: 20))
        #expect(tree.root.children[0].children.isEmpty)
    }

    // -------------------------------------------------------------------------
    // AC-04: A bare ProgressBar fills its constraints and has no children
    // Same fill-constraints behaviour a bare Slider exhibits today (DDD-4).
    // -------------------------------------------------------------------------

    @Test func `bare ProgressBar fills the whole constraint box and has no children`() {
        let bar = ProgressBar(value: 0.65, label: "Shield charge")
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)
        let tree = LayoutEngine().layout(bar, in: constraints)
        #expect(tree.root.frame.size == Size(width: 400, height: 300))
        #expect(tree.root.children.isEmpty)
    }

    // -------------------------------------------------------------------------
    // AC-04b: A bare ProgressBar and a bare Slider lay out identically
    // Pins the reuse claim in DDD-4 — both reach the same fill-constraints default.
    // -------------------------------------------------------------------------

    @Test func `bare ProgressBar lays out identically to a bare Slider`() {
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)
        let engine = LayoutEngine()
        let barTree = engine.layout(ProgressBar(value: 0.65, label: "Shield charge"), in: constraints)
        let sliderTree = engine.layout(Slider(value: 0.65, label: "Shield charge"), in: constraints)
        #expect(barTree.root.frame == sliderTree.root.frame)
        #expect(barTree.root.children.count == sliderTree.root.children.count)
    }

    // -------------------------------------------------------------------------
    // AC-05: Renderer-facing fill width is the node width times the clamped value
    // 200 × 0.65 == 130.0 exactly in Float.
    // -------------------------------------------------------------------------

    @Test func `fill width for a 65 percent bar in a 200 wide node is 130`() {
        let bar = ProgressBar(value: 0.65, label: "Shield charge")
        let tree = LayoutEngine().layout(bar, in: LayoutConstraints(maxWidth: 200, maxHeight: 20))
        let fillWidth = tree.root.frame.size.width * bar.clampedValue
        #expect(fillWidth == 130.0)
    }

    // -------------------------------------------------------------------------
    // AC-05b: A full bar fills the track exactly; an empty bar draws nothing
    // -------------------------------------------------------------------------

    @Test func `full bar fill width equals track width and empty bar fill width is zero`() {
        let tree = LayoutEngine().layout(
            ProgressBar(value: 1.0, label: "Shield charge"),
            in: LayoutConstraints(maxWidth: 200, maxHeight: 20)
        )
        let trackWidth = tree.root.frame.size.width
        #expect(trackWidth * ProgressBar(value: 1.0, label: "Shield charge").clampedValue == 200.0)
        #expect(trackWidth * ProgressBar(value: 0.0, label: "Shield charge").clampedValue == 0.0)
    }

    // -------------------------------------------------------------------------
    // AC-06: A ProgressBar is never reported as hit
    // It is not an AnyButton and has no action to invoke (D5).
    // -------------------------------------------------------------------------

    @Test func `hit testing a ProgressBar returns nil at every point including its own frame`() {
        let bar = ProgressBar(value: 0.65, label: "Shield charge")
        let tree = LayoutEngine().layout(bar, in: LayoutConstraints(maxWidth: 200, maxHeight: 20))
        #expect(hitTestButton(view: bar, node: tree.root, at: Point(x: 100, y: 10)) == nil)
        #expect(hitTestButton(view: bar, node: tree.root, at: Point(x: 0, y: 0)) == nil)
        #expect(hitTestButton(view: bar, node: tree.root, at: Point(x: 999, y: 999)) == nil)
    }

    // -------------------------------------------------------------------------
    // AC-06b: A ProgressBar beside a Button does not shift the button's index
    // Guards against ProgressBar accidentally entering the traversal count.
    // -------------------------------------------------------------------------

    @Test func `a ProgressBar beside a Button does not consume a hit-test index`() {
        let screen = VStack {
            ProgressBar(value: 0.65, label: "Shield charge").frame(width: 200, height: 20)
            Button(action: {}) { Rectangle(color: .white).frame(width: 200, height: 20) }
        }
        let tree = LayoutEngine().layout(screen, in: LayoutConstraints(maxWidth: 200, maxHeight: 100))
        // The button is the first and only AnyButton in the tree → index 0, not 1.
        #expect(hitTestButton(view: screen, node: tree.root, at: Point(x: 100, y: 30)) == 0)
    }

    // -------------------------------------------------------------------------
    // AC-07: ProgressBar is a primitive view — its Body is Never
    // Consistent with Slider, Checkbox and Text.
    // -------------------------------------------------------------------------

    @Test func `ProgressBar is a primitive view whose Body is Never`() {
        #expect(ProgressBar.Body.self == Never.self)
    }
}
