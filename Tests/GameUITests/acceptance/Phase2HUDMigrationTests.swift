// Phase 2 — HUD Migration
// Driving port: LayoutEngine.layout(_:in:)
// Text measurement uses an injected stub returning fixed sizes.
// All tests disabled until Phase 1 acceptance tests pass.

import Testing
@testable import GameUI

// MARK: - Stub text measurer

/// Returns a fixed Size regardless of content — deterministic for layout tests.
private func stubMeasurer(_ content: String, _ fontSize: Float) -> Size {
    Size(width: fontSize * Float(content.count), height: fontSize)
}

// MARK: - Phase 2 Acceptance Suite

@Suite struct `HUD layout` {

    // -------------------------------------------------------------------------
    // Text view — natural size
    // -------------------------------------------------------------------------

    @Test
    func `text view occupies a frame sized to its content and font`() {
        // Given a text label "HP" at font size 20
        let label = Text(content: "HP", fontSize: 20, color: .white)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 100)

        // When layout runs with the stub measurer
        let tree = LayoutEngine(textMeasurer: stubMeasurer)
            .layout(label, in: constraints)

        // Then the frame width equals fontSize × character count (2 × 20 = 40)
        // and height equals fontSize (20)
        #expect(tree.root.frame.size.width == 40)
        #expect(tree.root.frame.size.height == 20)
    }

    @Test
    func `text view with empty content occupies zero width`() {
        // Given an empty string label
        let label = Text(content: "", fontSize: 16, color: .white)
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 50)

        // When layout runs
        let tree = LayoutEngine(textMeasurer: stubMeasurer)
            .layout(label, in: constraints)

        // Then width is zero (no characters to measure)
        #expect(tree.root.frame.size.width == 0)
    }

    // -------------------------------------------------------------------------
    // Texture / image view
    // -------------------------------------------------------------------------

    @Test
    func `texture view with fixed frame occupies the declared size`() {
        // Given a texture view requesting 64 × 64
        let icon = Texture(textureName: "hero-portrait", tint: .white)
            .frame(width: 64, height: 64)
        let constraints = LayoutConstraints(maxWidth: 800, maxHeight: 600)

        // When layout runs
        let tree = LayoutEngine().layout(icon, in: constraints)

        // Then the frame matches the requested size exactly
        #expect(tree.root.frame.size.width == 64)
        #expect(tree.root.frame.size.height == 64)
    }

    // -------------------------------------------------------------------------
    // Button view — frame and child propagation
    // -------------------------------------------------------------------------

    @Test
    func `button wrapping a texture inherits the texture frame`() {
        // Given a button wrapping a 64 × 64 texture
        let button = Button(action: {}) {
            Texture(textureName: "hero-portrait", tint: .white)
                .frame(width: 64, height: 64)
        }
        let constraints = LayoutConstraints(maxWidth: 800, maxHeight: 600)

        // When layout runs
        let tree = LayoutEngine().layout(button, in: constraints)

        // Then the button frame equals its child's frame
        #expect(tree.root.frame.size.width == 64)
        #expect(tree.root.frame.size.height == 64)
    }

    @Test
    func `mouse position inside button frame counts as a hit`() {
        // Given a button laid out at a known position
        let button = Button(action: {}) {
            Rectangle(color: .white).frame(width: 100, height: 40)
        }
        let constraints = LayoutConstraints(maxWidth: 800, maxHeight: 600)
        let tree = LayoutEngine().layout(button, in: constraints)
        let buttonFrame = tree.root.frame

        // When the mouse position is inside the button frame
        let insidePoint = Point(x: buttonFrame.origin.x + 10,
                                y: buttonFrame.origin.y + 10)

        // Then the frame contains the point
        #expect(buttonFrame.contains(insidePoint))
    }

    @Test
    func `mouse position outside button frame is not a hit`() {
        // Given a button laid out at screen origin (0, 0) sized 100 × 40
        let button = Button(action: {}) {
            Rectangle(color: .white).frame(width: 100, height: 40)
        }
        let constraints = LayoutConstraints(maxWidth: 800, maxHeight: 600)
        let tree = LayoutEngine().layout(button, in: constraints)
        let buttonFrame = tree.root.frame

        // When the mouse position is outside the button frame
        let outsidePoint = Point(x: buttonFrame.origin.x + 200,
                                 y: buttonFrame.origin.y + 200)

        // Then the frame does not contain the point
        #expect(!buttonFrame.contains(outsidePoint))
    }

    // -------------------------------------------------------------------------
    // HP bar — proportional fill width
    // -------------------------------------------------------------------------

    @Test
    func `HP bar fill rectangle width reflects the health proportion`() {
        // Given a bar container 200 px wide with a fill at 75% health
        // The fill is expressed as a fixed width derived from proportion
        let fillWidth: Float = 200 * 0.75  // 150 px
        let bar = HStack(spacing: 0) {
            Rectangle(color: .green).frame(width: fillWidth, height: 20)
            Spacer()
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 20)

        // When layout runs
        let tree = LayoutEngine().layout(bar, in: constraints)

        // Then the first child (fill rectangle) is 150 px wide
        let fillNode = tree.root.children[0]
        #expect(fillNode.frame.size.width == 150)
    }

    @Test
    func `HP bar fill rectangle is zero width when health is zero`() {
        // Given a bar container with zero fill
        let bar = HStack(spacing: 0) {
            Rectangle(color: .green).frame(width: 0, height: 20)
            Spacer()
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 20)

        // When layout runs
        let tree = LayoutEngine().layout(bar, in: constraints)

        // Then the fill node has zero width
        let fillNode = tree.root.children[0]
        #expect(fillNode.frame.size.width == 0)
    }

    @Test
    func `HP bar fill rectangle equals container width at full health`() {
        // Given a bar container 200 px wide with 100% fill
        let bar = HStack(spacing: 0) {
            Rectangle(color: .green).frame(width: 200, height: 20)
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 20)

        // When layout runs
        let tree = LayoutEngine().layout(bar, in: constraints)

        // Then the fill occupies the full container width
        #expect(tree.root.children[0].frame.size.width == 200)
    }

    // -------------------------------------------------------------------------
    // VStack — vertical layout
    // -------------------------------------------------------------------------

    @Test
    func `VStack places children top to bottom without spacing`() {
        // Given a VStack of two items with no spacing
        let stack = VStack(spacing: 0) {
            Rectangle(color: .white).frame(width: 100, height: 30)
            Rectangle(color: .white).frame(width: 100, height: 50)
        }
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 400)

        // When layout runs
        let tree = LayoutEngine().layout(stack, in: constraints)
        let first = tree.root.children[0]
        let second = tree.root.children[1]

        // Then the second child's y origin follows directly below the first
        #expect(first.frame.origin.y == 0)
        #expect(second.frame.origin.y == 30)
    }

    @Test
    func `VStack separates children by the declared spacing`() {
        // Given a VStack with 8 pt spacing
        let stack = VStack(spacing: 8) {
            Rectangle(color: .white).frame(width: 100, height: 30)
            Rectangle(color: .white).frame(width: 100, height: 50)
        }
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 400)

        // When layout runs
        let tree = LayoutEngine().layout(stack, in: constraints)
        let second = tree.root.children[1]

        // Then the second child is offset by height + spacing (30 + 8 = 38)
        #expect(second.frame.origin.y == 38)
    }

    @Test
    func `VStack total height equals sum of children heights plus spacing gaps`() {
        // Given a VStack with 3 children at known heights and 4 pt spacing
        let stack = VStack(spacing: 4) {
            Rectangle(color: .white).frame(width: 80, height: 20)
            Rectangle(color: .white).frame(width: 80, height: 30)
            Rectangle(color: .white).frame(width: 80, height: 40)
        }
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 400)

        // When layout runs
        let tree = LayoutEngine().layout(stack, in: constraints)

        // Then the total height is 20+30+40 + 2 gaps of 4 = 98
        #expect(tree.root.frame.size.height == 98)
    }

    @Test
    func `VStack with more children than available height clips to constraint`() {
        // Given a VStack whose content exceeds the height constraint
        let stack = VStack(spacing: 0) {
            Rectangle(color: .white).frame(width: 100, height: 200)
            Rectangle(color: .white).frame(width: 100, height: 200)
        }
        // Only 300 px available, content is 400 px
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        // When layout runs
        let tree = LayoutEngine().layout(stack, in: constraints)

        // Then the container height does not exceed the constraint
        #expect(tree.root.frame.size.height <= 300)
    }

    // -------------------------------------------------------------------------
    // HStack — horizontal layout
    // -------------------------------------------------------------------------

    @Test
    func `HStack places children left to right without spacing`() {
        // Given an HStack of two items with no spacing
        let stack = HStack(spacing: 0) {
            Rectangle(color: .white).frame(width: 40, height: 30)
            Rectangle(color: .white).frame(width: 60, height: 30)
        }
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 100)

        // When layout runs
        let tree = LayoutEngine().layout(stack, in: constraints)
        let first = tree.root.children[0]
        let second = tree.root.children[1]

        // Then the second child's x origin follows directly after the first
        #expect(first.frame.origin.x == 0)
        #expect(second.frame.origin.x == 40)
    }

    @Test
    func `HStack separates children by the declared spacing`() {
        // Given an HStack with 10 pt spacing
        let stack = HStack(spacing: 10) {
            Rectangle(color: .white).frame(width: 40, height: 30)
            Rectangle(color: .white).frame(width: 60, height: 30)
        }
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 100)

        // When layout runs
        let tree = LayoutEngine().layout(stack, in: constraints)
        let second = tree.root.children[1]

        // Then the second child starts at width + spacing (40 + 10 = 50)
        #expect(second.frame.origin.x == 50)
    }

    @Test
    func `HStack total width equals sum of children widths plus spacing gaps`() {
        // Given an HStack with 3 children and 6 pt spacing
        let stack = HStack(spacing: 6) {
            Rectangle(color: .white).frame(width: 50, height: 30)
            Rectangle(color: .white).frame(width: 70, height: 30)
            Rectangle(color: .white).frame(width: 30, height: 30)
        }
        let constraints = LayoutConstraints(maxWidth: 800, maxHeight: 100)

        // When layout runs
        let tree = LayoutEngine().layout(stack, in: constraints)

        // Then total width is 50+70+30 + 2 gaps of 6 = 162
        #expect(tree.root.frame.size.width == 162)
    }

    // -------------------------------------------------------------------------
    // Fixed-size container — constrains children
    // -------------------------------------------------------------------------

    @Test
    func `fixed-size container restricts child to declared dimensions`() {
        // Given a child that prefers 500 × 500 inside a 100 × 80 container
        let container = Rectangle(color: .white)
            .frame(width: 500, height: 500)
            .frame(width: 100, height: 80)  // outer frame modifier constrains
        let constraints = LayoutConstraints(maxWidth: 1280, maxHeight: 800)

        // When layout runs
        let tree = LayoutEngine().layout(container, in: constraints)

        // Then the resolved frame honours the outer constraint
        #expect(tree.root.frame.size.width == 100)
        #expect(tree.root.frame.size.height == 80)
    }

    @Test
    func `view requesting larger size than available constraint is clamped`() {
        // Given a fixed-size view requesting 2000 × 2000 in a 400 × 300 space
        let view = Rectangle(color: .white).frame(width: 2000, height: 2000)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        // When layout runs
        let tree = LayoutEngine().layout(view, in: constraints)

        // Then the frame does not exceed the available constraints
        #expect(tree.root.frame.size.width <= 400)
        #expect(tree.root.frame.size.height <= 300)
    }
}
