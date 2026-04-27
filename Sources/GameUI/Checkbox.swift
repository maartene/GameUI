// Checkbox.swift — Toggleable checkbox leaf view for GameUI.

public struct Checkbox: View {
    public let isChecked: Bool
    public let label: String
    public let subtitle: String?
    /// Called when the user taps the checkbox to toggle it.
    public let onToggle: (@Sendable () -> Void)?

    public init(isChecked: Bool, label: String, subtitle: String? = nil, onToggle: (@Sendable () -> Void)? = nil) {
        self.isChecked = isChecked
        self.label = label
        self.subtitle = subtitle
        self.onToggle = onToggle
    }

    public var body: Never { fatalError("Checkbox is a primitive view") }
}
