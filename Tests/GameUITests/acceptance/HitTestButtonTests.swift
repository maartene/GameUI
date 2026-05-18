// HitTestButtonTests.swift — Acceptance tests for hitTestButton(view:node:at:)
// Feature: hit-test-button | Story: US-01
// Driving port: hitTestButton(view:node:at:) — public free function in GameUI module
//
// WS Strategy A: pure in-memory. All views constructed inline. No I/O.
// Enable tests one at a time in DELIVER; each maps to one TDD cycle.
// First test (walking skeleton) is enabled. All others carry .disabled trait.
//
// ODQ-01 note: Rect.contains must be fixed to inclusive (<=) before AC-06
// boundary tests (Tests 11 and 12) can pass. Crafter performs that fix first.

import Testing
@testable import GameUI

// MARK: - Acceptance Suite

@Suite("Hit Test Button — Button Identification by Screen Position")
struct HitTestButtonTests {

    // -------------------------------------------------------------------------
    // Walking Skeleton (US-01)
    // Answers: "Can Riku call hitTestButton and receive the index of the button
    // his cursor is over?"
    // ENABLED — RED on scaffold (scaffold returns nil; expects 0).
    // -------------------------------------------------------------------------

    @Test("Walking skeleton — cursor over single button returns its index")
    func walkingSkeletonCursorOverSingleButtonReturnsIndex() {
        // Riku has one button constrained to an explicit 200×40 frame.
        // Rectangle fills its constraints, so the button frame is 200×40 at origin (0, 0).
        let view = Button(action: {}) {
            Rectangle().frame(width: 200, height: 40)
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 40)
        let tree = LayoutEngine().layout(view, in: constraints)

        // Cursor is at the centre of the button frame.
        let buttonNode = tree.root
        let midX = buttonNode.frame.origin.x + buttonNode.frame.size.width / 2
        let midY = buttonNode.frame.origin.y + buttonNode.frame.size.height / 2

        let result = hitTestButton(view: view, node: tree.root, at: Point(x: midX, y: midY))
        #expect(result == 0)
    }

    // -------------------------------------------------------------------------
    // AC-02: Returns traversal-order index of first AnyButton containing point
    // -------------------------------------------------------------------------

    @Test("Cursor over first of two buttons returns index 0",
)
    func cursorOverFirstButtonReturnsIndexZero() {
        let view = VStack(spacing: 20) {
            Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
            Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 200)
        let tree = LayoutEngine().layout(view, in: constraints)

        let firstButtonNode = tree.root.children[0]
        let midX = firstButtonNode.frame.origin.x + firstButtonNode.frame.size.width / 2
        let midY = firstButtonNode.frame.origin.y + firstButtonNode.frame.size.height / 2

        let result = hitTestButton(view: view, node: tree.root, at: Point(x: midX, y: midY))
        #expect(result == 0)
    }

    @Test("Cursor over second of two buttons returns index 1",
)
    func cursorOverSecondButtonReturnsIndexOne() {
        let view = VStack(spacing: 20) {
            Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
            Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 200)
        let tree = LayoutEngine().layout(view, in: constraints)

        let secondButtonNode = tree.root.children[1]
        let midX = secondButtonNode.frame.origin.x + secondButtonNode.frame.size.width / 2
        let midY = secondButtonNode.frame.origin.y + secondButtonNode.frame.size.height / 2

        let result = hitTestButton(view: view, node: tree.root, at: Point(x: midX, y: midY))
        #expect(result == 1)
    }

    // -------------------------------------------------------------------------
    // AC-03: Returns nil when no AnyButton frame contains point
    // -------------------------------------------------------------------------

    @Test("Cursor in gap between two buttons returns nil",
)
    func cursorBetweenButtonsReturnsNil() {
        // spacing: 20 creates a 20-point gap. With two 40-tall buttons:
        // button 0 occupies y: 0–40, gap occupies y: 40–60, button 1 occupies y: 60–100.
        let view = VStack(spacing: 20) {
            Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
            Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 200)
        let tree = LayoutEngine().layout(view, in: constraints)

        let endOfFirst = tree.root.children[0].frame.origin.y + tree.root.children[0].frame.size.height
        let startOfSecond = tree.root.children[1].frame.origin.y
        let gapMidY = endOfFirst + (startOfSecond - endOfFirst) / 2

        let result = hitTestButton(view: view, node: tree.root, at: Point(x: 100, y: gapMidY))
        #expect(result == nil)
    }

    @Test("Cursor far outside all button frames returns nil",
)
    func cursorOutsideAllButtonsReturnsNil() {
        let view = VStack(spacing: 0) {
            Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
            Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 600)
        let tree = LayoutEngine().layout(view, in: constraints)

        // Point far below all buttons (buttons end at y: 80)
        let result = hitTestButton(view: view, node: tree.root, at: Point(x: 100, y: 500))
        #expect(result == nil)
    }

    @Test("View tree containing no buttons always returns nil",
)
    func viewTreeWithNoButtonsReturnsNil() {
        let view = VStack(spacing: 0) {
            Rectangle().frame(width: 200, height: 40)
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 40)
        let tree = LayoutEngine().layout(view, in: constraints)

        let result = hitTestButton(view: view, node: tree.root, at: Point(x: 100, y: 20))
        #expect(result == nil)
    }

    // -------------------------------------------------------------------------
    // AC-04: Traversal is depth-first, matching view-tree construction order
    // -------------------------------------------------------------------------

    @Test("Three buttons in VStack are indexed 0, 1, 2 in top-to-bottom construction order",
)
    func threeButtonsIndexedInConstructionOrder() {
        let view = VStack(spacing: 0) {
            Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
            Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
            Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 600)
        let tree = LayoutEngine().layout(view, in: constraints)

        let node0 = tree.root.children[0]
        let node1 = tree.root.children[1]
        let node2 = tree.root.children[2]

        let mid0 = Point(x: 100, y: node0.frame.origin.y + node0.frame.size.height / 2)
        let mid1 = Point(x: 100, y: node1.frame.origin.y + node1.frame.size.height / 2)
        let mid2 = Point(x: 100, y: node2.frame.origin.y + node2.frame.size.height / 2)

        #expect(hitTestButton(view: view, node: tree.root, at: mid0) == 0)
        #expect(hitTestButton(view: view, node: tree.root, at: mid1) == 1)
        #expect(hitTestButton(view: view, node: tree.root, at: mid2) == 2)
    }

    // -------------------------------------------------------------------------
    // AC-05: Works when buttons are nested inside containers
    // -------------------------------------------------------------------------

    @Test("Button inside nested VStack is reachable and returns correct index",
)
    func buttonInsideNestedVStackIsReachable() {
        // Outer VStack contains one inner VStack which holds two buttons.
        let view = VStack(spacing: 0) {
            VStack(spacing: 0) {
                Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
                Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
            }
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 600)
        let tree = LayoutEngine().layout(view, in: constraints)

        // tree.root = outer VStack node
        // tree.root.children[0] = inner VStack node
        // tree.root.children[0].children[1] = second button node
        let innerStack = tree.root.children[0]
        let secondButtonNode = innerStack.children[1]
        let midX = secondButtonNode.frame.origin.x + secondButtonNode.frame.size.width / 2
        let midY = secondButtonNode.frame.origin.y + secondButtonNode.frame.size.height / 2

        let result = hitTestButton(view: view, node: tree.root, at: Point(x: midX, y: midY))
        #expect(result == 1)
    }

    @Test("Buttons inside HStack are indexed by horizontal construction order",
)
    func buttonsInsideHStackIndexedByPosition() {
        let view = HStack(spacing: 0) {
            Button(action: {}) { Rectangle().frame(width: 100, height: 40) }
            Button(action: {}) { Rectangle().frame(width: 100, height: 40) }
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 40)
        let tree = LayoutEngine().layout(view, in: constraints)

        let firstButtonNode = tree.root.children[0]
        let secondButtonNode = tree.root.children[1]

        let mid0 = Point(
            x: firstButtonNode.frame.origin.x + firstButtonNode.frame.size.width / 2,
            y: firstButtonNode.frame.origin.y + firstButtonNode.frame.size.height / 2
        )
        let mid1 = Point(
            x: secondButtonNode.frame.origin.x + secondButtonNode.frame.size.width / 2,
            y: secondButtonNode.frame.origin.y + secondButtonNode.frame.size.height / 2
        )

        #expect(hitTestButton(view: view, node: tree.root, at: mid0) == 0)
        #expect(hitTestButton(view: view, node: tree.root, at: mid1) == 1)
    }

    @Test("Button inside FrameModifier panel is reachable and returns correct index",
)
    func buttonInsideFrameModifierIsReachable() {
        // Two buttons wrapped in a VStack framed to 200×200.
        let view = VStack(spacing: 0) {
            Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
            Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
        }.frame(width: 200, height: 200)
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 200)
        let tree = LayoutEngine().layout(view, in: constraints)

        // tree.root = FrameModifier node
        // tree.root.children[0] = VStack node
        // tree.root.children[0].children[1] = second button node
        let vStackNode = tree.root.children[0]
        let secondButtonNode = vStackNode.children[1]
        let midX = secondButtonNode.frame.origin.x + secondButtonNode.frame.size.width / 2
        let midY = secondButtonNode.frame.origin.y + secondButtonNode.frame.size.height / 2

        let result = hitTestButton(view: view, node: tree.root, at: Point(x: midX, y: midY))
        #expect(result == 1)
    }

    // -------------------------------------------------------------------------
    // AC-06: Point on frame boundary counts as contained (inclusive bounds)
    // Both tests require ODQ-01 fix: Rect.contains changed from < to <=
    // Enable these AFTER fixing Rect.contains in LayoutTypes.swift.
    // -------------------------------------------------------------------------

    @Test("Point on top-left corner of button frame counts as a hit")
    func pointOnTopLeftCornerCountsAsHit() {
        let view = Button(action: {}) {
            Rectangle().frame(width: 200, height: 40)
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 40)
        let tree = LayoutEngine().layout(view, in: constraints)

        // Point exactly at the top-left corner (inclusive boundary)
        let topLeft = tree.root.frame.origin
        let result = hitTestButton(view: view, node: tree.root, at: topLeft)
        #expect(result == 0)
    }

    @Test("Point on bottom-right corner of button frame counts as a hit")
    func pointOnBottomRightCornerCountsAsHit() {
        let view = Button(action: {}) {
            Rectangle().frame(width: 200, height: 40)
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 40)
        let tree = LayoutEngine().layout(view, in: constraints)

        let frame = tree.root.frame
        let bottomRight = Point(
            x: frame.origin.x + frame.size.width,
            y: frame.origin.y + frame.size.height
        )
        let result = hitTestButton(view: view, node: tree.root, at: bottomRight)
        #expect(result == 0)
    }

    // -------------------------------------------------------------------------
    // AC-07: Does not invoke any button's action during traversal
    // GREEN on scaffold (scaffold never calls action). Enable to lock in the
    // invariant; mutation testing will kill any mutant that calls anyAction.
    // -------------------------------------------------------------------------

    @Test("Traversal never invokes a button action regardless of hit result",
)
    func traversalNeverInvokesButtonAction() {
        nonisolated(unsafe) var callCount = 0
        let view = VStack(spacing: 0) {
            Button(action: { callCount += 1 }) { Rectangle().frame(width: 200, height: 40) }
            Button(action: { callCount += 1 }) { Rectangle().frame(width: 200, height: 40) }
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 200)
        let tree = LayoutEngine().layout(view, in: constraints)

        // Call once at a point inside the first button (would be a hit after implementation)
        let buttonNode = tree.root.children[0]
        let midX = buttonNode.frame.origin.x + buttonNode.frame.size.width / 2
        let midY = buttonNode.frame.origin.y + buttonNode.frame.size.height / 2
        _ = hitTestButton(view: view, node: tree.root, at: Point(x: midX, y: midY))

        // Call again at a point that misses all buttons
        _ = hitTestButton(view: view, node: tree.root, at: Point(x: 100, y: 500))

        #expect(callCount == 0)
    }
}
