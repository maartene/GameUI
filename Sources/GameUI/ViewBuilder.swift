// ViewBuilder.swift — @resultBuilder for declarative view composition.

// TupleView types for multi-child composition.

/// Implemented by TupleView types so LayoutEngine can extract children without generics.
public protocol ChildrenProviding {
    var viewChildren: [any View] { get }
}

public struct TupleView2<V0: View, V1: View>: View, ChildrenProviding {
    public let v0: V0
    public let v1: V1
    public init(_ v0: V0, _ v1: V1) { self.v0 = v0; self.v1 = v1 }
    public var body: Never { fatalError("TupleView2 is a primitive view") }
    public var viewChildren: [any View] { [v0, v1] }
}

public struct TupleView3<V0: View, V1: View, V2: View>: View, ChildrenProviding {
    public let v0: V0
    public let v1: V1
    public let v2: V2
    public init(_ v0: V0, _ v1: V1, _ v2: V2) { self.v0 = v0; self.v1 = v1; self.v2 = v2 }
    public var body: Never { fatalError("TupleView3 is a primitive view") }
    public var viewChildren: [any View] { [v0, v1, v2] }
}

public struct TupleView4<V0: View, V1: View, V2: View, V3: View>: View, ChildrenProviding {
    public let v0: V0
    public let v1: V1
    public let v2: V2
    public let v3: V3
    public init(_ v0: V0, _ v1: V1, _ v2: V2, _ v3: V3) {
        self.v0 = v0; self.v1 = v1; self.v2 = v2; self.v3 = v3
    }
    public var body: Never { fatalError("TupleView4 is a primitive view") }
    public var viewChildren: [any View] { [v0, v1, v2, v3] }
}

@resultBuilder
public enum ViewBuilder {
    public static func buildBlock<V: View>(_ v: V) -> V { v }

    public static func buildBlock<V0: View, V1: View>(
        _ v0: V0, _ v1: V1
    ) -> TupleView2<V0, V1> {
        TupleView2(v0, v1)
    }

    public static func buildBlock<V0: View, V1: View, V2: View>(
        _ v0: V0, _ v1: V1, _ v2: V2
    ) -> TupleView3<V0, V1, V2> {
        TupleView3(v0, v1, v2)
    }

    public static func buildBlock<V0: View, V1: View, V2: View, V3: View>(
        _ v0: V0, _ v1: V1, _ v2: V2, _ v3: V3
    ) -> TupleView4<V0, V1, V2, V3> {
        TupleView4(v0, v1, v2, v3)
    }
}
