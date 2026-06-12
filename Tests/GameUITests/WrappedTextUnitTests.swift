// WrappedTextUnitTests.swift — Unit tests for WrappedText.wrappedLines, clippedLines, and LayoutEngine WrappedText branch
// Driving port: WrappedText.wrappedLines(measurer:maxWidth:) — pure function IS its own driving port
//              WrappedText.clippedLines(measurer:maxWidth:) — pure function IS its own driving port
//              LayoutEngine.layout(_:in:) — application service driving port for layout behavior
// Test Budget (step 01-01 wrappedLines): 4 distinct behaviors × 2 = 8 max unit tests (using 4)
// Test Budget (step 01-01 clippedLines): 1 distinct behavior × 2 = 2 max unit tests (using 1)
// Test Budget (step 01-02): 1 distinct behavior × 2 = 2 max unit tests (using 1)

import Testing
@testable import GameUI

// MARK: - Stub measurer (width = fontSize × charCount, height = fontSize)

private func stubMeasurer(_ content: String, _ fontSize: Float) -> Size {
    Size(width: fontSize * Float(content.count), height: fontSize)
}

// MARK: - WrappedText.wrappedLines unit tests

@Suite("WrappedText — wrappedLines unit")
struct WrappedTextUnitTests {

    // Behavior 1: Empty content → empty array
    @Test func `empty content returns empty array`() {
        let wrappedText = WrappedText(content: "", fontSize: 16, color: .white)
        let lines = wrappedText.wrappedLines(measurer: stubMeasurer, maxWidth: 100)
        #expect(lines.isEmpty)
    }

    // Behavior 2: Single word fits → exactly one line with that word
    @Test func `single word that fits within maxWidth produces exactly one line`() {
        let wrappedText = WrappedText(content: "Hello", fontSize: 10, color: .white)
        // "Hello" = 5 × 10 = 50 ≤ 100
        let lines = wrappedText.wrappedLines(measurer: stubMeasurer, maxWidth: 100)
        #expect(lines.count == 1)
        #expect(lines[0] == "Hello")
    }

    // Behavior 3: Greedy word-wrap produces correct line split
    @Test func `greedy wrap splits words into correct number of lines`() {
        let wrappedText = WrappedText(content: "AAAAA BBBBB CCCCC", fontSize: 16, color: .white)
        // "AAAAA" = 5 × 16 = 80 ≤ 80 (fits)
        // "AAAAA BBBBB" = 11 × 16 = 176 > 80 → wrap after "AAAAA"
        // "BBBBB" = 5 × 16 = 80 ≤ 80 (fits)
        // "BBBBB CCCCC" = 11 × 16 = 176 > 80 → wrap after "BBBBB"
        // Result: 3 lines
        let lines = wrappedText.wrappedLines(measurer: stubMeasurer, maxWidth: 80)
        #expect(lines.count == 3)
        #expect(lines[0] == "AAAAA")
        #expect(lines[1] == "BBBBB")
        #expect(lines[2] == "CCCCC")
    }

    // Behavior 4: Single unbreakable word wider than maxWidth → placed on its own line, no crash
    @Test func `single word wider than maxWidth is placed on its own line without crashing`() {
        let wrappedText = WrappedText(content: "SUPERLONGWORD", fontSize: 20, color: .white)
        // "SUPERLONGWORD" = 13 × 20 = 260 > 50
        let lines = wrappedText.wrappedLines(measurer: stubMeasurer, maxWidth: 50)
        #expect(lines.count == 1)
        #expect(lines[0] == "SUPERLONGWORD")
    }
}

// MARK: - WrappedText.clippedLines unit tests (step 01-01)

@Suite("WrappedText — clippedLines unit")
struct WrappedTextClippedLinesUnitTests {

    // Behavior: prefix clip — clippedLines returns exactly maxLines elements when content wraps beyond maxLines
    @Test func `clippedLines with maxLines 2 on 3-line content returns exactly 2 elements`() {
        // "AAAAA BBBBB CCCCC" at fontSize 16, maxWidth 80 → 3 lines; maxLines: 2 clips to 2
        let wrapped = WrappedText(content: "AAAAA BBBBB CCCCC", fontSize: 16, color: .white, maxLines: 2)
        let lines = wrapped.clippedLines(measurer: stubMeasurer, maxWidth: 80)
        #expect(lines.count == 2)
    }
}

// MARK: - LayoutEngine WrappedText branch unit tests (step 01-02)

@Suite("LayoutEngine — WrappedText layout")
struct LayoutEngineWrappedTextTests {

    // Behavior 5: LayoutEngine produces one child node per wrapped line
    // Driving port: LayoutEngine.layout(_:in:) — application service
    @Test func `layoutEngine produces correct number of children for wrapped text`() {
        // "AAAAA BBBBB CCCCC" at fontSize 16, maxWidth 80 → 3 lines
        // "AAAAA" = 5 × 16 = 80 ≤ 80; "AAAAA BBBBB" = 11 × 16 = 176 > 80 → 3 lines
        let wrappedText = WrappedText(content: "AAAAA BBBBB CCCCC", fontSize: 16, color: .white)
        let constraints = LayoutConstraints(maxWidth: 80, maxHeight: 600)
        let engine = LayoutEngine(textMeasurer: { str, fs in Size(width: fs * Float(str.count), height: fs) })
        let tree = engine.layout(wrappedText, in: constraints)
        #expect(tree.root.children.count == 3)
    }
}
