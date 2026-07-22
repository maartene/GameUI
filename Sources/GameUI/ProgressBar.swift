// ProgressBar.swift — Display-only progress bar leaf view for GameUI.
//
// value: Float — caller's raw magnitude. Stored verbatim (AC-14).
// clampedValue: Float — renderer-facing, guaranteed in 0...1 for every Float input.
//
// See: ADR-005, docs/product/architecture/brief.md § progress-bar Feature.

public struct ProgressBar: View {
    public let value: Float
    public let label: String
    public let fillColor: Color
    public let trackColor: Color

    public init(
        value: Float,
        label: String,
        fillColor: Color = .green,
        trackColor: Color = .darkGray
    ) {
        self.value = value
        self.label = label
        self.fillColor = fillColor
        self.trackColor = trackColor
    }

    /// The fill fraction a renderer must use. Always in `0.0...1.0`.
    ///
    /// Renderers read this, never `value` — see the renderer contract in
    /// `docs/product/architecture/brief.md`.
    ///
    /// - Important: must not be implemented with `min`/`max`. Both propagate NaN,
    ///   so `min(1, max(0, .nan))` returns NaN and the guarantee fails at exactly
    ///   the input it exists for. Use negated comparisons (ADR-005, Decision 2).
    public var clampedValue: Float {
        if !(value > 0) { return 0 }  // negated comparison: NaN lands here
        if value > 1 { return 1 }
        return value
    }

    public var body: Never { fatalError("ProgressBar is a primitive view") }
}
