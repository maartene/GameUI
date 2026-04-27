// Slider.swift — Slider leaf view for GameUI.
// value: Float in [0.0, 1.0] — displayed as integer 0–100.

public struct Slider: View {
    public let value: Float
    public let label: String
    /// Called when the user taps/clicks the slider. Argument is the new value (0.0–1.0).
    public let onTap: (@Sendable (Float) -> Void)?

    public init(value: Float, label: String, onTap: (@Sendable (Float) -> Void)? = nil) {
        self.value = value
        self.label = label
        self.onTap = onTap
    }

    public var body: Never { fatalError("Slider is a primitive view") }
}
