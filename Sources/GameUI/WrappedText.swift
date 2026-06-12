// WrappedText.swift — Leaf primitive for word-wrapping text in constrained areas.

public struct WrappedText: View {
    public let content: String
    public let fontSize: Float
    public let color: Color
    public let maxLines: Int?

    public init(content: String, fontSize: Float, color: Color, maxLines: Int? = nil) {
        self.content = content
        self.fontSize = fontSize
        self.color = color
        self.maxLines = maxLines
    }

    public var body: Never { fatalError("WrappedText is a primitive view") }

    /// Splits `content` into lines, each measuring ≤ `maxWidth` using `measurer`.
    /// Falls back to `fontSize * charCount` when `measurer` is nil.
    /// Returns empty array for empty content. Handles unbreakable words without looping.
    public func wrappedLines(
        measurer: (@Sendable (String, Float) -> Size)?,
        maxWidth: Float
    ) -> [String] {
        let words = content.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard !words.isEmpty else { return [] }

        var lines: [String] = []
        var currentLine = ""

        for word in words {
            let candidate = currentLine.isEmpty ? word : currentLine + " " + word
            let candidateWidth = measurer.map { $0(candidate, fontSize).width } ?? (fontSize * Float(candidate.count))
            if candidateWidth <= maxWidth {
                currentLine = candidate
            } else {
                if !currentLine.isEmpty {
                    lines.append(currentLine)
                }
                currentLine = word
            }
        }

        if !currentLine.isEmpty {
            lines.append(currentLine)
        }

        return lines
    }

    /// Returns `wrappedLines` clipped to `maxLines`. Call this from renderers when `maxLines` may be set.
    /// Invariant: `clippedLines(...).count == node.children.count` when layout and render use the same measurer and constraints.
    public func clippedLines(
        measurer: (@Sendable (String, Float) -> Size)?,
        maxWidth: Float
    ) -> [String] {
        return Array(wrappedLines(measurer: measurer, maxWidth: maxWidth).prefix(maxLines ?? Int.max))
    }
}
