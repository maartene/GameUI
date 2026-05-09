// WrappedTextUnitTests.swift — Unit tests for WrappedText.wrappedLines
// Driving port: WrappedText.wrappedLines(measurer:maxWidth:) — pure function IS its own driving port
// Test Budget: 4 distinct behaviors × 2 = 8 max unit tests (using 4)

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
        let wt = WrappedText(content: "", fontSize: 16, color: .white)
        let lines = wt.wrappedLines(measurer: stubMeasurer, maxWidth: 100)
        #expect(lines.isEmpty)
    }

    // Behavior 2: Single word fits → exactly one line with that word
    @Test func `single word that fits within maxWidth produces exactly one line`() {
        let wt = WrappedText(content: "Hello", fontSize: 10, color: .white)
        // "Hello" = 5 × 10 = 50 ≤ 100
        let lines = wt.wrappedLines(measurer: stubMeasurer, maxWidth: 100)
        #expect(lines.count == 1)
        #expect(lines[0] == "Hello")
    }

    // Behavior 3: Greedy word-wrap produces correct line split
    @Test func `greedy wrap splits words into correct number of lines`() {
        let wt = WrappedText(content: "AAAAA BBBBB CCCCC", fontSize: 16, color: .white)
        // "AAAAA" = 5 × 16 = 80 ≤ 80 (fits)
        // "AAAAA BBBBB" = 11 × 16 = 176 > 80 → wrap after "AAAAA"
        // "BBBBB" = 5 × 16 = 80 ≤ 80 (fits)
        // "BBBBB CCCCC" = 11 × 16 = 176 > 80 → wrap after "BBBBB"
        // Result: 3 lines
        let lines = wt.wrappedLines(measurer: stubMeasurer, maxWidth: 80)
        #expect(lines.count == 3)
        #expect(lines[0] == "AAAAA")
        #expect(lines[1] == "BBBBB")
        #expect(lines[2] == "CCCCC")
    }

    // Behavior 4: Single unbreakable word wider than maxWidth → placed on its own line, no crash
    @Test func `single word wider than maxWidth is placed on its own line without crashing`() {
        let wt = WrappedText(content: "SUPERLONGWORD", fontSize: 20, color: .white)
        // "SUPERLONGWORD" = 13 × 20 = 260 > 50
        let lines = wt.wrappedLines(measurer: stubMeasurer, maxWidth: 50)
        #expect(lines.count == 1)
        #expect(lines[0] == "SUPERLONGWORD")
    }
}
