// DirectionalPaddingTests.swift — Acceptance tests for padding(x:y:) directional modifier
// Feature: padding-directional | Stories: US-PDR-01, US-PDR-02
// Driving ports:
//   Layout:   LayoutEngine.layout(_:in:)       — public method on LayoutEngine
//   Hit-test: hitTestButton(view:node:at:)      — public free function in GameUI module

import Testing
@testable import GameUI

// MARK: - Walking Skeleton

@Suite("Directional Padding — Walking Skeleton")
struct DirectionalPaddingWalkingSkeletonTests {

    @Test func `Walking skeleton — padding(x:y:) on framed view produces correct outer frame`() {
        // Driving port: LayoutEngine.layout(_:in:)
        // End-to-end path: View.padding(x:y:) → DirectionalPaddingModifier → layoutNode dispatch
        //                  → layoutDirectionalPaddingNode → LayoutNode with correct outer frame
        let view = Rectangle().frame(width: 100, height: 50)
            .padding(x: 20, y: 10)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        let tree = LayoutEngine().layout(view, in: constraints)

        #expect(tree.root.frame.size.width == 140)
        #expect(tree.root.frame.size.height == 70)
    }
}

// MARK: - US-PDR-01: Directional Padding Layout

@Suite("Directional Padding — Layout (US-PDR-01)")
struct DirectionalPaddingLayoutTests {

    // AC-1: happy path — both axes carry padding
    @Test func `padding(x:20 y:10) on 100x50 view produces outer frame 140x70`() {
        let view = Rectangle().frame(width: 100, height: 50)
            .padding(x: 20, y: 10)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        let tree = LayoutEngine().layout(view, in: constraints)

        #expect(tree.root.frame.size.width == 140)
        #expect(tree.root.frame.size.height == 70)
    }

    // AC-2: zero x — width must NOT change; only height is inset
    // (also guards against axis transposition: if x and y are swapped, width would change)
    @Test func `padding(x:0 y:10) on 80x40 view leaves width unchanged and adds 20 to height`() {
        let view = Rectangle().frame(width: 80, height: 40)
            .padding(x: 0, y: 10)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        let tree = LayoutEngine().layout(view, in: constraints)

        #expect(tree.root.frame.size.width == 80)
        #expect(tree.root.frame.size.height == 60)
    }

    // AC-3: zero y — height must NOT change; only width is inset
    // (mirror of AC-2: independently verifies axis assignment)
    @Test func `padding(x:10 y:0) on 80x40 view adds 20 to width and leaves height unchanged`() {
        let view = Rectangle().frame(width: 80, height: 40)
            .padding(x: 10, y: 0)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        let tree = LayoutEngine().layout(view, in: constraints)

        #expect(tree.root.frame.size.width == 100)
        #expect(tree.root.frame.size.height == 40)
    }

    // AC-4: child origin is inset by (paddingX, paddingY) from the outer frame origin
    @Test func `padding(x:20 y:10) places child at (20, 10) within outer frame`() throws {
        let view = Rectangle().frame(width: 100, height: 50)
            .padding(x: 20, y: 10)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        let tree = LayoutEngine().layout(view, in: constraints)

        let child = try #require(tree.root.children.first, "Expected child node inside directional padding wrapper")
        #expect(child.frame.origin.x == 20)
        #expect(child.frame.origin.y == 10)
    }

    // AC-5: outer frame is clamped to available constraints
    @Test func `padding(x:20 y:20) on 90x90 view in 100x100 constraints clamps outer frame to 100x100`() {
        let view = Rectangle().frame(width: 90, height: 90)
            .padding(x: 20, y: 20)
        let constraints = LayoutConstraints(maxWidth: 100, maxHeight: 100)

        let tree = LayoutEngine().layout(view, in: constraints)

        #expect(tree.root.frame.size.width <= 100)
        #expect(tree.root.frame.size.height <= 100)
    }

    // AC-6: zero on both axes — outer frame equals content frame
    @Test func `padding(x:0 y:0) produces outer frame identical to unwrapped content frame`() {
        let view = Rectangle().frame(width: 60, height: 30)
            .padding(x: 0, y: 0)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        let tree = LayoutEngine().layout(view, in: constraints)

        #expect(tree.root.frame.size.width == 60)
        #expect(tree.root.frame.size.height == 30)
    }

    // AC-7: negative values are silently clamped to zero — no crash, frame equals content
    @Test func `padding(x:-5 y:-10) is treated as padding(x:0 y:0) — negative values clamped`() {
        let view = Rectangle().frame(width: 60, height: 40)
            .padding(x: -5, y: -10)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        let tree = LayoutEngine().layout(view, in: constraints)

        #expect(tree.root.frame.size.width == 60)
        #expect(tree.root.frame.size.height == 40)
    }
}

// MARK: - US-PDR-02: Hit-Test Traversal Through Directional Padding

@Suite("Directional Padding — Hit-Test Traversal (US-PDR-02)")
struct DirectionalPaddingHitTestTests {

    // AC-1: button wrapped in directional padding is reachable via hitTestButton
    @Test func `hitTestButton reaches button wrapped in padding(x:10 y:5) and returns index 0`() {
        let view = Button(action: {}) {
            Rectangle().frame(width: 100, height: 40)
        }.padding(x: 10, y: 5)
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 100)
        let tree = LayoutEngine().layout(view, in: constraints)

        let mid = Point(
            x: tree.root.frame.origin.x + tree.root.frame.size.width / 2,
            y: tree.root.frame.origin.y + tree.root.frame.size.height / 2
        )

        let result = hitTestButton(view: view, node: tree.root, at: mid)
        #expect(result == 0)
    }

    // AC-2a: point inside padded frame → index returned
    @Test func `point inside directionally padded button frame returns the button index`() {
        let view = Button(action: {}) {
            Rectangle().frame(width: 100, height: 40)
        }.padding(x: 10, y: 5)
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 100)
        let tree = LayoutEngine().layout(view, in: constraints)

        // Top-left corner of outer padded frame — inclusive boundary
        let topLeft = tree.root.frame.origin

        let result = hitTestButton(view: view, node: tree.root, at: topLeft)
        #expect(result == 0)
    }

    // AC-2b: point outside outer padded frame → nil
    @Test func `point outside directionally padded button frame returns nil`() {
        let view = Button(action: {}) {
            Rectangle().frame(width: 100, height: 40)
        }.padding(x: 10, y: 5)
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 100)
        let tree = LayoutEngine().layout(view, in: constraints)

        let outside = Point(x: 1000, y: 1000)

        let result = hitTestButton(view: view, node: tree.root, at: outside)
        #expect(result == nil)
    }

    // AC-3: button wrapped in directional padding inside VStack → correct index
    @Test func `hitTestButton returns correct index for directionally padded button inside VStack`() {
        let view = VStack(spacing: 0) {
            Button(action: {}) { Rectangle().frame(width: 100, height: 40) }
            Button(action: {}) { Rectangle().frame(width: 100, height: 40) }.padding(x: 8, y: 4)
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 200)
        let tree = LayoutEngine().layout(view, in: constraints)

        // Second button (index 1) is wrapped in directional padding
        let secondNode = tree.root.children[1]
        let mid = Point(
            x: secondNode.frame.origin.x + secondNode.frame.size.width / 2,
            y: secondNode.frame.origin.y + secondNode.frame.size.height / 2
        )

        let result = hitTestButton(view: view, node: tree.root, at: mid)
        #expect(result == 1)
    }

    // AC-4: button action is never invoked during hit-test traversal
    @Test func `hitTestButton does not invoke button action when traversing through directional padding`() {
        nonisolated(unsafe) var callCount = 0
        let view = Button(action: { callCount += 1 }) {
            Rectangle().frame(width: 100, height: 40)
        }.padding(x: 10, y: 5)
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 100)
        let tree = LayoutEngine().layout(view, in: constraints)

        let mid = Point(
            x: tree.root.frame.origin.x + tree.root.frame.size.width / 2,
            y: tree.root.frame.origin.y + tree.root.frame.size.height / 2
        )
        _ = hitTestButton(view: view, node: tree.root, at: mid)
        _ = hitTestButton(view: view, node: tree.root, at: Point(x: 1000, y: 1000))

        #expect(callCount == 0)
    }
}

// MARK: - Dispatch Verification: PaddingModifier reaches unified AnyDirectionalPaddingModifier branch

@Suite("Directional Padding — Dispatch Verification (Option B)")
struct PaddingDispatchVerificationTests {

    // Verifies that PaddingModifier is dispatched through the AnyDirectionalPaddingModifier
    // branch after Option B changes, not through the deprecated AnyPaddingModifier branch.
    //
    // Expected values assume content-box semantics (Option X from DISTILL DWD-04):
    //   outer = content.size + 2*padding
    // If the crafter chooses border-box (Option Z), update to: width == 100, height == 50.
    @Test func `PaddingModifier dispatched through AnyDirectionalPaddingModifier produces content-box outer frame`() {
        let view = Rectangle().frame(width: 100, height: 50)
            .padding(20)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        let tree = LayoutEngine().layout(view, in: constraints)

        // Content-box: outer = content + 2 * amount (100+40 × 50+40)
        // If this fails after implementation with actual = 100×50, the AnyPaddingModifier
        // (border-box) dispatch branch is still active — the replacement was not applied.
        #expect(tree.root.frame.size.width == 140)
        #expect(tree.root.frame.size.height == 90)
    }
}

// MARK: - Regression: existing uniform padding must still work (Option B conformance check)
//
// NOTE (DISTILL upstream issue): the existing layoutPaddingNode uses border-box semantics for
// HasFrameSize content (outer frame = content's declared size, padding squeezes content inward).
// The DISCUSS ACs for DirectionalPaddingModifier specify content-box semantics (outer grows).
// If the crafter implements layoutDirectionalPaddingNode as content-box AND routes PaddingModifier
// through it (Option B), the existing LayoutEngineTests "padding modifier insets child origin and
// reduces child size" test (child.size.width == 90) will break — see wave-decisions.md.
//
// This regression suite only asserts the behavior that is unambiguous (child origin), not the
// outer frame, which depends on the box-sizing decision the crafter makes.

@Suite("Directional Padding — Regression: Uniform Padding Unaffected")
struct UniformPaddingRegressionTests {

    @Test func `existing padding(_ amount:) child origin is inset uniformly on both axes`() throws {
        let view = Rectangle().frame(width: 100, height: 50)
            .padding(20)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        let tree = LayoutEngine().layout(view, in: constraints)

        let child = try #require(tree.root.children.first, "Expected child node inside uniform padding wrapper")
        #expect(child.frame.origin.x == 20)
        #expect(child.frame.origin.y == 20)
    }
}
