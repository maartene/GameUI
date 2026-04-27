// GUIContext.swift — Contextual input state passed to the UI renderer.
// Pure GameUI type — no raylib dependency.

public struct GUIContext: Sendable {
    public let mousePosition: Point

    public init(mousePosition: Point) {
        self.mousePosition = mousePosition
    }
}
