import Testing
@testable import GameUI

// MARK: - Step 02-01 stub measurer
private func stubMeasurer(_ content: String, _ fontSize: Float) -> Size {
    Size(width: fontSize * Float(content.count), height: fontSize)
}

@Suite struct `LayoutEngineTests` {

    // Test Budget: 2 behaviors x 2 = 4 max unit tests. Using 3.

    @Test func `layout engine assigns frame origin at zero for root node`() {
        let view = Rectangle().frame(width: 50, height: 30)
        let constraints = LayoutConstraints(maxWidth: 800, maxHeight: 600)
        let tree = LayoutEngine().layout(view, in: constraints)
        #expect(tree.root.frame.origin.x == 0)
        #expect(tree.root.frame.origin.y == 0)
    }

    @Test func `text node with stub measurer produces frame sized to content`() {
        // "AB" at fontSize 10 → width 20, height 10
        let label = Text(content: "AB", fontSize: 10, color: .white)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 100)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(label, in: constraints)
        #expect(tree.root.frame.size.width == 20)
        #expect(tree.root.frame.size.height == 10)
    }

    // Step 02-02 additions — Test Budget: 2 behaviors x 2 = 4 max; using 2.

    @Test func `framed texture produces layout node with declared frame size`() {
        // FrameModifier<Texture> must be matched generically by HasFrameSize
        let icon = Texture(textureName: "hero-portrait", tint: .white).frame(width: 32, height: 32)
        let constraints = LayoutConstraints(maxWidth: 800, maxHeight: 600)
        let tree = LayoutEngine().layout(icon, in: constraints)
        #expect(tree.root.frame.size.width == 32)
        #expect(tree.root.frame.size.height == 32)
    }

    @Test func `button wrapping framed rectangle inherits child frame size`() {
        // Button recurses into its content and returns child frame as its own
        let button = Button(action: {}) { Rectangle(color: .white).frame(width: 50, height: 30) }
        let constraints = LayoutConstraints(maxWidth: 800, maxHeight: 600)
        let tree = LayoutEngine().layout(button, in: constraints)
        #expect(tree.root.frame.size.width == 50)
        #expect(tree.root.frame.size.height == 30)
    }

    // Step 02-03 additions — Test Budget: 1 behavior x 2 = 2 max; using 2.

    @Test func `Spacer in HStack fills remaining width after fixed-size siblings`() {
        // Given an HStack with a 60 pt wide rectangle and a Spacer in 200 pt max width
        let stack = HStack(spacing: 0) {
            Rectangle(color: .white).frame(width: 60, height: 20)
            Spacer()
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 20)

        // When layout runs
        let tree = LayoutEngine().layout(stack, in: constraints)

        // Then the Spacer node receives the remaining 140 pt
        let spacerNode = tree.root.children[1]
        #expect(spacerNode.frame.size.width == 140)
    }

    @Test func `Spacer in VStack fills remaining height after fixed-size siblings`() {
        // Given a VStack with a 30 pt tall rectangle and a Spacer in 100 pt max height
        let stack = VStack(spacing: 0) {
            Rectangle(color: .white).frame(width: 80, height: 30)
            Spacer()
        }
        let constraints = LayoutConstraints(maxWidth: 80, maxHeight: 100)

        // When layout runs
        let tree = LayoutEngine().layout(stack, in: constraints)

        // Then the Spacer node receives the remaining 70 pt
        let spacerNode = tree.root.children[1]
        #expect(spacerNode.frame.size.height == 70)
    }

    // Step 02-04 additions — Test Budget: 1 behavior x 2 = 2 max; using 1.

    @Test func `VStack total height is clamped to maxHeight when children overflow`() {
        // Given a VStack whose content (400 pt) exceeds the constraint (300 pt)
        let stack = VStack(spacing: 0) {
            Rectangle(color: .white).frame(width: 100, height: 200)
            Rectangle(color: .white).frame(width: 100, height: 200)
        }
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        // When layout runs
        let tree = LayoutEngine().layout(stack, in: constraints)

        // Then the container height is clamped to the constraint
        #expect(tree.root.frame.size.height <= 300)
    }

    @Test func `layout engine recurses into VStack children producing child nodes`() {
        // Given a VStack with two fixed-size children
        let container = VStack(spacing: 0) {
            Rectangle(color: .white).frame(width: 100, height: 40)
            Rectangle(color: .darkGray).frame(width: 100, height: 40)
        }
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 400)

        // When layout runs
        let tree = LayoutEngine().layout(container, in: constraints)

        // Then the root node has exactly 2 children
        #expect(tree.root.children.count == 2)
    }

    // Step 03-03 additions — Test Budget: 3 behaviors x 2 = 6 max; using 1.

    @Test func `ZStack lays out two children at the same origin with max-dimension frame`() {
        // Given a ZStack with two overlapping items of different sizes
        let stack = ZStack {
            Rectangle(color: .darkGray).frame(width: 200, height: 150)
            Rectangle(color: .white).frame(width: 80, height: 30)
        }
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        // When layout runs
        let tree = LayoutEngine().layout(stack, in: constraints)
        let background = tree.root.children[0]
        let foreground = tree.root.children[1]

        // Then both children share the same origin and the root frame is max of child dimensions
        #expect(background.frame.origin.x == foreground.frame.origin.x)
        #expect(background.frame.origin.y == foreground.frame.origin.y)
        #expect(tree.root.frame.size.width == 200)
        #expect(tree.root.frame.size.height == 150)
    }

    // Bug-fix additions — Test Budget: 2 behaviors x 2 = 4 max; using 2.

    @Test func `FrameModifier wrapping Button propagates children through frame modifier`() {
        // A Button wrapped in .frame() must NOT collapse to a childless leaf node.
        // The frame modifier must recurse into the Button so the ZStack's children are reachable.
        let button = Button(action: {}) {
            ZStack {
                Rectangle(color: .white).frame(width: 50, height: 30)
                Rectangle(color: .darkGray).frame(width: 50, height: 30)
            }
        }.frame(width: 100, height: 60)
        let constraints = LayoutConstraints(maxWidth: 800, maxHeight: 600)
        let tree = LayoutEngine().layout(button, in: constraints)
        #expect(!tree.root.children.isEmpty)
    }

    @Test func `framed Button children are reachable for hit-testing`() {
        // At least one descendant of a framed Button must have a non-zero frame,
        // proving ZStack children were laid out (not silently dropped).
        let button = Button(action: {}) {
            ZStack {
                Rectangle(color: .white).frame(width: 50, height: 30)
                Rectangle(color: .darkGray).frame(width: 50, height: 30)
            }
        }.frame(width: 100, height: 60)
        let constraints = LayoutConstraints(maxWidth: 800, maxHeight: 600)
        let tree = LayoutEngine().layout(button, in: constraints)

        func hasNonZeroDescendant(_ node: LayoutNode) -> Bool {
            if node.frame.size.width > 0 && node.frame.size.height > 0 { return true }
            return node.children.contains(where: hasNonZeroDescendant)
        }
        let descendants = tree.root.children.flatMap { [$0] + $0.children }
        #expect(descendants.contains { $0.frame.size.width > 0 && $0.frame.size.height > 0 })
    }

    // Step 01-01 — Test Budget: 1 behavior x 2 = 2 max; using 1.
    // Specification test: HUD info row scenario showing correct width with injected measurer.

    @Test func `HStack with real measurer distributes children within panel width`() {
        // Given a measurer that returns realistic sizes (90px wide for "Loretta" at 24px)
        let realisticMeasurer: @Sendable (String, Float) -> Size = { text, fontSize in
            if text == "Loretta" && fontSize == 24 {
                return Size(width: 90, height: 24)
            }
            return Size(width: fontSize * Float(text.count), height: fontSize)
        }

        // HUD info row: [5px spacer, 60px button, VStack{Text("Loretta")+Rect(120,21)+Rect(120,15)}]
        let stack = HStack(spacing: 0) {
            Spacer().frame(width: 5, height: 20)
            Rectangle(color: .white).frame(width: 60, height: 60)
            VStack(spacing: 0) {
                Text(content: "Loretta", fontSize: 24, color: .white)
                Rectangle(color: .white).frame(width: 120, height: 21)
                Rectangle(color: .white).frame(width: 120, height: 15)
            }
        }
        let constraints = LayoutConstraints(maxWidth: 300, maxHeight: 100)

        // When laid out with the real measurer
        let tree = LayoutEngine(textMeasurer: realisticMeasurer).layout(stack, in: constraints)

        // Then total HStack width is <= 185 (5 + 60 + 90 = 155, well within 185)
        // Without measurer "Loretta" = 168px → HStack child widths = 5+60+168 = 233 > 185
        #expect(tree.root.frame.size.width <= 185)
    }

    // Step 01-02 additions — Test Budget: 2 behaviors x 2 = 4 max; using 2.

    @Test func `Text with leading alignment stores alignment leading`() {
        let label = Text(content: "Name", fontSize: 16, alignment: .leading)
        #expect(label.alignment == .leading)
    }

    @Test func `Text omitting alignment defaults to center`() {
        let label = Text(content: "Title", fontSize: 16)
        #expect(label.alignment == .center)
    }

    // Bug-fix: HStack flanking Spacers in nested VStack

    @Test func `HStack with flanking Spacers nested in VStack sizes Spacers to content height not parent budget`() {
        // Bug: HStack Spacers received height = constraints.maxHeight (e.g. 1080) instead of
        // the tallest non-Spacer sibling (30). This caused HStack to report height=1080,
        // consuming the entire VStack budget and collapsing the outer VStack Spacers to zero.
        let view = VStack(spacing: 0) {
            Spacer()
            HStack(spacing: 0) {
                Spacer()
                Rectangle(color: .white).frame(width: 60, height: 30)
                Spacer()
            }
            Spacer()
        }
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 1080)
        let tree = LayoutEngine().layout(view, in: constraints)

        let hstackNode = tree.root.children[1]
        let hstackLeftSpacer = hstackNode.children[0]
        let hstackRightSpacer = hstackNode.children[2]
        #expect(hstackLeftSpacer.frame.size.height == 30)
        #expect(hstackRightSpacer.frame.size.height == 30)

        let vstackTopSpacer = tree.root.children[0]
        let vstackBottomSpacer = tree.root.children[2]
        #expect(vstackTopSpacer.frame.size.height == 525)
        #expect(vstackBottomSpacer.frame.size.height == 525)
    }

    // Step 03-04 additions — Test Budget: 1 behavior x 2 = 2 max; using 1.

    @Test func `padding modifier insets child origin by padding amount on all sides`() {
        // Given Rectangle.frame(100,50).padding(5) — padding = 5 on all sides (content-box: outer grows)
        let padded = Rectangle(color: .white).frame(width: 100, height: 50).padding(5)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 300)

        // When layout runs
        let tree = LayoutEngine().layout(padded, in: constraints)
        let childNode = tree.root.children[0]

        // Then child origin is offset by padding amount; content size is unchanged (content-box)
        #expect(childNode.frame.origin.x == 5)
        #expect(childNode.frame.origin.y == 5)
        #expect(childNode.frame.size.width == 100)
        #expect(childNode.frame.size.height == 50)
    }
}
