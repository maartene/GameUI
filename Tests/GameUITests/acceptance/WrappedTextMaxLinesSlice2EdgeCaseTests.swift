// WrappedText Max Lines Slice 2 — Edge Cases Acceptance Tests
// Driving port (layout): LayoutEngine.layout(_:in:)
// Driving port (renderer contract): WrappedText.clippedLines(measurer:maxWidth:)
// US-05: WrappedText maxLines Edge Cases
//
// Stub measurer: width = fontSize × charCount, height = fontSize

import Testing
@testable import GameUI

private func stubMeasurer(_ content: String, _ fontSize: Float) -> Size {
    Size(width: fontSize * Float(content.count), height: fontSize)
}

@Suite("WrappedText — maxLines Edge Cases")
struct WrappedTextMaxLinesSlice2EdgeCaseTests {

    // -------------------------------------------------------------------------
    // AC: maxLines: 0 → 0 children, height = 0.0
    // -------------------------------------------------------------------------

    @Test func `maxLines zero produces zero children and zero height`() {
        // "Battle stations!" wraps to 1 line without maxLines; maxLines: 0 collapses to zero
        let wrapped = WrappedText(content: "Battle stations!", fontSize: 22, color: .white, maxLines: 0)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.children.count == 0)
        #expect(tree.root.frame.size.height == 0.0)
    }

    // -------------------------------------------------------------------------
    // AC: maxLines: 1, content wraps to multiple lines → 1 child, height = lineHeight
    // -------------------------------------------------------------------------

    @Test func `maxLines one clips three-line content to a single child with single-line height`() {
        // "AAAAA BBBBB CCCCC" at fontSize 16, maxWidth 80 → 3 lines; maxLines: 1 clips to 1
        let wrapped = WrappedText(content: "AAAAA BBBBB CCCCC", fontSize: 16, color: .white, maxLines: 1)
        let constraints = LayoutConstraints(maxWidth: 80, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.children.count == 1)
        #expect(tree.root.frame.size.height == 16.0)
    }

    // -------------------------------------------------------------------------
    // AC: maxLines: 1, content fits on 1 line → 1 child, height = lineHeight (no regression)
    // -------------------------------------------------------------------------

    @Test func `maxLines one with content that wraps to exactly one line produces one child and single-line height`() {
        // "HP" = 2 × 16 = 32 ≤ 200 → 1 line
        let wrapped = WrappedText(content: "HP", fontSize: 16, color: .white, maxLines: 1)
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.children.count == 1)
        #expect(tree.root.frame.size.height == 16.0)
    }

    // -------------------------------------------------------------------------
    // AC: maxLines: 3, content "" → 0 children, height = 3 × lineHeight (floor applies to empty)
    // -------------------------------------------------------------------------

    @Test func `empty content with maxLines 3 reserves three-line height with zero children`() {
        let wrapped = WrappedText(content: "", fontSize: 22, color: .white, maxLines: 3)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.children.count == 0)
        #expect(tree.root.frame.size.height == 66.0)
    }

    // -------------------------------------------------------------------------
    // AC: maxLines: 1, unbreakable word → 1 child, height = lineHeight, no crash
    // -------------------------------------------------------------------------

    @Test func `maxLines one with unbreakable word wider than maxWidth produces one child safely without crash`() {
        // "AncientRelicOfThePast" = 21 chars × 14 = 294 > 50 — unbreakable, placed on own line
        let wrapped = WrappedText(content: "AncientRelicOfThePast", fontSize: 14, color: .white, maxLines: 1)
        let constraints = LayoutConstraints(maxWidth: 50, maxHeight: 400)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.children.count == 1)
        #expect(tree.root.frame.size.height == 14.0)
    }

    // -------------------------------------------------------------------------
    // AC: maxLines: 0 with empty content → 0 children, height = 0.0
    // -------------------------------------------------------------------------

    @Test func `maxLines zero with empty content produces zero children and zero height`() {
        let wrapped = WrappedText(content: "", fontSize: 22, color: .white, maxLines: 0)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.children.count == 0)
        #expect(tree.root.frame.size.height == 0.0)
    }

    // -------------------------------------------------------------------------
    // AC: clippedLines with maxLines: 0 returns empty array
    // -------------------------------------------------------------------------

    @Test func `clippedLines with maxLines zero returns empty array`() {
        let wrapped = WrappedText(content: "Battle stations!", fontSize: 22, color: .white, maxLines: 0)
        let lines = wrapped.clippedLines(measurer: stubMeasurer, maxWidth: 400)
        #expect(lines.isEmpty)
    }

    // -------------------------------------------------------------------------
    // AC: clippedLines with maxLines: 1 returns at most 1 string for multi-line content
    // -------------------------------------------------------------------------

    @Test func `clippedLines with maxLines one returns exactly one string for multi-line content`() {
        // 3 lines → clipped to 1
        let wrapped = WrappedText(content: "AAAAA BBBBB CCCCC", fontSize: 16, color: .white, maxLines: 1)
        let lines = wrapped.clippedLines(measurer: stubMeasurer, maxWidth: 80)
        #expect(lines.count == 1)
    }

    // -------------------------------------------------------------------------
    // AC: clippedLines with empty content and maxLines set returns empty array
    // -------------------------------------------------------------------------

    @Test func `clippedLines with empty content and maxLines 3 returns empty array`() {
        let wrapped = WrappedText(content: "", fontSize: 22, color: .white, maxLines: 3)
        let lines = wrapped.clippedLines(measurer: stubMeasurer, maxWidth: 400)
        #expect(lines.isEmpty)
    }
}
