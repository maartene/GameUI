// View Traversal Slice 2 — ViewTraversalCoverageTests
//
// Driving port (traversal):  GameUI.childViews(of:)
// Driving port (collection): GameUITesting.collect(_:from:)
//
// THIS SUITE IS HALF THE ENFORCEMENT MECHANISM, NOT GARNISH. ADR-006 Decision 3 depends on
// it existing, and says so in as many words.
//
// The traversal registry in `ViewTraversal.swift` is checked by a CI grep that proves a type
// was *considered*. It cannot prove the accessor written for it is *correct*:
// `// traversal: Grid leaf` on a child-bearing type satisfies the grep and reproduces the
// original field bug exactly. This suite covers the second half — for every child-bearing
// type in `Sources/GameUI/`, construct it around a uniquely identifiable sentinel and assert
// the sentinel is actually reached.
//
// The two mechanisms fail differently, which is the point: the grep names the type you
// forgot; this suite names the type you mis-described.
//
// Enable tests one at a time in DELIVER; each maps to one TDD cycle.

import Testing
import GameUI
import GameUITesting

// MARK: - Sentinel
//
// A view type that exists nowhere else, so reaching it cannot be an accident of some other
// branch. It carries an `id` so a test can say WHICH sentinel came back, not merely that one
// did — a chain that returns the wrong child still fails.
//
// It is declared in the test target, outside `Sources/GameUI/`, so it correctly needs no
// traversal registry entry.
private struct TraversalSentinel: View {
    let id: String
    var body: Never { fatalError("TraversalSentinel is a primitive view") }
}

/// A composite sentinel holder — `Body != Never`, so only `childViews`' composite fallback
/// reaches inside it.
private struct SentinelComposite: View {
    let id: String
    var body: some View { TraversalSentinel(id: id) }
}

/// A view whose `body` returns another instance of itself: a cycle, not a tree.
/// Used only inside the ODQ-VT-04 exit test below, where the trap is the behaviour under test.
private struct CyclicView: View {
    var body: CyclicView { CyclicView() }
}

private func sentinelIDs(in view: some View) -> [String] {
    collect(TraversalSentinel.self, from: view).map(\.id)
}

@Suite("View Traversal — registry coverage")
struct ViewTraversalSlice2CoverageTests {

    // =========================================================================
    // MARK: Child-bearing types — one per `// traversal: <Type> children <Accessor>` line
    //
    // Each asserts BOTH halves: `childViews` reports the right arity directly, and the
    // sentinel is actually retrievable through `collect`. Arity alone would pass for a
    // branch that returns the wrong child.
    // =========================================================================

    @Test func `VStack reports its declared children and the sentinel inside is reached`() {
        let stack = VStack(spacing: 2) {
            TraversalSentinel(id: "vstack-first")
            TraversalSentinel(id: "vstack-second")
        }

        #expect(childViews(of: stack).count == 2)
        #expect(sentinelIDs(in: stack) == ["vstack-first", "vstack-second"])
    }

    @Test func `HStack reports its declared children and the sentinel inside is reached`() {
        let stack = HStack(spacing: 2) {
            TraversalSentinel(id: "hstack-first")
            TraversalSentinel(id: "hstack-second")
        }

        #expect(childViews(of: stack).count == 2)
        #expect(sentinelIDs(in: stack) == ["hstack-first", "hstack-second"])
    }

    @Test func `ZStack reports its declared children and the sentinel inside is reached`() {
        let stack = ZStack {
            TraversalSentinel(id: "zstack-back")
            TraversalSentinel(id: "zstack-front")
        }

        #expect(childViews(of: stack).count == 2)
        #expect(sentinelIDs(in: stack) == ["zstack-back", "zstack-front"])
    }

    // A stack holding exactly one view does not produce a TupleView at all — the builder
    // returns the child directly and `containerChildren` wraps it. Different code path
    // from the multi-child case above, and the one a single-element stack takes.
    @Test func `a stack holding a single view reaches that view`() {
        #expect(sentinelIDs(in: VStack { TraversalSentinel(id: "only") }) == ["only"])
        #expect(sentinelIDs(in: HStack { TraversalSentinel(id: "only") }) == ["only"])
        #expect(sentinelIDs(in: ZStack { TraversalSentinel(id: "only") }) == ["only"])
    }

    @Test func `FrameModifier reports its framed content and the sentinel inside is reached`() {
        let framed = TraversalSentinel(id: "framed").frame(width: 40, height: 12)

        #expect(childViews(of: framed).count == 1)
        #expect(sentinelIDs(in: framed) == ["framed"])
    }

    @Test func `PaddingModifier reports its padded content and the sentinel inside is reached`() {
        let padded = TraversalSentinel(id: "uniformly-padded").padding(3)

        // Dispatched through AnyDirectionalPaddingModifier, NOT the deprecated
        // AnyPaddingModifier. A second padding branch would resurrect the dispatch-order
        // fragility ADR-003 closed, so there is deliberately only one.
        #expect(childViews(of: padded).count == 1)
        #expect(sentinelIDs(in: padded) == ["uniformly-padded"])
    }

    @Test func `DirectionalPaddingModifier reports its padded content and the sentinel inside is reached`() {
        let padded = TraversalSentinel(id: "directionally-padded").padding(x: 4, y: 2)

        #expect(childViews(of: padded).count == 1)
        #expect(sentinelIDs(in: padded) == ["directionally-padded"])
    }

    @Test func `Button reports its content and the sentinel inside is reached`() {
        let button = Button(tag: "primary", action: {}) {
            TraversalSentinel(id: "button-label")
        }

        #expect(childViews(of: button).count == 1)
        #expect(sentinelIDs(in: button) == ["button-label"])
    }

    @Test func `TupleView2 reports both children and both sentinels are reached`() {
        let tuple = TupleView2(TraversalSentinel(id: "t2-a"), TraversalSentinel(id: "t2-b"))

        #expect(childViews(of: tuple).count == 2)
        #expect(sentinelIDs(in: tuple) == ["t2-a", "t2-b"])
    }

    @Test func `TupleView3 reports all three children and all three sentinels are reached`() {
        let tuple = TupleView3(
            TraversalSentinel(id: "t3-a"),
            TraversalSentinel(id: "t3-b"),
            TraversalSentinel(id: "t3-c")
        )

        #expect(childViews(of: tuple).count == 3)
        #expect(sentinelIDs(in: tuple) == ["t3-a", "t3-b", "t3-c"])
    }

    @Test func `TupleView4 reports all four children and all four sentinels are reached`() {
        let tuple = TupleView4(
            TraversalSentinel(id: "t4-a"),
            TraversalSentinel(id: "t4-b"),
            TraversalSentinel(id: "t4-c"),
            TraversalSentinel(id: "t4-d")
        )

        #expect(childViews(of: tuple).count == 4)
        #expect(sentinelIDs(in: tuple) == ["t4-a", "t4-b", "t4-c", "t4-d"])
    }

    // The composite fallback has no registry line — it is a property of `Body != Never`
    // rather than of any one type — but it is the branch both field incidents lost, so it
    // gets the same sentinel treatment as the named types.
    @Test func `a composite view reports its body and the sentinel inside is reached`() {
        let composite = SentinelComposite(id: "inside-a-body")

        #expect(childViews(of: composite).count == 1)
        #expect(sentinelIDs(in: composite) == ["inside-a-body"])
    }

    // -------------------------------------------------------------------------
    // Aggregate guard: every child-bearing type at once.
    //
    // This is what actually catches `// traversal: Grid leaf` on a type that has
    // children — a new child-bearing type added without a branch shows up here as
    // one named empty entry, next to eleven non-empty ones.
    // -------------------------------------------------------------------------

    @Test func `every child-bearing view type reports at least one child`() {
        let childBearing: [(name: String, view: any View)] = [
            ("VStack", VStack { TraversalSentinel(id: "x") }),
            ("HStack", HStack { TraversalSentinel(id: "x") }),
            ("ZStack", ZStack { TraversalSentinel(id: "x") }),
            ("FrameModifier", TraversalSentinel(id: "x").frame(width: 1, height: 1)),
            ("PaddingModifier", TraversalSentinel(id: "x").padding(1)),
            ("DirectionalPaddingModifier", TraversalSentinel(id: "x").padding(x: 1, y: 1)),
            ("Button", Button(action: {}) { TraversalSentinel(id: "x") }),
            ("TupleView2", TupleView2(TraversalSentinel(id: "x"), TraversalSentinel(id: "y"))),
            ("TupleView3", TupleView3(TraversalSentinel(id: "x"), TraversalSentinel(id: "y"), TraversalSentinel(id: "z"))),
            ("TupleView4", TupleView4(TraversalSentinel(id: "w"), TraversalSentinel(id: "x"), TraversalSentinel(id: "y"), TraversalSentinel(id: "z"))),
            ("composite body", SentinelComposite(id: "x")),
        ]

        // The `let` binding is load-bearing, not style — but the reason is narrower than a
        // first read suggests. Passing a TUPLE ELEMENT of an implicitly-typed closure
        // parameter to a generic parameter defeats implicit existential opening:
        // `childBearing.filter { childViews(of: $0.view).isEmpty }` fails with
        // "type 'any View' cannot conform to 'View'" (#ProtocolTypeNonConformance).
        // A struct property in the same position compiles, as does a bare `any View`
        // element, as does this member access outside a closure. Annotating the closure's
        // parameter type fixes it too — annotating only its result type does not.
        // This is a type-checker limitation in one syntactic position, NOT a restriction on
        // ADR-006 Decision 2's call-site contract, which holds as written.
        var childless: [String] = []
        for entry in childBearing {
            let view = entry.view
            if childViews(of: view).isEmpty { childless.append(entry.name) }
        }

        #expect(childless.isEmpty, "child-bearing types reporting no children: \(childless)")
    }

    // =========================================================================
    // MARK: Leaf types — one per `// traversal: <Type> leaf` line
    //
    // Each asserts BOTH halves deliberately. "Reports no children" alone is satisfied by a
    // traversal that returns nothing for everything — which is precisely the bug. Pairing it
    // with "is still reached when nested" is what makes the leaf claim mean something.
    // =========================================================================

    @Test func `Text is a leaf and is still reached when nested`() {
        let leaf = Text(content: "SYSTEMS", fontSize: 10, color: .white)

        #expect(childViews(of: leaf).isEmpty)
        #expect(collect(Text.self, from: VStack { leaf }).map(\.content) == ["SYSTEMS"])
    }

    @Test func `WrappedText is a leaf and is still reached when nested`() {
        let leaf = WrappedText(content: "hull breach on deck four", fontSize: 8, color: .red)

        // Its LayoutNode children are generated geometry, not views, so they are not
        // collectable and `childViews` must not invent them.
        #expect(childViews(of: leaf).isEmpty)
        #expect(collect(WrappedText.self, from: VStack { leaf }).map(\.content) == ["hull breach on deck four"])
    }

    @Test func `Rectangle is a leaf and is still reached when nested`() {
        let leaf = Rectangle(color: .darkGray)

        #expect(childViews(of: leaf).isEmpty)
        #expect(collect(Rectangle.self, from: VStack { leaf }).map(\.color) == [.darkGray])
    }

    @Test func `Texture is a leaf and is still reached when nested`() {
        let leaf = Texture(textureName: "hull-icon", tint: .white)

        #expect(childViews(of: leaf).isEmpty)
        #expect(collect(Texture.self, from: VStack { leaf }).map(\.textureName) == ["hull-icon"])
    }

    @Test func `Spacer is a leaf and is still reached when nested`() {
        let leaf = Spacer()

        #expect(childViews(of: leaf).isEmpty)
        #expect(collect(Spacer.self, from: VStack { leaf }).count == 1)
    }

    @Test func `Slider is a leaf and is still reached when nested`() {
        let leaf = Slider(value: 0.5, label: "Thruster power")

        #expect(childViews(of: leaf).isEmpty)
        #expect(collect(Slider.self, from: VStack { leaf }).map(\.label) == ["Thruster power"])
    }

    @Test func `Checkbox is a leaf and is still reached when nested`() {
        let leaf = Checkbox(isChecked: true, label: "Autopilot")

        #expect(childViews(of: leaf).isEmpty)
        #expect(collect(Checkbox.self, from: VStack { leaf }).map(\.label) == ["Autopilot"])
    }

    // -------------------------------------------------------------------------
    // ADR-005: ProgressBar conforms to NO dispatch protocol.
    //
    // That standing constraint used to need five negative conformance assertions. With the
    // registry it becomes one line (`// traversal: ProgressBar leaf`) plus this test.
    // -------------------------------------------------------------------------

    @Test func `ProgressBar is a leaf conforming to no dispatch protocol and is still reached when nested`() {
        let leaf = ProgressBar(value: 0.65, label: "Shield charge")

        #expect(!(leaf is any ContainerView))
        #expect(!(leaf is any ZStackView))
        #expect(!(leaf is any AnyButton))
        #expect(!(leaf is any HasFrameSize))
        #expect(!(leaf is any AnyDirectionalPaddingModifier))
        #expect(!(leaf is any ChildrenProviding))

        #expect(childViews(of: leaf).isEmpty)
        #expect(collect(ProgressBar.self, from: VStack { leaf }).map(\.label) == ["Shield charge"])
    }

    // -------------------------------------------------------------------------
    // Aggregate guard: every registered leaf at once.
    //
    // The mirror of the child-bearing aggregate. Fails when a type registered `leaf`
    // starts producing children — the opposite drift, and the one the CI grep is
    // equally blind to.
    // -------------------------------------------------------------------------

    @Test func `every registered leaf type reports no children yet is reachable when nested`() {
        // Each row carries the leaf AND the same leaf wrapped in a stack. Both are built
        // concretely here because GameUI has no type-eraser: a composite's body must be
        // `some View`, and `any View` does not conform to `View`.
        let leaves: [(name: String, leaf: any View, nested: any View)] = [
            ("Text", Text(content: "x", fontSize: 8),
                     VStack { Text(content: "x", fontSize: 8) }),
            ("WrappedText", WrappedText(content: "x", fontSize: 8, color: .white),
                            VStack { WrappedText(content: "x", fontSize: 8, color: .white) }),
            ("Rectangle", Rectangle(color: .white),
                          VStack { Rectangle(color: .white) }),
            ("Texture", Texture(textureName: "x"),
                        VStack { Texture(textureName: "x") }),
            ("Spacer", Spacer(),
                       VStack { Spacer() }),
            ("Slider", Slider(value: 0.5, label: "x"),
                       VStack { Slider(value: 0.5, label: "x") }),
            ("Checkbox", Checkbox(isChecked: false, label: "x"),
                         VStack { Checkbox(isChecked: false, label: "x") }),
            ("ProgressBar", ProgressBar(value: 0.5, label: "x"),
                            VStack { ProgressBar(value: 0.5, label: "x") }),
        ]

        var bearing: [String] = []
        var unreachable: [String] = []
        for entry in leaves {
            let leaf = entry.leaf
            let nested = entry.nested
            if !childViews(of: leaf).isEmpty { bearing.append(entry.name) }
            if childViews(of: nested).isEmpty { unreachable.append(entry.name) }
        }

        #expect(bearing.isEmpty, "types registered as leaves reporting children: \(bearing)")

        // The positive control, and it is not optional. On its own the assertion above is
        // satisfied by a traversal that reports no children for ANYTHING — which is the bug,
        // passing. "This type is a leaf" only means something alongside "and the walk that
        // concluded so is a walk that works".
        #expect(unreachable.isEmpty, "leaf types unreachable when nested: \(unreachable)")
    }

    // =========================================================================
    // MARK: The Never-body trap, and why the leaf assertions above are not vacuous
    // =========================================================================

    // Every primitive declares `var body: Never { fatalError("… is a primitive view") }`.
    // That trap is exactly what fires if `childViews` ever routes a primitive down the
    // composite `V.Body.self != Never.self` branch. This exit test proves the trap is
    // genuinely reachable — which is what makes "childViews(of: Text(...)) returned without
    // trapping" an observation rather than a tautology.
    //
    // Asserts `.failure`, not a specific signal: `fatalError` surfaces as SIGILL or SIGTRAP
    // depending on platform, and pinning one would go green on one CI runner and red on the
    // other. The contract we care about is that the process terminates.
    @Test func `reading a primitive view's body traps`() async {
        await #expect(processExitsWith: .failure) {
            _ = Text(content: "SYSTEMS", fontSize: 10).body
        }
    }

    @Test func `no registered leaf type traps when asked for its children`() {
        // Absence of a crash is the assertion. If `childViews` mis-routes any of these down
        // the composite branch, this test does not fail — it takes the process down, which
        // is itself an unmistakable signal, and the exit test above is what proves that
        // signal exists.
        #expect(childViews(of: Text(content: "x", fontSize: 8)).isEmpty)
        #expect(childViews(of: WrappedText(content: "x", fontSize: 8, color: .white)).isEmpty)
        #expect(childViews(of: Rectangle(color: .white)).isEmpty)
        #expect(childViews(of: Texture(textureName: "x")).isEmpty)
        #expect(childViews(of: Spacer()).isEmpty)
        #expect(childViews(of: Slider(value: 0.5, label: "x")).isEmpty)
        #expect(childViews(of: Checkbox(isChecked: false, label: "x")).isEmpty)
        #expect(childViews(of: ProgressBar(value: 0.5, label: "x")).isEmpty)

        // Positive control: a genuine composite DOES get its body read, and does not trap
        // either. Without this line, "nothing trapped" is equally true of a traversal that
        // never dispatches at all.
        #expect(childViews(of: SentinelComposite(id: "reached")).count == 1)
    }

    // =========================================================================
    // MARK: ODQ-VT-04 — the cyclic-body precondition, made executable
    // =========================================================================

    // DESIGN recommended "no guard, documented precondition"; DISTILL confirms it (see the
    // feature-delta for the reasoning). This test is what stops that being a prose caveat
    // nobody can check.
    //
    // The contract it pins is NOT "we handle cycles". It is the three-way distinction that
    // matters to a caller: given a view whose `body` returns a view containing itself,
    // `collect` TERMINATES THE PROCESS — it does not hang forever, and it does not return a
    // plausible-but-wrong result that a test would then assert against. Loud failure on a
    // precondition violation, which is what `hitTestButton`'s isomorphism precondition and
    // `layoutNode`'s identical exposure already give.
    //
    // `.failure` rather than `.signal(SIGSEGV)`: a stack overflow surfaces as SIGSEGV or
    // SIGBUS depending on platform and stack-guard behaviour, and both CI jobs must agree.
    //
    // The tree is built inside the closure because exit-test closures cannot capture from
    // the enclosing scope — the child process is a fresh spawn.
    @Test func `collecting from a view whose body contains itself terminates rather than hanging`() async {
        await #expect(processExitsWith: .failure) {
            _ = collect(CyclicView.self, from: CyclicView())
        }
    }
}
