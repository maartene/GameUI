// WrappedText Slice 3 — Renderer Guidance Acceptance Tests
// Driving port: WrappedText.wrappedLines(measurer:maxWidth:) + LayoutEngine.layout(_:in:)
//
// Depends on Slices 1 and 2 merged. DESIGN wave resolved ODQ-01 as Option C:
//   Renderer calls wt.wrappedLines(measurer:maxWidth:) and zips with node.children.
//   Each zip element produces one draw call.
//
// Note: The README documentation AC (renderer integration example in README.md) is a
// manual documentation gate, not an automated test. Verify by inspection.

import Testing
@testable import GameUI

// MARK: - Stub measurer

private func stubMeasurer(_ content: String, _ fontSize: Float) -> Size {
    Size(width: fontSize * Float(content.count), height: fontSize)
}

// MARK: - Slice 3 Acceptance Suite

@Suite("WrappedText — Renderer Guidance (wrappedLines API)")
struct WrappedTextSlice3RendererTests {

    // -------------------------------------------------------------------------
    // AC: wrappedLines returns correct line strings for multi-line content
    // -------------------------------------------------------------------------

    @Test func `wrappedLines returns correct line strings for multi-line content`() throws {
        // "AAAAA BBBBB CCCCC" at fontSize 16, maxWidth 80:
        // Line 1: "AAAAA", Line 2: "BBBBB", Line 3: "CCCCC"
        let wrapped = WrappedText(content: "AAAAA BBBBB CCCCC", fontSize: 16, color: .white)
        let lines = wrapped.wrappedLines(measurer: stubMeasurer, maxWidth: 80)
        try #require(lines.count == 3)
        #expect(lines[0] == "AAAAA")
        #expect(lines[1] == "BBBBB")
        #expect(lines[2] == "CCCCC")
    }

    // -------------------------------------------------------------------------
    // AC: wrappedLines count matches layout engine child node count
    // (renderer zip(lines, children) produces one pair per wrapped line)
    // -------------------------------------------------------------------------

    @Test func `wrappedLines count matches layout engine child node count`() {
        let wrapped = WrappedText(
            content: "The ancient relic pulses with an eerie blue glow",
            fontSize: 14,
            color: .white
        )
        let maxWidth: Float = 200
        let constraints = LayoutConstraints(maxWidth: maxWidth, maxHeight: 600)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        let lines = wrapped.wrappedLines(measurer: stubMeasurer, maxWidth: maxWidth)
        #expect(lines.count > 0)
        #expect(lines.count == tree.root.children.count)
    }

    // -------------------------------------------------------------------------
    // AC: Empty content → wrappedLines returns [], children is [], zip iterates 0 times
    // -------------------------------------------------------------------------

    @Test func `empty content produces empty wrappedLines and zero children`() {
        let wrapped = WrappedText(content: "", fontSize: 14, color: .white)
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 400)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        let lines = wrapped.wrappedLines(measurer: stubMeasurer, maxWidth: 200)
        #expect(lines.isEmpty)
        #expect(tree.root.children.isEmpty)
        // zip(lines, children) → 0 iterations → 0 draw calls, no crash
    }

    // -------------------------------------------------------------------------
    // AC: wrappedLines is deterministic — same inputs always produce same output
    // -------------------------------------------------------------------------

    @Test func `wrappedLines produces the same result on repeated calls with the same input`() {
        let wrapped = WrappedText(content: "AAAAA BBBBB CCCCC", fontSize: 16, color: .white)
        let lines1 = wrapped.wrappedLines(measurer: stubMeasurer, maxWidth: 80)
        let lines2 = wrapped.wrappedLines(measurer: stubMeasurer, maxWidth: 80)
        #expect(lines1 == lines2)
    }

    // -------------------------------------------------------------------------
    // AC: wrappedLines with no measurer uses char-count fallback (no crash)
    // -------------------------------------------------------------------------

    @Test func `wrappedLines with no measurer uses char-count fallback without crashing`() {
        let wrapped = WrappedText(content: "Short text", fontSize: 10, color: .white)
        let lines = wrapped.wrappedLines(measurer: nil, maxWidth: 100)
        #expect(lines.count >= 1)
    }

    // -------------------------------------------------------------------------
    // AC: No line in wrappedLines result exceeds maxWidth when measured
    // -------------------------------------------------------------------------

    @Test func `no line returned by wrappedLines exceeds maxWidth when measured`() {
        let wrapped = WrappedText(
            content: "The ancient relic pulses with an eerie blue glow said to grant its bearer visions of the past",
            fontSize: 14,
            color: .white
        )
        let maxWidth: Float = 200
        let lines = wrapped.wrappedLines(measurer: stubMeasurer, maxWidth: maxWidth)
        for line in lines {
            let measuredWidth = stubMeasurer(line, 14).width
            #expect(measuredWidth <= maxWidth)
        }
    }
}
