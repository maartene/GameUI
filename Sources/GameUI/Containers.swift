// Containers.swift — Layout container views (HStack, VStack, ZStack).

/// Implemented by VStack and HStack so LayoutEngine can recurse without generics.
public protocol ContainerView {
    var containerChildren: [any View] { get }
    var containerSpacing: Float { get }
    var isVertical: Bool { get }
}

public struct VStack<Content: View>: View, ContainerView {
    public let spacing: Float
    public let content: Content

    public init(spacing: Float = 0, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: Never { fatalError("VStack is a primitive view") }

    public var containerChildren: [any View] {
        if let provider = content as? ChildrenProviding {
            return provider.viewChildren
        }
        return [content]
    }
    public var containerSpacing: Float { spacing }
    public var isVertical: Bool { true }
}

public struct HStack<Content: View>: View, ContainerView {
    public let spacing: Float
    public let content: Content

    public init(spacing: Float = 0, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: Never { fatalError("HStack is a primitive view") }

    public var containerChildren: [any View] {
        if let provider = content as? ChildrenProviding {
            return provider.viewChildren
        }
        return [content]
    }
    public var containerSpacing: Float { spacing }
    public var isVertical: Bool { false }
}

/// Implemented by ZStack so LayoutEngine can place all children at the same origin.
public protocol ZStackView {
    var zStackChildren: [any View] { get }
}

public struct ZStack<Content: View>: View, ZStackView {
    public let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: Never { fatalError("ZStack is a primitive view") }

    public var zStackChildren: [any View] {
        if let provider = content as? ChildrenProviding {
            return provider.viewChildren
        }
        return [content]
    }
}
