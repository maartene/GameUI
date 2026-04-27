// Phase 3 — AbilityGUI Migration
// Driving port: LayoutEngine.layout(_:in:)
// All tests disabled until Phase 2 acceptance tests pass.

import Testing
@testable import GameUI

// MARK: - Stub text measurer

private func stubMeasurer(_ content: String, _ fontSize: Float) -> Size {
    Size(width: fontSize * Float(content.count), height: fontSize)
}

// MARK: - Phase 3 Acceptance Suite

@Suite struct `AbilityGUI layout` {

    // -------------------------------------------------------------------------
    // Grid layout — N columns
    // -------------------------------------------------------------------------

    @Test
    func `grid of two columns places first item at left and second at right`() {
        // Given an HStack representing a 2-column grid row, each column 120 px wide
        let row = HStack(spacing: 0) {
            Rectangle(color: .white).frame(width: 120, height: 60)
            Rectangle(color: .white).frame(width: 120, height: 60)
        }
        let constraints = LayoutConstraints(maxWidth: 240, maxHeight: 60)

        // When layout runs
        let tree = LayoutEngine().layout(row, in: constraints)
        let left = tree.root.children[0]
        let right = tree.root.children[1]

        // Then columns are side by side at the correct x origins
        #expect(left.frame.origin.x == 0)
        #expect(right.frame.origin.x == 120)
    }

    @Test
    func `grid of four columns places each item at correct horizontal offset`() {
        // Given an HStack with four equal 60 px columns
        let row = HStack(spacing: 0) {
            Rectangle(color: .white).frame(width: 60, height: 50)
            Rectangle(color: .white).frame(width: 60, height: 50)
            Rectangle(color: .white).frame(width: 60, height: 50)
            Rectangle(color: .white).frame(width: 60, height: 50)
        }
        let constraints = LayoutConstraints(maxWidth: 240, maxHeight: 50)

        // When layout runs
        let tree = LayoutEngine().layout(row, in: constraints)
        let children = tree.root.children

        // Then each column starts at its expected x offset
        #expect(children[0].frame.origin.x == 0)
        #expect(children[1].frame.origin.x == 60)
        #expect(children[2].frame.origin.x == 120)
        #expect(children[3].frame.origin.x == 180)
    }

    @Test
    func `grid row height equals the tallest cell in that row`() {
        // Given an HStack with two cells of different heights
        let row = HStack(spacing: 0) {
            Rectangle(color: .white).frame(width: 100, height: 40)
            Rectangle(color: .white).frame(width: 100, height: 80)
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 200)

        // When layout runs
        let tree = LayoutEngine().layout(row, in: constraints)

        // Then the row height equals the tallest cell
        #expect(tree.root.frame.size.height == 80)
    }

    // -------------------------------------------------------------------------
    // Nested containers
    // -------------------------------------------------------------------------

    @Test
    func `VStack inside HStack produces correct child positions`() {
        // Given an HStack with a plain rectangle and a VStack of two items
        let layout = HStack(spacing: 0) {
            Rectangle(color: .darkGray).frame(width: 50, height: 80)
            VStack(spacing: 0) {
                Rectangle(color: .white).frame(width: 100, height: 40)
                Rectangle(color: .white).frame(width: 100, height: 40)
            }
        }
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 200)

        // When layout runs
        let tree = LayoutEngine().layout(layout, in: constraints)
        let vstackNode = tree.root.children[1]
        let nestedFirst = vstackNode.children[0]
        let nestedSecond = vstackNode.children[1]

        // Then the nested VStack children are positioned inside the HStack column
        #expect(vstackNode.frame.origin.x == 50)
        #expect(nestedFirst.frame.origin.y == 0)
        #expect(nestedSecond.frame.origin.y == 40)
    }

    @Test
    func `HStack inside VStack produces correct child positions`() {
        // Given a VStack containing an HStack with two items
        let layout = VStack(spacing: 0) {
            Rectangle(color: .white).frame(width: 200, height: 30)
            HStack(spacing: 0) {
                Rectangle(color: .white).frame(width: 100, height: 50)
                Rectangle(color: .white).frame(width: 100, height: 50)
            }
        }
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        // When layout runs
        let tree = LayoutEngine().layout(layout, in: constraints)
        let hstackNode = tree.root.children[1]

        // Then the HStack is positioned below the first row
        #expect(hstackNode.frame.origin.y == 30)
        #expect(hstackNode.children[0].frame.origin.x == 0)
        #expect(hstackNode.children[1].frame.origin.x == 100)
    }

    @Test
    func `three levels of nesting resolve frames without error`() {
        // Given a three-level deep nesting (VStack > HStack > VStack)
        let deepLayout = VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    Rectangle(color: .white).frame(width: 40, height: 20)
                    Rectangle(color: .white).frame(width: 40, height: 20)
                }
                Rectangle(color: .white).frame(width: 40, height: 40)
            }
        }
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 400)

        // When layout runs
        let tree = LayoutEngine().layout(deepLayout, in: constraints)

        // Then the inner VStack children are reachable and have valid frames
        let innerVStack = tree.root.children[0].children[0]
        #expect(innerVStack.children.count == 2)
        #expect(innerVStack.children[0].frame.size.height == 20)
        #expect(innerVStack.children[1].frame.origin.y == 20)
    }

    // -------------------------------------------------------------------------
    // ZStack — overlay positioning
    // -------------------------------------------------------------------------

    @Test
    func `ZStack places all children at the same origin`() {
        // Given a ZStack with two overlapping items
        let stack = ZStack {
            Rectangle(color: .darkGray).frame(width: 200, height: 100)
            Rectangle(color: .white).frame(width: 80, height: 30)
        }
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        // When layout runs
        let tree = LayoutEngine().layout(stack, in: constraints)
        let background = tree.root.children[0]
        let foreground = tree.root.children[1]

        // Then both children share the same origin
        #expect(background.frame.origin.x == foreground.frame.origin.x)
        #expect(background.frame.origin.y == foreground.frame.origin.y)
    }

    @Test
    func `ZStack size is determined by its largest child`() {
        // Given a ZStack where one child is larger
        let stack = ZStack {
            Rectangle(color: .darkGray).frame(width: 200, height: 150)
            Rectangle(color: .white).frame(width: 80, height: 30)
        }
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        // When layout runs
        let tree = LayoutEngine().layout(stack, in: constraints)

        // Then the ZStack frame matches the largest child's dimensions
        #expect(tree.root.frame.size.width == 200)
        #expect(tree.root.frame.size.height == 150)
    }

    @Test
    func `ZStack with a single child occupies that child frame`() {
        // Given a ZStack containing a single rectangle
        let stack = ZStack {
            Rectangle(color: .white).frame(width: 120, height: 60)
        }
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        // When layout runs
        let tree = LayoutEngine().layout(stack, in: constraints)

        // Then the ZStack and child frames match
        #expect(tree.root.frame.size.width == 120)
        #expect(tree.root.frame.size.height == 60)
    }

    // -------------------------------------------------------------------------
    // Padding modifier — insets child frame
    // -------------------------------------------------------------------------

    @Test
    func `padding modifier insets child frame on all sides`() {
        // Given a rectangle padded by 10 on all sides inside a 200 × 100 container
        let padded = Rectangle(color: .white)
            .frame(width: 200, height: 100)
            .padding(10)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        // When layout runs
        let tree = LayoutEngine().layout(padded, in: constraints)
        let childNode = tree.root.children[0]  // inner rectangle

        // Then the child's frame is inset by 10 on each side
        #expect(childNode.frame.origin.x == 10)
        #expect(childNode.frame.origin.y == 10)
        #expect(childNode.frame.size.width == 180)
        #expect(childNode.frame.size.height == 80)
    }

    @Test
    func `padding modifier with zero inset leaves child frame unchanged`() {
        // Given a rectangle with zero padding
        let padded = Rectangle(color: .white)
            .frame(width: 100, height: 50)
            .padding(0)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        // When layout runs
        let tree = LayoutEngine().layout(padded, in: constraints)
        let childNode = tree.root.children[0]

        // Then the child starts at origin with unchanged size
        #expect(childNode.frame.origin.x == 0)
        #expect(childNode.frame.origin.y == 0)
        #expect(childNode.frame.size.width == 100)
        #expect(childNode.frame.size.height == 50)
    }

    @Test
    func `padding modifier larger than available space yields minimum child size`() {
        // Given a container 30 × 30 with 20 pt padding on all sides
        // Remaining space for child: 30 - 40 = negative — clamped to 0
        let padded = Rectangle(color: .white)
            .frame(width: 30, height: 30)
            .padding(20)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        // When layout runs
        let tree = LayoutEngine().layout(padded, in: constraints)
        let childNode = tree.root.children[0]

        // Then child size is clamped to zero (no negative dimensions)
        #expect(childNode.frame.size.width >= 0)
        #expect(childNode.frame.size.height >= 0)
    }

    // -------------------------------------------------------------------------
    // Spacer — fills remaining axis space
    // -------------------------------------------------------------------------

    @Test
    func `Spacer in HStack fills all remaining width after fixed siblings`() {
        // Given an HStack where the last item is a Spacer
        let stack = HStack(spacing: 0) {
            Rectangle(color: .white).frame(width: 60, height: 30)
            Spacer()
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 30)

        // When layout runs
        let tree = LayoutEngine().layout(stack, in: constraints)
        let spacerNode = tree.root.children[1]

        // Then the Spacer occupies the remaining 140 px (200 - 60)
        #expect(spacerNode.frame.size.width == 140)
    }

    @Test
    func `Spacer in VStack fills all remaining height after fixed siblings`() {
        // Given a VStack where the last item is a Spacer
        let stack = VStack(spacing: 0) {
            Rectangle(color: .white).frame(width: 100, height: 40)
            Spacer()
        }
        let constraints = LayoutConstraints(maxWidth: 100, maxHeight: 200)

        // When layout runs
        let tree = LayoutEngine().layout(stack, in: constraints)
        let spacerNode = tree.root.children[1]

        // Then the Spacer fills the remaining 160 px (200 - 40)
        #expect(spacerNode.frame.size.height == 160)
    }

    @Test
    func `two Spacers in HStack divide remaining space equally`() {
        // Given an HStack with a fixed item flanked by two Spacers
        let stack = HStack(spacing: 0) {
            Spacer()
            Rectangle(color: .white).frame(width: 40, height: 30)
            Spacer()
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 30)

        // When layout runs
        let tree = LayoutEngine().layout(stack, in: constraints)
        let leftSpacer = tree.root.children[0]
        let rightSpacer = tree.root.children[2]

        // Then each Spacer occupies 80 px ((200 - 40) / 2)
        #expect(leftSpacer.frame.size.width == 80)
        #expect(rightSpacer.frame.size.width == 80)
    }
}
