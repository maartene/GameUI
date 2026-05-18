// HitTestButtonTests.swift — Acceptance tests for hitTestButton(view:node:at:)
// Feature: hit-test-button | Story: US-01
// Driving port: hitTestButton(view:node:at:) — public free function in GameUI module

import Testing
@testable import GameUI

@Suite("Hit Test Button — Button Identification by Screen Position")
struct HitTestButtonTests {

    // MARK: - Walking Skeleton

    @Test func `Walking skeleton — cursor over single button returns its index`() {
        let view = Button(action: {}) {
            Rectangle().frame(width: 200, height: 40)
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 40)
        let tree = LayoutEngine().layout(view, in: constraints)

        let midX = tree.root.frame.origin.x + tree.root.frame.size.width / 2
        let midY = tree.root.frame.origin.y + tree.root.frame.size.height / 2

        let result = hitTestButton(view: view, node: tree.root, at: Point(x: midX, y: midY))
        #expect(result == 0)
    }

    // MARK: - AC-02: Returns traversal-order index of first AnyButton containing point

    @Test func `Cursor over first of two buttons returns index 0`() {
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

    @Test func `Cursor over second of two buttons returns index 1`() {
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

    // MARK: - AC-03: Returns nil when no AnyButton frame contains point

    @Test func `Cursor in gap between two buttons returns nil`() {
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

    @Test func `Cursor far outside all button frames returns nil`() {
        let view = VStack(spacing: 0) {
            Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
            Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 600)
        let tree = LayoutEngine().layout(view, in: constraints)

        let result = hitTestButton(view: view, node: tree.root, at: Point(x: 100, y: 500))
        #expect(result == nil)
    }

    @Test func `View tree containing no buttons always returns nil`() {
        let view = VStack(spacing: 0) {
            Rectangle().frame(width: 200, height: 40)
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 40)
        let tree = LayoutEngine().layout(view, in: constraints)

        let result = hitTestButton(view: view, node: tree.root, at: Point(x: 100, y: 20))
        #expect(result == nil)
    }

    // MARK: - AC-04: Traversal is depth-first, matching view-tree construction order

    @Test func `Three buttons in VStack are indexed 0, 1, 2 in top-to-bottom construction order`() {
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

    // MARK: - AC-05: Works when buttons are nested inside containers

    @Test func `Button inside nested VStack is reachable and returns correct index`() {
        let view = VStack(spacing: 0) {
            VStack(spacing: 0) {
                Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
                Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
            }
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 600)
        let tree = LayoutEngine().layout(view, in: constraints)

        let innerStack = tree.root.children[0]
        let secondButtonNode = innerStack.children[1]
        let midX = secondButtonNode.frame.origin.x + secondButtonNode.frame.size.width / 2
        let midY = secondButtonNode.frame.origin.y + secondButtonNode.frame.size.height / 2

        let result = hitTestButton(view: view, node: tree.root, at: Point(x: midX, y: midY))
        #expect(result == 1)
    }

    @Test func `Buttons inside HStack are indexed by horizontal construction order`() {
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

    @Test func `Button inside FrameModifier panel is reachable and returns correct index`() {
        let view = VStack(spacing: 0) {
            Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
            Button(action: {}) { Rectangle().frame(width: 200, height: 40) }
        }.frame(width: 200, height: 200)
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 200)
        let tree = LayoutEngine().layout(view, in: constraints)

        let vStackNode = tree.root.children[0]
        let secondButtonNode = vStackNode.children[1]
        let midX = secondButtonNode.frame.origin.x + secondButtonNode.frame.size.width / 2
        let midY = secondButtonNode.frame.origin.y + secondButtonNode.frame.size.height / 2

        let result = hitTestButton(view: view, node: tree.root, at: Point(x: midX, y: midY))
        #expect(result == 1)
    }

    // MARK: - AC-06: Point on frame boundary counts as contained (inclusive bounds)

    @Test func `Point on top-left corner of button frame counts as a hit`() {
        let view = Button(action: {}) {
            Rectangle().frame(width: 200, height: 40)
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 40)
        let tree = LayoutEngine().layout(view, in: constraints)

        let result = hitTestButton(view: view, node: tree.root, at: tree.root.frame.origin)
        #expect(result == 0)
    }

    @Test func `Point on bottom-right corner of button frame counts as a hit`() {
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

    // MARK: - AC-07: Does not invoke any button's action during traversal

    @Test func `Traversal never invokes a button action regardless of hit result`() {
        nonisolated(unsafe) var callCount = 0
        let view = VStack(spacing: 0) {
            Button(action: { callCount += 1 }) { Rectangle().frame(width: 200, height: 40) }
            Button(action: { callCount += 1 }) { Rectangle().frame(width: 200, height: 40) }
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 200)
        let tree = LayoutEngine().layout(view, in: constraints)

        let buttonNode = tree.root.children[0]
        let midX = buttonNode.frame.origin.x + buttonNode.frame.size.width / 2
        let midY = buttonNode.frame.origin.y + buttonNode.frame.size.height / 2
        _ = hitTestButton(view: view, node: tree.root, at: Point(x: midX, y: midY))
        _ = hitTestButton(view: view, node: tree.root, at: Point(x: 100, y: 500))

        #expect(callCount == 0)
    }

    // MARK: - ZStack edge case

    @Test func `ZStack with two overlapping buttons returns the first button in construction order`() {
        // Both buttons occupy the same frame. First in construction order wins.
        let view = ZStack {
            Button(action: {}) { Rectangle().frame(width: 100, height: 40) }
            Button(action: {}) { Rectangle().frame(width: 100, height: 40) }
        }
        let constraints = LayoutConstraints(maxWidth: 100, maxHeight: 40)
        let tree = LayoutEngine().layout(view, in: constraints)

        let result = hitTestButton(view: view, node: tree.root, at: Point(x: 50, y: 20))
        #expect(result == 0)
    }
}
