// WrappedText Max Lines Slice 1 — Core Floor + Ceiling Acceptance Tests
// Driving port (layout): LayoutEngine.layout(_:in:)
// Driving port (renderer contract): WrappedText.clippedLines(measurer:maxWidth:)
// US-04: WrappedText maxLines Layout Reservation
//
// Stub measurer: width = fontSize × charCount, height = fontSize
// Enable tests one at a time in DELIVER; each maps to one TDD cycle.

import Testing
@testable import GameUI

private func stubMeasurer(_ content: String, _ fontSize: Float) -> Size {
    Size(width: fontSize * Float(content.count), height: fontSize)
}

@Suite("WrappedText — maxLines Floor + Ceiling")
struct WrappedTextMaxLinesSlice1CoreTests {

    // -------------------------------------------------------------------------
    // AC: Short narration reserves full declared height (floor)
    // maxLines: 3, content wraps to 1 line → 1 child, height = 3 × 22 = 66.0
    // -------------------------------------------------------------------------

    @Test func `short narration with maxLines 3 reserves three-line height even though content wraps to one line`() {
        // "Battle stations!" = 16 chars × 22 = 352 ≤ 400 → fits on 1 line
        let wrapped = WrappedText(content: "Battle stations!", fontSize: 22, color: .white, maxLines: 3)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.children.count == 1)
        #expect(tree.root.frame.size.height == 66.0)
    }

    // -------------------------------------------------------------------------
    // AC: Long narration is clipped at maxLines boundary (ceiling)
    // maxLines: 3, content wraps to 5 lines → exactly 3 children, height = 66.0
    // -------------------------------------------------------------------------

    @Test func `long narration with maxLines 3 produces exactly 3 children and clamps height to 66`() {
        // Each word = 5 × 22 = 110 (fits exactly); "AAAAA BBBBB" = 11 × 22 = 242 > 110 → wrap
        // → 5 lines total; maxLines: 3 clips to 3
        let wrapped = WrappedText(
            content: "AAAAA BBBBB CCCCC DDDDD EEEEE",
            fontSize: 22,
            color: .white,
            maxLines: 3
        )
        let constraints = LayoutConstraints(maxWidth: 110, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.children.count == 3)
        #expect(tree.root.frame.size.height == 66.0)
    }

    // -------------------------------------------------------------------------
    // AC: Content that exactly fills maxLines produces no clipping
    // maxLines: 3, content wraps to exactly 3 lines → 3 children, height = 66.0
    // -------------------------------------------------------------------------

    @Test func `narration that exactly fills maxLines 3 produces 3 children and 66 height without clipping`() throws {
        // "AAAAA BBBBB CCCCC" at fontSize 22, maxWidth 110 → exactly 3 lines
        let wrapped = WrappedText(content: "AAAAA BBBBB CCCCC", fontSize: 22, color: .white, maxLines: 3)
        let constraints = LayoutConstraints(maxWidth: 110, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.children.count == 3)
        #expect(tree.root.frame.size.height == 66.0)
    }

    // -------------------------------------------------------------------------
    // AC: maxLines nil preserves existing content-height behaviour (regression guard)
    // -------------------------------------------------------------------------

    @Test func `maxLines nil preserves existing content-height behaviour producing N children and N times lineHeight`() {
        // 3 lines at fontSize 14, maxWidth 70: height = 3 × 14 = 42
        let wrapped = WrappedText(content: "AAAAA BBBBB CCCCC", fontSize: 14, color: .white)
        let constraints = LayoutConstraints(maxWidth: 70, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.children.count == 3)
        #expect(tree.root.frame.size.height == 42.0)
    }

    // -------------------------------------------------------------------------
    // AC: Layout height is stable across varying content lengths when maxLines is set
    // -------------------------------------------------------------------------

    @Test func `layout height is stable across short and long content when maxLines is 3`() {
        let engine = LayoutEngine(textMeasurer: stubMeasurer)
        let shortWrapped = WrappedText(content: "Battle stations!", fontSize: 22, color: .white, maxLines: 3)
        let longWrapped = WrappedText(
            content: "AAAAA BBBBB CCCCC DDDDD EEEEE",
            fontSize: 22,
            color: .white,
            maxLines: 3
        )
        let shortTree = engine.layout(shortWrapped, in: LayoutConstraints(maxWidth: 400, maxHeight: 600))
        let longTree = engine.layout(longWrapped, in: LayoutConstraints(maxWidth: 110, maxHeight: 600))
        #expect(shortTree.root.frame.size.height == 66.0)
        #expect(longTree.root.frame.size.height == 66.0)
    }

    // -------------------------------------------------------------------------
    // AC: Child nodes stacked at correct y-origins when maxLines clips content
    // -------------------------------------------------------------------------

    @Test func `child nodes are stacked vertically at expected y-origins when maxLines clips to 3 lines`() throws {
        // 3 lines at fontSize 22 → origins at y = 0, 22, 44
        let wrapped = WrappedText(content: "AAAAA BBBBB CCCCC", fontSize: 22, color: .white, maxLines: 3)
        let constraints = LayoutConstraints(maxWidth: 110, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        try #require(tree.root.children.count == 3)
        #expect(tree.root.children[0].frame.origin.y == 0)
        #expect(tree.root.children[1].frame.origin.y == 22)
        #expect(tree.root.children[2].frame.origin.y == 44)
    }

    // -------------------------------------------------------------------------
    // AC: Root frame width equals constraints.maxWidth (unchanged behaviour)
    // -------------------------------------------------------------------------

    @Test func `root frame width equals constraints maxWidth when maxLines is set`() {
        let wrapped = WrappedText(content: "Battle stations!", fontSize: 22, color: .white, maxLines: 3)
        let constraints = LayoutConstraints(maxWidth: 400, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.frame.size.width == 400)
    }

    // -------------------------------------------------------------------------
    // AC: maxLines property stored on WrappedText
    // -------------------------------------------------------------------------

    @Test func `WrappedText stores maxLines value at construction`() {
        let wrapped = WrappedText(content: "Hello", fontSize: 14, color: .white, maxLines: 3)
        #expect(wrapped.maxLines == 3)
    }

    // -------------------------------------------------------------------------
    // AC: clippedLines returns exactly maxLines strings when content wraps to more lines
    // Driving port: WrappedText.clippedLines(measurer:maxWidth:)
    // -------------------------------------------------------------------------

    @Test func `clippedLines returns exactly maxLines strings when content wraps to more lines than maxLines`() {
        let wrapped = WrappedText(
            content: "AAAAA BBBBB CCCCC DDDDD EEEEE",
            fontSize: 22,
            color: .white,
            maxLines: 3
        )
        let lines = wrapped.clippedLines(measurer: stubMeasurer, maxWidth: 110)
        #expect(lines.count == 3)
    }

    // -------------------------------------------------------------------------
    // AC: clippedLines returns the first maxLines strings (not later lines)
    // -------------------------------------------------------------------------

    @Test func `clippedLines returns first maxLines strings when content wraps to more lines`() throws {
        // Lines: "AAAAA", "BBBBB", "CCCCC", "DDDDD", "EEEEE" → clipped to first 3
        let wrapped = WrappedText(
            content: "AAAAA BBBBB CCCCC DDDDD EEEEE",
            fontSize: 22,
            color: .white,
            maxLines: 3
        )
        let lines = wrapped.clippedLines(measurer: stubMeasurer, maxWidth: 110)
        try #require(lines.count == 3)
        #expect(lines[0] == "AAAAA")
        #expect(lines[1] == "BBBBB")
        #expect(lines[2] == "CCCCC")
    }

    // -------------------------------------------------------------------------
    // AC: clippedLines count matches layout child count (renderer safety invariant)
    // -------------------------------------------------------------------------

    @Test func `clippedLines count matches layout engine child node count when maxLines is set`() {
        let wrapped = WrappedText(
            content: "AAAAA BBBBB CCCCC DDDDD EEEEE",
            fontSize: 22,
            color: .white,
            maxLines: 3
        )
        let maxWidth: Float = 110
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(
            wrapped,
            in: LayoutConstraints(maxWidth: maxWidth, maxHeight: 600)
        )
        let lines = wrapped.clippedLines(measurer: stubMeasurer, maxWidth: maxWidth)
        #expect(lines.count == tree.root.children.count)
    }

    // -------------------------------------------------------------------------
    // AC: clippedLines is deterministic — same inputs produce same output
    // -------------------------------------------------------------------------

    @Test func `clippedLines produces the same result on repeated calls with the same input`() {
        let wrapped = WrappedText(content: "AAAAA BBBBB CCCCC", fontSize: 22, color: .white, maxLines: 3)
        let lines1 = wrapped.clippedLines(measurer: stubMeasurer, maxWidth: 110)
        let lines2 = wrapped.clippedLines(measurer: stubMeasurer, maxWidth: 110)
        #expect(lines1 == lines2)
    }

    // -------------------------------------------------------------------------
    // AC: clippedLines with maxLines nil returns same result as wrappedLines (backward compat)
    // -------------------------------------------------------------------------

    @Test func `clippedLines with maxLines nil returns same result as wrappedLines`() {
        let wrapped = WrappedText(content: "AAAAA BBBBB CCCCC", fontSize: 22, color: .white)
        let clipped = wrapped.clippedLines(measurer: stubMeasurer, maxWidth: 110)
        let all = wrapped.wrappedLines(measurer: stubMeasurer, maxWidth: 110)
        #expect(clipped == all)
    }
}
