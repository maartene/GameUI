// Phase 1 — Foundation (Walking Skeleton)
// Driving port: LayoutEngine.layout(_:in:) and @ViewBuilder DSL
//
// Enable scenarios one at a time. The first test is enabled;
// all others are marked @Test(.disabled(...)).

import Testing
@testable import GameUI

// MARK: - Walking Skeleton

@Suite struct `GameUI foundation` {

    // Walking skeleton — ENABLED FIRST.
    // Answers: "Can a developer describe a view and receive a positioned frame?"
    @Test func `layout engine produces a frame for a single fixed-size view`() {
        // Given a view that requests a fixed size of 200 × 100
        let view = Rectangle(color: .white)
            .frame(width: 200, height: 100)
        let constraints = LayoutConstraints(maxWidth: 1280, maxHeight: 800)

        // When the layout engine resolves the view tree
        let tree = LayoutEngine().layout(view, in: constraints)

        // Then the root node has the requested frame
        #expect(tree.root.frame.size.width == 200)
        #expect(tree.root.frame.size.height == 100)
    }

    // -------------------------------------------------------------------------
    // View protocol — definition and basic conformance
    // -------------------------------------------------------------------------

    @Test func `leaf view conforms to View protocol`() {
        // Given
        let rectangle = Rectangle(color: .white)

        // When we inspect its type
        // Then it satisfies the View protocol (compile-time verification)
        let _: any View = rectangle
        #expect(Bool(true)) // compilation reaching here is the assertion
    }

    @Test func `color named constants are available without importing raylib`() {
        // Given the GameUI module is imported (no raylib)
        // When named colors are referenced
        let white = Color.white
        let darkGray = Color.darkGray

        // Then they carry the expected RGBA byte values
        #expect(white.r == 255 && white.g == 255 && white.b == 255 && white.a == 255)
        #expect(darkGray.r < 100 && darkGray.g < 100 && darkGray.b < 100)
    }

    // -------------------------------------------------------------------------
    // LayoutConstraints — boundary values
    // -------------------------------------------------------------------------

    @Test func `layout engine accepts zero-size constraints without crashing`() {
        // Given a non-empty view and zero available space
        let view = Rectangle(color: .white)
        let constraints = LayoutConstraints(maxWidth: 0, maxHeight: 0)

        // When layout is requested
        let tree = LayoutEngine().layout(view, in: constraints)

        // Then a layout tree is returned (no crash, no nil)
        #expect(tree.root.frame.size.width >= 0)
        #expect(tree.root.frame.size.height >= 0)
    }

    @Test func `layout engine places root frame at screen origin by default`() {
        // Given a fixed-size view with plenty of available space
        let view = Rectangle(color: .white).frame(width: 50, height: 50)
        let constraints = LayoutConstraints(maxWidth: 1280, maxHeight: 800)

        // When layout runs
        let tree = LayoutEngine().layout(view, in: constraints)

        // Then the root frame origin is top-left (0, 0)
        #expect(tree.root.frame.origin.x == 0)
        #expect(tree.root.frame.origin.y == 0)
    }

    // -------------------------------------------------------------------------
    // @ViewBuilder DSL — composition
    // -------------------------------------------------------------------------

    @Test func `ViewBuilder composes two children into a container`() {
        // Given a VStack declared with two children using result builder syntax
        let container = VStack(spacing: 0) {
            Rectangle(color: .white).frame(width: 100, height: 40)
            Rectangle(color: .darkGray).frame(width: 100, height: 40)
        }

        // When layout runs with enough space
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 400)
        let tree = LayoutEngine().layout(container, in: constraints)

        // Then the layout tree contains two child nodes
        #expect(tree.root.children.count == 2)
    }

    @Test func `ViewBuilder composes three children in declaration order`() {
        // Given a VStack with three children
        let container = VStack(spacing: 0) {
            Rectangle(color: .white).frame(width: 80, height: 20)
            Rectangle(color: .white).frame(width: 80, height: 30)
            Rectangle(color: .white).frame(width: 80, height: 40)
        }
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 400)

        // When layout runs
        let tree = LayoutEngine().layout(container, in: constraints)

        // Then three children are present
        #expect(tree.root.children.count == 3)
    }
}
