// WrappedText Slice 2 — Robustness and Fallback Acceptance Tests
// Driving port: LayoutEngine.layout(_:in:)
//
// Depends on Slice 1 merged. Tests boundary conditions:
//   - No measurer injected (char-count fallback)
//   - Single unbreakable word wider than maxWidth
//   - Empty content string
//   - Near-zero maxWidth

import Testing
@testable import GameUI

// MARK: - Stub measurer

private func stubMeasurer(_ content: String, _ fontSize: Float) -> Size {
    Size(width: fontSize * Float(content.count), height: fontSize)
}

// MARK: - Slice 2 Acceptance Suite

@Suite("WrappedText — Robustness and Fallback")
struct WrappedTextSlice2RobustnessTests {

    // -------------------------------------------------------------------------
    // AC: Char-count fallback when no textMeasurer is injected
    // -------------------------------------------------------------------------

    @Test func `char-count fallback produces at least one child when no measurer is injected`() {
        // LayoutEngine() with no textMeasurer → falls back to fontSize × charCount estimate
        let wrapped = WrappedText(content: "Short text for testing fallback", fontSize: 10, color: .white)
        let constraints = LayoutConstraints(maxWidth: 100, maxHeight: 400)
        let tree = LayoutEngine().layout(wrapped, in: constraints)
        #expect(tree.root.children.count >= 1)
    }

    // -------------------------------------------------------------------------
    // AC: Single unbreakable word wider than maxWidth → placed on its own line, no loop
    // -------------------------------------------------------------------------

    @Test func `single unbreakable word wider than maxWidth is placed on its own line without crashing`() {
        // "AncientRelicOfThePast" = 21 × 14 = 294 > 50 → wider than maxWidth, unbreakable
        // Guard: word placed as-is; greedy loop must not retry indefinitely
        let wrapped = WrappedText(content: "AncientRelicOfThePast", fontSize: 14, color: .white)
        let constraints = LayoutConstraints(maxWidth: 50, maxHeight: 400)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.children.count == 1)
    }

    // -------------------------------------------------------------------------
    // AC: Empty content → zero children, root height == 0, no crash
    // -------------------------------------------------------------------------

    @Test func `empty content produces zero children and zero root height`() {
        let wrapped = WrappedText(content: "", fontSize: 14, color: .white)
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 400)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.children.count == 0)
        #expect(tree.root.frame.size.height == 0)
    }

    // -------------------------------------------------------------------------
    // AC: Empty content with no measurer → zero children, no crash
    // -------------------------------------------------------------------------

    @Test func `empty content with no measurer produces zero children`() {
        let wrapped = WrappedText(content: "", fontSize: 14, color: .white)
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 400)
        let tree = LayoutEngine().layout(wrapped, in: constraints)
        #expect(tree.root.children.count == 0)
    }

    // -------------------------------------------------------------------------
    // AC: Near-zero maxWidth → each word placed on its own line, no infinite loop
    // -------------------------------------------------------------------------

    @Test func `near-zero maxWidth places each word on its own line without crashing`() {
        // "Hello world" → 2 words → 2 children at maxWidth 1.0
        // Both "Hello" (5 × 14 = 70) and "world" (5 × 14 = 70) exceed maxWidth 1.0
        // Unbreakable word guard: each word placed as-is on its own line
        let wrapped = WrappedText(content: "Hello world", fontSize: 14, color: .white)
        let constraints = LayoutConstraints(maxWidth: 1.0, maxHeight: 400)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.children.count == 2)
    }

    // -------------------------------------------------------------------------
    // AC: Multi-word content at near-zero maxWidth with only unbreakable tokens
    // -------------------------------------------------------------------------

    @Test func `two-word content at near-zero maxWidth produces exactly two children`() {
        // "Go now" at maxWidth 1.0 — both words exceed maxWidth → 2 children, no loop
        let wrapped = WrappedText(content: "Go now", fontSize: 14, color: .white)
        let constraints = LayoutConstraints(maxWidth: 1.0, maxHeight: 400)
        let tree = LayoutEngine(textMeasurer: stubMeasurer).layout(wrapped, in: constraints)
        #expect(tree.root.children.count == 2)
    }
}
