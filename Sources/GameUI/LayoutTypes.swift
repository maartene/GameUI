// LayoutTypes.swift — Core geometry value types for the GameUI layout system.
// All Float-based for Linux compatibility (no CGFloat, no Foundation).

public struct Point: Equatable, Sendable {
    public let x: Float
    public let y: Float

    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }

    public static let zero = Point(x: 0, y: 0)
}

public struct Size: Equatable, Sendable {
    public let width: Float
    public let height: Float

    public init(width: Float, height: Float) {
        self.width = width
        self.height = height
    }

    public static let zero = Size(width: 0, height: 0)
}

public struct Rect: Equatable, Sendable {
    public let origin: Point
    public let size: Size

    public init(origin: Point, size: Size) {
        self.origin = origin
        self.size = size
    }

    public static let zero = Rect(origin: .zero, size: .zero)

    public func contains(_ point: Point) -> Bool {
        point.x >= origin.x && point.x < origin.x + size.width &&
        point.y >= origin.y && point.y < origin.y + size.height
    }
}

public struct LayoutConstraints: Sendable {
    public let maxWidth: Float
    public let maxHeight: Float

    public init(maxWidth: Float, maxHeight: Float) {
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
    }
}
