// WrappedText.swift — Leaf primitive for word-wrapping text in constrained areas.

public struct WrappedText: View {
    public let content: String
    public let fontSize: Float
    public let color: Color

    public init(content: String, fontSize: Float, color: Color) {
        self.content = content
        self.fontSize = fontSize
        self.color = color
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
}
