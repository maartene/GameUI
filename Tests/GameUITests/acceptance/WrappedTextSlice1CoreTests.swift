// WrappedText Slice 1 — Core Word-Wrap Acceptance Tests
// Driving port: LayoutEngine.layout(_:in:)
//
// Stub measurer: width = fontSize × charCount, height = fontSize
// Enable tests one at a time in DELIVER; each maps to one TDD cycle.

import Testing
@testable import GameUI

// MARK: - Stub measurer

private func stubMeasurer(_ content: String, _ fontSize: Float) -> Size {
    Size(width: fontSize * Float(content.count), height: fontSize)
}

// MARK: - Slice 1 Acceptance Suite

@Suite("WrappedText — Core Word-Wrap")
struct WrappedTextSlice1CoreTests {

    // -------------------------------------------------------------------------
    // Walking skeleton — compile + run end-to-end
    // Answers: "Can a developer declare WrappedText and receive a LayoutTree?"
    // -------------------------------------------------------------------------

    @Test func `WrappedText is accepted by LayoutEngine as a View and returns a LayoutTree`() {
        let wrapped = WrappedText(content: "Hello", fontSize: 14, color: .white)
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.frame.size.width >= 0)
    }

    // -------------------------------------------------------------------------
    // AC: Multi-line text produces two or more child nodes
    // -------------------------------------------------------------------------

    @Test func `multi-line item description produces two or more child nodes`() {
        // "The ancient relic..." at fontSize 14 with maxWidth 200:
        // "The ancient" = 11 × 14 = 154 ≤ 200; "The ancient relic" = 17 × 14 = 238 > 200 → wraps
        let wrapped = WrappedText(
            content: "The ancient relic pulses with an eerie blue glow said to grant its bearer visions of the past",
            fontSize: 14,
            color: .white
        )
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.children.count >= 2)
    }

    // -------------------------------------------------------------------------
    // AC: No child LayoutNode frame width exceeds maxWidth
    // -------------------------------------------------------------------------

    @Test func `no child LayoutNode frame width exceeds constraints maxWidth`() throws {
        let wrapped = WrappedText(
            content: "The ancient relic pulses with an eerie blue glow said to grant its bearer visions of the past",
            fontSize: 14,
            color: .white
        )
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        try #require(tree.root.children.count >= 2)
        for child in tree.root.children {
            #expect(child.frame.size.width <= 200)
        }
    }

    // -------------------------------------------------------------------------
    // AC: Child nodes stacked vertically — origins at multiples of fontSize
    // -------------------------------------------------------------------------

    @Test func `child nodes are stacked vertically with y-origins at multiples of fontSize`() throws {
        // "AAAAA BBBBB CCCCC" at fontSize 16, maxWidth 80:
        // "AAAAA" = 5 × 16 = 80 ≤ 80 (fits)
        // "AAAAA BBBBB" = 11 × 16 = 176 > 80 → wrap after "AAAAA"
        // "BBBBB CCCCC" = 11 × 16 = 176 > 80 → wrap after "BBBBB"
        // Result: 3 lines → origins at y = 0, 16, 32
        let wrapped = WrappedText(content: "AAAAA BBBBB CCCCC", fontSize: 16, color: .white)
        let constraints = LayoutConstraints(maxWidth: 80, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        try #require(tree.root.children.count == 3)
        #expect(tree.root.children[0].frame.origin.y == 0)
        #expect(tree.root.children[1].frame.origin.y == 16)
        #expect(tree.root.children[2].frame.origin.y == 32)
    }

    // -------------------------------------------------------------------------
    // AC: Root node height equals lineCount × lineHeight
    // -------------------------------------------------------------------------

    @Test func `root node height equals total line count times lineHeight`() throws {
        // "AAAAA BBBBB CCCCC" at fontSize 14, maxWidth 70:
        // "AAAAA" = 5 × 14 = 70 (exactly fits); wraps before "BBBBB"
        // 3 lines × 14 = 42
        let wrapped = WrappedText(content: "AAAAA BBBBB CCCCC", fontSize: 14, color: .white)
        let constraints = LayoutConstraints(maxWidth: 70, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        try #require(tree.root.children.count == 3)
        #expect(tree.root.frame.size.height == 42)
    }

    // -------------------------------------------------------------------------
    // AC: Root node frame width equals constraints.maxWidth (fills available width)
    // -------------------------------------------------------------------------

    @Test func `root node frame width equals constraints maxWidth`() {
        let wrapped = WrappedText(content: "Hello world", fontSize: 14, color: .white)
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.frame.size.width == 200)
    }

    // -------------------------------------------------------------------------
    // AC: Single short text produces exactly one child node
    // -------------------------------------------------------------------------

    @Test func `single short text that fits on one line produces exactly one child node`() {
        // "HP" = 2 × 14 = 28 ≤ 200 → 1 line
        let wrapped = WrappedText(content: "HP", fontSize: 14, color: .white)
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.children.count == 1)
    }

    // -------------------------------------------------------------------------
    // AC: Single-line child frame width does not exceed maxWidth
    // -------------------------------------------------------------------------

    @Test func `single-line child frame width does not exceed maxWidth`() throws {
        let wrapped = WrappedText(content: "HP", fontSize: 14, color: .white)
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        try #require(tree.root.children.count == 1)
        #expect(tree.root.children[0].frame.size.width <= 200)
    }

    // -------------------------------------------------------------------------
    // AC: Identical inputs produce identical LayoutTrees (deterministic)
    // -------------------------------------------------------------------------

    @Test func `identical inputs always produce identical LayoutTrees`() {
        let wrapped = WrappedText(
            content: "The ancient relic pulses with an eerie blue glow",
            fontSize: 14,
            color: .white
        )
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 600)
        let engine = LayoutEngine(textMeasurer: stubMeasurer)
        let tree1 = engine.layout(wrapped, in: constraints)
        let tree2 = engine.layout(wrapped, in: constraints)
        #expect(tree1.root.children.count == tree2.root.children.count)
        #expect(tree1.root.frame.size.width == tree2.root.frame.size.width)
        #expect(tree1.root.frame.size.height == tree2.root.frame.size.height)
    }

    // -------------------------------------------------------------------------
    // AC: Text exactly fitting one line → exactly one child, no spurious second line
    // -------------------------------------------------------------------------

    @Test func `text that exactly fills one line produces exactly one child without overflow`() throws {
        // "AAAAA" = 5 × 14 = 70, maxWidth = 70 → exactly fits, no wrap
        let wrapped = WrappedText(content: "AAAAA", fontSize: 14, color: .white)
        let constraints = LayoutConstraints(maxWidth: 70, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.children.count == 1)
        try #require(tree.root.children.count == 1)
        #expect(tree.root.children[0].frame.size.width <= 70)
    }

    // -------------------------------------------------------------------------
    // AC: WrappedText.color and .fontSize are accessible post-pattern-match
    // -------------------------------------------------------------------------

    @Test func `WrappedText color and fontSize are accessible after construction`() {
        let wrapped = WrappedText(content: "Title", fontSize: 18, color: .white)
        #expect(wrapped.fontSize == 18)
        #expect(wrapped.color.r == 255 && wrapped.color.g == 255 && wrapped.color.b == 255)
    }
}
