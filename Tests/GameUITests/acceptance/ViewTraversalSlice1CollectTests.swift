// View Traversal Slice 1 — collect(_:from:) Acceptance Tests
//
// Driving port (traversal):    GameUI.childViews(of:)
// Driving port (collection):   GameUITesting.collect(_:from:)
// Driving port (conveniences): collectTexts / collectButtons / collectTextColors /
//                              collectProgressBars / collectTextures
//
// The elevator pitch: a downstream test author asserts on the UI a screen *declares*,
// not on the geometry it happens to lay out to. GameUI is a library with no CLI, so the
// driving port IS the public API and the demo is an API call whose observable output is
// the returned array (CLAUDE.md § Standing Exemptions, Phase 3.5 adaptation).
//
// These imports are deliberately NOT `@testable`. This target consumes GameUITesting the
// way a downstream test target does — through its public product. `@testable import GameUI`
// from GameUITesting is rejected outright (ADR-006 Alternative E): it needs -enable-testing,
// which SwiftPM does not apply to a package consumed as a release dependency, so it would
// compile here and fail at every consumer.
//
// Enable tests one at a time in DELIVER; each maps to one TDD cycle.

import Testing
import GameUI
import GameUITesting

// MARK: - Fixtures
//
// These composites live in the test target, so they are outside `Sources/GameUI/` and
// correctly invisible to the traversal registry CI check.

/// A composite view whose `body` is a single expression. `Body != Never`, so the ONLY route
/// to the ProgressBar inside is `childViews`' composite fallback. This is the exact shape
/// both field incidents skipped: a helper missing that branch returns `[]` and the assertion
/// `#expect(bars.isEmpty)` passes for the wrong reason.
private struct ShieldPanel: View {
    let charge: Float

    var body: some View {
        VStack(spacing: 2) {
            Text(content: "Shields", fontSize: 8, color: .lightGray)
            ProgressBar(value: charge, label: "Shield charge")
        }
    }
}

/// A composite whose `body` is a MULTI-STATEMENT `@ViewBuilder` block, so the body value is
/// a bare `TupleView3` with no enclosing container.
///
/// `layoutNode` has no `ChildrenProviding` branch, so a bare tuple matches nothing there and
/// this row lays out as an empty fill-constraints box — that gap is NOT fixed by this feature
/// and is recorded as ODQ-VT-03. `childViews` adds the branch (DDD-9), so the row's contents
/// become traversable for the first time. That is what the test below proves.
///
/// Note the explicit `@ViewBuilder` on `body`: `GameUI.View` does not annotate the protocol
/// requirement, unlike SwiftUI, so a multi-statement body does not compile without it.
private struct AbilityRow: View {
    @ViewBuilder var body: some View {
        Text(content: "Boost", fontSize: 8, color: .yellow)
        Texture(textureName: "boost-icon")
        ProgressBar(value: 0.5, label: "Boost cooldown")
    }
}

/// A composite containing a button, wrapped in modifiers — the shape a real HUD produces and
/// the one a hand-copied chain missing `HasFrameSize` silently truncated (`brief.md`
/// § wrapped-text-max-lines records that incident verbatim).
private struct AbilityButtonPanel: View {
    var body: some View {
        Button(tag: "primary", action: {}) {
            ProgressBar(value: 0.25, label: "Ability cooldown")
        }
        .frame(width: 120, height: 24)
        .padding(x: 4, y: 2)
    }
}

@Suite("View Traversal — collect")
struct ViewTraversalSlice1CollectTests {

    // -------------------------------------------------------------------------
    // WALKING SKELETON (API demo, Phase 3.5 adapted)
    //
    // A downstream test author asks a declared screen what it contains and gets an
    // answer. Every layer the feature ships is on this path: childViews' composite
    // branch, its container branch, collect's recursion, and a convenience wrapper.
    // The observable output is the returned array — no subprocess is fabricated.
    // -------------------------------------------------------------------------

    @Test func `a declared HUD screen reports the shield charge a downstream test asserts on`() throws {
        let hud = VStack(spacing: 4) {
            Text(content: "SYSTEMS", fontSize: 10, color: .white)
            ShieldPanel(charge: 0.65)
        }

        let bars = collectProgressBars(from: hud)

        try #require(bars.count == 1)
        #expect(bars[0].label == "Shield charge")
        #expect(bars[0].value == 0.65)
        #expect(collectTexts(from: hud) == ["SYSTEMS", "Shields"])
    }

    // -------------------------------------------------------------------------
    // The field incident, isolated: a view reachable ONLY through a composite body
    // -------------------------------------------------------------------------

    @Test func `collect finds a progress bar nested inside a composite body`() throws {
        let bars = collect(ProgressBar.self, from: ShieldPanel(charge: 0.4))

        try #require(bars.count == 1)
        #expect(bars[0].label == "Shield charge")
    }

    // -------------------------------------------------------------------------
    // The root itself matches — collect includes it rather than starting at its children
    // -------------------------------------------------------------------------

    @Test func `collect finds a progress bar declared at the root of the tree`() throws {
        let bars = collect(ProgressBar.self, from: ProgressBar(value: 0.9, label: "Hull integrity"))

        try #require(bars.count == 1)
        #expect(bars[0].label == "Hull integrity")
    }

    // -------------------------------------------------------------------------
    // Nested modifiers: frame + padding + button, all in one chain
    // -------------------------------------------------------------------------

    @Test func `collect reaches a progress bar through frame padding and button layers`() throws {
        let bars = collect(ProgressBar.self, from: AbilityButtonPanel())

        try #require(bars.count == 1)
        #expect(bars[0].label == "Ability cooldown")
    }

    // -------------------------------------------------------------------------
    // DDD-9: a multi-statement @ViewBuilder body produces a bare TupleViewN.
    // Newly reachable — this branch does not exist in layoutNode and never has.
    // -------------------------------------------------------------------------

    @Test func `collect reaches every view of a multi-statement builder body`() {
        let row = AbilityRow()

        #expect(collectTexts(from: row) == ["Boost"])
        #expect(collectTextures(from: row).map(\.textureName) == ["boost-icon"])
        #expect(collectProgressBars(from: row).map(\.label) == ["Boost cooldown"])
    }

    // -------------------------------------------------------------------------
    // Depth-first, declaration order — the order a renderer encounters the tree.
    //
    // "b" and "c" are nested one level deeper than "a" and "d". Breadth-first would
    // report a, d, b, c; a chain that abandoned the subtree would report a, d.
    // -------------------------------------------------------------------------

    @Test func `collect visits the tree depth first in declaration order`() {
        let screen = VStack {
            Text(content: "a", fontSize: 8)
            HStack {
                Text(content: "b", fontSize: 8)
                Text(content: "c", fontSize: 8)
            }
            Text(content: "d", fontSize: 8)
        }

        #expect(collectTexts(from: screen) == ["a", "b", "c", "d"])
    }

    // -------------------------------------------------------------------------
    // A match does not end the walk. The silent-under-traversal bug class includes
    // "stopped early", not only "never started".
    // -------------------------------------------------------------------------

    @Test func `collect keeps visiting later siblings after it finds a match`() {
        let screen = VStack {
            ProgressBar(value: 0.1, label: "first")
            ShieldPanel(charge: 0.2)
            ProgressBar(value: 0.3, label: "third")
        }

        #expect(collectProgressBars(from: screen).map(\.label) == ["first", "Shield charge", "third"])
    }

    // -------------------------------------------------------------------------
    // Depth: twelve wrapper layers. Each `.frame`/`.padding` is a distinct generic
    // type, so this also proves the walk does not depend on a bounded type depth.
    // -------------------------------------------------------------------------

    @Test func `collect reaches a progress bar twelve modifier layers deep`() throws {
        let deep = ProgressBar(value: 0.5, label: "Core temperature")
            .frame(width: 100, height: 10)
            .padding(1)
            .padding(x: 1, y: 1)
            .frame(width: 100, height: 10)
            .padding(1)
            .padding(x: 1, y: 1)
            .frame(width: 100, height: 10)
            .padding(1)
            .padding(x: 1, y: 1)
            .frame(width: 100, height: 10)
            .padding(1)
            .padding(x: 1, y: 1)

        let bars = collect(ProgressBar.self, from: deep)

        try #require(bars.count == 1)
        #expect(bars[0].label == "Core temperature")
    }

    // -------------------------------------------------------------------------
    // Existential lookup — the reason `collect` is generic over an unconstrained T
    // -------------------------------------------------------------------------

    @Test func `collect finds every button through the existential button type`() {
        let screen = VStack {
            Button(tag: "primary", action: {}) { Text(content: "Fire", fontSize: 8) }
            ShieldPanel(charge: 0.5)
            Button(tag: "secondary", action: {}) { Text(content: "Cloak", fontSize: 8) }
        }

        let buttons = collect((any AnyButton).self, from: screen)

        #expect(buttons.map(\.tag) == ["primary", "secondary"])
    }

    // -------------------------------------------------------------------------
    // The concrete generic specialisation is narrower than the existential.
    // Both spellings are supported and they do not mean the same thing.
    // -------------------------------------------------------------------------

    @Test func `a concrete button specialisation matches fewer buttons than the existential`() {
        let screen = VStack {
            Button(tag: "primary", action: {}) { Text(content: "Fire", fontSize: 8) }
            Button(tag: "secondary", action: {}) { Texture(textureName: "cloak") }
        }

        #expect(collect((any AnyButton).self, from: screen).count == 2)
        #expect(collect(Button<Text>.self, from: screen).map(\.tag) == ["primary"])
    }

    // -------------------------------------------------------------------------
    // Conveniences name intent; they must not diverge from the traversal beneath them.
    // -------------------------------------------------------------------------

    @Test func `each convenience agrees with the collect call it wraps`() {
        let screen = VStack {
            Button(tag: "primary", action: {}) { Text(content: "Fire", fontSize: 8) }
            Texture(textureName: "hull-icon")
            ProgressBar(value: 0.3, label: "Hull integrity")
        }

        // Positive control first. "Both sides are empty" is agreement of the useless kind,
        // and is precisely what the bug produced.
        #expect(collectButtons(from: screen).map(\.tag) == ["primary"])
        #expect(collectTextures(from: screen).map(\.textureName) == ["hull-icon"])
        #expect(collectProgressBars(from: screen).map(\.label) == ["Hull integrity"])

        #expect(collectButtons(from: screen).map(\.tag) == collect((any AnyButton).self, from: screen).map(\.tag))
        #expect(collectTextures(from: screen).map(\.textureName) == collect(Texture.self, from: screen).map(\.textureName))
        #expect(collectProgressBars(from: screen).map(\.label) == collect(ProgressBar.self, from: screen).map(\.label))
    }

    // -------------------------------------------------------------------------
    // The collectTexts / collectTextColors asymmetry, pinned deliberately.
    //
    // collectTexts covers Text AND WrappedText; collectTextColors covers Text ONLY.
    // Inherited verbatim from the field helper and retained on purpose: WrappedText
    // carries one colour for all its lines, so a merged colour list could not be
    // zipped against the content list. Documented, not silently smoothed over.
    // If someone "fixes" the asymmetry, this test is the conversation.
    // -------------------------------------------------------------------------

    @Test func `collectTexts reports both Text and WrappedText content`() {
        let screen = VStack {
            Text(content: "TRANSMISSION", fontSize: 10, color: .white)
            WrappedText(content: "hull breach on deck four", fontSize: 8, color: .red)
        }

        #expect(collectTexts(from: screen) == ["TRANSMISSION", "hull breach on deck four"])
    }

    @Test func `collectTextColors reports colours for Text only and leaves WrappedText out`() {
        let screen = VStack {
            Text(content: "TRANSMISSION", fontSize: 10, color: .white)
            WrappedText(content: "hull breach on deck four", fontSize: 8, color: .red)
        }

        // Two texts by content, one colour: the asymmetry is the point.
        #expect(collectTexts(from: screen).count == 2)
        #expect(collectTextColors(from: screen) == [.white])
    }

    // -------------------------------------------------------------------------
    // EDGE: the sought type is not in the tree. `[]` here is the CORRECT answer —
    // and it is also what the bug produced. The tests above are what make this one
    // trustworthy; on its own an empty result proves nothing.
    // -------------------------------------------------------------------------

    @Test func `collect returns nothing when the tree contains no view of that type`() {
        let screen = VStack {
            Text(content: "SYSTEMS", fontSize: 10)
            HStack {
                Texture(textureName: "hull-icon")
                Spacer()
            }
        }

        // Positive control: the walk DID happen. Without it, this test is satisfied by a
        // traversal that returns nothing for everything — the exact bug, passing.
        #expect(collectTexts(from: screen) == ["SYSTEMS"])
        #expect(collectTextures(from: screen).map(\.textureName) == ["hull-icon"])

        #expect(collect(ProgressBar.self, from: screen).isEmpty)
        #expect(collectProgressBars(from: screen).isEmpty)
    }

    // -------------------------------------------------------------------------
    // EDGE: degenerate tree — a leaf at the root that is not the sought type.
    // No children to walk, no body to resolve.
    // -------------------------------------------------------------------------

    @Test func `collect returns nothing for a bare leaf that is not the sought type`() {
        #expect(collect(ProgressBar.self, from: Spacer()).isEmpty)
        #expect(collect(ProgressBar.self, from: Text(content: "x", fontSize: 8)).isEmpty)
        #expect(collect(ProgressBar.self, from: Rectangle(color: .white)).isEmpty)

        // Positive control: each of those same leaves IS found when it is the sought type.
        // The empty results above are about the type asked for, not about the walk failing.
        #expect(collect(Spacer.self, from: Spacer()).count == 1)
        #expect(collect(Text.self, from: Text(content: "x", fontSize: 8)).count == 1)
        #expect(collect(Rectangle.self, from: Rectangle(color: .white)).count == 1)
    }

    // -------------------------------------------------------------------------
    // EDGE: a container whose single child is of another type. The container is
    // walked (it has a child) but yields nothing — distinguishable from a chain
    // that never entered the container at all only by the tests above.
    // -------------------------------------------------------------------------

    @Test func `collect returns nothing from a container holding only views of another type`() {
        let screen = ZStack {
            Rectangle(color: .darkGray)
        }

        #expect(collect(ProgressBar.self, from: screen).isEmpty)
        #expect(collect(Rectangle.self, from: screen).count == 1)
    }

    // -------------------------------------------------------------------------
    // EDGE: a composite whose body is itself a leaf of the sought type — one hop,
    // no container in between.
    // -------------------------------------------------------------------------

    @Test func `collect resolves a composite whose body is directly the sought view`() throws {
        struct BareGauge: View {
            var body: some View { ProgressBar(value: 0.75, label: "Reactor output") }
        }

        let bars = collect(ProgressBar.self, from: BareGauge())

        try #require(bars.count == 1)
        #expect(bars[0].label == "Reactor output")
    }

    // -------------------------------------------------------------------------
    // Purity: the traversal contract promises repeated calls are safe. `.body` is a
    // computed property, so a composite is rebuilt on every read; nothing may depend
    // on that.
    // -------------------------------------------------------------------------

    @Test func `collect returns the same result when called repeatedly on the same tree`() {
        let screen = VStack {
            ShieldPanel(charge: 0.65)
            AbilityRow()
        }

        let first = collectTexts(from: screen)
        let second = collectTexts(from: screen)

        // Positive control: `[] == []` is stable and worthless.
        #expect(first == ["Shields", "Boost"])
        #expect(first == second)
        #expect(collectProgressBars(from: screen).count == 2)
        #expect(collectProgressBars(from: screen).map(\.label) == collectProgressBars(from: screen).map(\.label))
    }
}
