// LeafViews.swift — Primitive leaf view types for GameUI.

public enum TextAlignment: Sendable {
    case center
    case leading
}

public struct Rectangle: View {
    public let color: Color

    public init(color: Color = .white) {
        self.color = color
    }

    public var body: Never { fatalError("Rectangle is a primitive view") }
}

public struct Text: View {
    public let content: String
    public let fontSize: Float
    public let color: Color
    public let alignment: TextAlignment

    public init(content: String, fontSize: Float, color: Color = .white, alignment: TextAlignment = .center) {
        self.content = content
        self.fontSize = fontSize
        self.color = color
        self.alignment = alignment
    }

    public var body: Never { fatalError("Text is a primitive view") }
}

public struct Texture: View {
    public let textureName: String
    public let tint: Color

    public init(textureName: String, tint: Color = .white) {
        self.textureName = textureName
        self.tint = tint
    }

    public var body: Never { fatalError("Texture is a primitive view") }
}

/// Type-erased protocol allowing LayoutEngine to recurse into Button<Content>
/// without knowing the concrete Content type.
public protocol AnyButton {
    var anyContent: any View { get }
    var anyAction: @Sendable () -> Void { get }
}

public struct Button<Content: View>: View, AnyButton {
    public let action: @Sendable () -> Void
    public let content: Content

    public init(action: @escaping @Sendable () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }

    public var anyContent: any View { content }
    public var anyAction: @Sendable () -> Void { action }

    public var body: Never { fatalError("Button is a primitive view") }
}

public struct Spacer: View {
    public init() {}
    public var body: Never { fatalError("Spacer is a primitive view") }
}
