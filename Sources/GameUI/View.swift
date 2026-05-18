// View.swift — View protocol for the GameUI declarative UI system.
// Mirrors the SwiftUI primitive pattern: leaf views use a Never body.

public protocol View {
    associatedtype Body: View
    var body: Body { get }
}

extension Never: View {
    public var body: Never { fatalError("Never body should not be called") }
}

// Protocol allowing LayoutEngine to pattern-match any FrameModifier<Content> without
// knowing the concrete Content type.
public protocol HasFrameSize {
    var frameWidth: Float { get }
    var frameHeight: Float { get }
    var framedContent: any View { get }
}

// FrameModifier wraps a view with an explicit fixed size.
public struct FrameModifier<Content: View>: View, HasFrameSize {
    public let content: Content
    public let width: Float
    public let height: Float

    public init(content: Content, width: Float, height: Float) {
        self.content = content
        self.width = width
        self.height = height
    }

    public var frameWidth: Float { width }
    public var frameHeight: Float { height }
    public var framedContent: any View { content }

    public var body: Never { fatalError("FrameModifier is a primitive view") }
}

// View extension providing the .frame(width:height:) modifier.
extension View {
    public func frame(width: Float, height: Float) -> FrameModifier<Self> {
        FrameModifier(content: self, width: width, height: height)
    }

    public func padding(_ amount: Float) -> PaddingModifier<Self> {
        PaddingModifier(content: self, amount: amount)
    }

    public func padding(x: Float, y: Float) -> DirectionalPaddingModifier<Self> {
        DirectionalPaddingModifier(content: self, x: x, y: y)
    }
}

// Protocol allowing LayoutEngine to pattern-match any PaddingModifier<Content> without
// knowing the concrete Content type.
@available(*, deprecated, renamed: "AnyDirectionalPaddingModifier")
public protocol AnyPaddingModifier {
    var paddingAmount: Float { get }
    var paddingContent: any View { get }
}

// Single dispatch protocol for all padding — uniform and directional.
public protocol AnyDirectionalPaddingModifier {
    var paddingX: Float { get }
    var paddingY: Float { get }
    var paddingContent: any View { get }
}

// PaddingModifier insets a child view by a uniform amount on all sides.
public struct PaddingModifier<Content: View>: View, AnyPaddingModifier, AnyDirectionalPaddingModifier {
    public let content: Content
    public let amount: Float

    public init(content: Content, amount: Float) {
        self.content = content
        self.amount = amount
    }

    @available(*, deprecated, message: "Use paddingX or paddingY via AnyDirectionalPaddingModifier")
    public var paddingAmount: Float { amount }
    public var paddingX: Float { amount }
    public var paddingY: Float { amount }
    public var paddingContent: any View { content }

    public var body: Never { fatalError("PaddingModifier is a primitive view") }
}

// DirectionalPaddingModifier insets a child view by independent horizontal (x) and vertical (y) amounts.
public struct DirectionalPaddingModifier<Content: View>: View, AnyDirectionalPaddingModifier {
    public let content: Content
    public let x: Float
    public let y: Float

    public init(content: Content, x: Float, y: Float) {
        self.content = content
        self.x = x
        self.y = y
    }

    public var paddingX: Float { x }
    public var paddingY: Float { y }
    public var paddingContent: any View { content }

    public var body: Never { fatalError("DirectionalPaddingModifier is a primitive view") }
}
