// LayoutEngine.swift — Pure layout engine for the GameUI declarative UI system.
// No side effects, no Raylib dependency. Same input always produces same output.

public struct LayoutNode {
    public let frame: Rect
    public let children: [LayoutNode]

    public init(frame: Rect, children: [LayoutNode] = []) {
        self.frame = frame
        self.children = children
    }
}

public struct LayoutTree {
    public let root: LayoutNode

    public init(root: LayoutNode) {
        self.root = root
    }
}

public struct LayoutEngine {
    public let textMeasurer: (@Sendable (String, Float) -> Size)?

    public init(textMeasurer: (@Sendable (String, Float) -> Size)? = nil) {
        self.textMeasurer = textMeasurer
    }

    public func layout(_ view: some View, in constraints: LayoutConstraints) -> LayoutTree {
        let node = layoutNode(view, in: constraints, origin: .zero)
        return LayoutTree(root: node)
    }

    private func layoutNode(_ view: some View, in constraints: LayoutConstraints, origin: Point) -> LayoutNode {
        if let textView = view as? Text {
            return layoutTextNode(textView, in: constraints, origin: origin)
        }
        if let framed = view as? any HasFrameSize {
            let size = Size(
                width: min(framed.frameWidth, constraints.maxWidth),
                height: min(framed.frameHeight, constraints.maxHeight)
            )
            let childConstraints = LayoutConstraints(maxWidth: size.width, maxHeight: size.height)
            let childNode = layoutNode(framed.framedContent, in: childConstraints, origin: origin)
            return LayoutNode(frame: Rect(origin: origin, size: size), children: [childNode])
        }
        if let button = view as? AnyButton {
            let childNode = layoutNode(button.anyContent, in: constraints, origin: origin)
            return LayoutNode(frame: childNode.frame, children: [childNode])
        }
        if let zStack = view as? ZStackView {
            return layoutZStackNode(zStack, in: constraints, origin: origin)
        }
        if let wt = view as? WrappedText {
            return layoutWrappedTextNode(wt, in: constraints, origin: origin)
        }
        if let container = view as? ContainerView {
            return layoutContainerNode(container, in: constraints, origin: origin)
        }
        if let padded = view as? any AnyPaddingModifier {
            return layoutPaddingNode(padded, in: constraints, origin: origin)
        }
        return LayoutNode(frame: Rect(origin: origin, size: Size(width: constraints.maxWidth, height: constraints.maxHeight)))
    }

    private func layoutTextNode(_ textView: Text, in constraints: LayoutConstraints, origin: Point) -> LayoutNode {
        let size: Size
        if let measurer = textMeasurer {
            size = measurer(textView.content, textView.fontSize)
        } else {
            size = Size(
                width: textView.fontSize * Float(textView.content.count),
                height: textView.fontSize
            )
        }
        return LayoutNode(frame: Rect(origin: origin, size: size))
    }

    private func layoutPaddingNode(_ padded: any AnyPaddingModifier, in constraints: LayoutConstraints, origin: Point) -> LayoutNode {
        let amount = padded.paddingAmount
        let outerSize = outerSizeForPaddedContent(padded.paddingContent, amount: amount, constraints: constraints)
        let childConstraints = LayoutConstraints(
            maxWidth: max(0, outerSize.width - 2 * amount),
            maxHeight: max(0, outerSize.height - 2 * amount)
        )
        let childOrigin = Point(x: origin.x + amount, y: origin.y + amount)
        let childNode = layoutNode(padded.paddingContent, in: childConstraints, origin: childOrigin)
        let paddingSize = Size(
            width: min(childNode.frame.size.width + 2 * amount, constraints.maxWidth),
            height: min(childNode.frame.size.height + 2 * amount, constraints.maxHeight)
        )
        return LayoutNode(frame: Rect(origin: origin, size: paddingSize), children: [childNode])
    }

    private func outerSizeForPaddedContent(_ content: any View, amount: Float, constraints: LayoutConstraints) -> Size {
        if let framed = content as? any HasFrameSize {
            return Size(
                width: min(framed.frameWidth, constraints.maxWidth),
                height: min(framed.frameHeight, constraints.maxHeight)
            )
        }
        return Size(width: constraints.maxWidth, height: constraints.maxHeight)
    }

    private func layoutContainerNode(_ container: ContainerView, in constraints: LayoutConstraints, origin: Point) -> LayoutNode {
        let children = container.containerChildren
        let spacing = container.containerSpacing
        let isVertical = container.isVertical

        let (fixedChildSizes, fixedSizeTotal) = measureFixedChildren(children, in: constraints, isVertical: isVertical)
        let share = spacerShare(
            spacerCount: children.filter { $0 is Spacer }.count,
            fixedSizeTotal: fixedSizeTotal,
            childCount: children.count,
            spacing: spacing,
            constraints: constraints,
            isVertical: isVertical
        )

        let childNodes = placeChildren(
            children,
            fixedChildSizes: fixedChildSizes,
            spacerShare: share,
            spacing: spacing,
            isVertical: isVertical,
            constraints: constraints,
            origin: origin
        )

        let containerSize = totalContainerSize(from: childNodes, isVertical: isVertical, spacing: spacing, constraints: constraints)
        return LayoutNode(frame: Rect(origin: origin, size: containerSize), children: childNodes)
    }

    private func measureFixedChildren(
        _ children: [any View],
        in constraints: LayoutConstraints,
        isVertical: Bool
    ) -> (sizes: [Int: Size], axisTotal: Float) {
        var axisTotal: Float = 0
        var sizes: [Int: Size] = [:]
        for (index, child) in children.enumerated() {
            guard !(child is Spacer) else { continue }
            let node = layoutNode(child, in: constraints, origin: .zero)
            sizes[index] = node.frame.size
            axisTotal += isVertical ? node.frame.size.height : node.frame.size.width
        }
        return (sizes, axisTotal)
    }

    private func spacerShare(
        spacerCount: Int,
        fixedSizeTotal: Float,
        childCount: Int,
        spacing: Float,
        constraints: LayoutConstraints,
        isVertical: Bool
    ) -> Float {
        guard spacerCount > 0 else { return 0 }
        let totalSpacing = Float(max(childCount - 1, 0)) * spacing
        let axisConstraint: Float = isVertical ? constraints.maxHeight : constraints.maxWidth
        let remaining = max(0, axisConstraint - fixedSizeTotal - totalSpacing)
        return remaining / Float(spacerCount)
    }

    private func placeChildren(
        _ children: [any View],
        fixedChildSizes: [Int: Size],
        spacerShare: Float,
        spacing: Float,
        isVertical: Bool,
        constraints: LayoutConstraints,
        origin: Point
    ) -> [LayoutNode] {
        var childNodes: [LayoutNode] = []
        var cursor: Float = 0

        for (index, child) in children.enumerated() {
            let childOrigin = isVertical
                ? Point(x: origin.x, y: origin.y + cursor)
                : Point(x: origin.x + cursor, y: origin.y)

            let childNode = makeChildNode(
                child,
                index: index,
                at: childOrigin,
                fixedChildSizes: fixedChildSizes,
                spacerShare: spacerShare,
                isVertical: isVertical,
                constraints: constraints
            )

            childNodes.append(childNode)
            cursor += (isVertical ? childNode.frame.size.height : childNode.frame.size.width) + spacing
        }

        return childNodes
    }

    private func makeChildNode(
        _ child: any View,
        index: Int,
        at childOrigin: Point,
        fixedChildSizes: [Int: Size],
        spacerShare: Float,
        isVertical: Bool,
        constraints: LayoutConstraints
    ) -> LayoutNode {
        if child is Spacer {
            let spacerSize = isVertical
                ? Size(width: constraints.maxWidth, height: spacerShare)
                : Size(width: spacerShare, height: constraints.maxHeight)
            return LayoutNode(frame: Rect(origin: childOrigin, size: spacerSize))
        }
        if let fixedSize = fixedChildSizes[index] {
            // Re-layout with absolute origin so grandchildren (e.g. ZStack inside Button) get
            // correct positions. The measured size from pass 1 is reused; only the tree is rebuilt.
            let recursed = layoutNode(child, in: constraints, origin: childOrigin)
            return LayoutNode(frame: Rect(origin: childOrigin, size: fixedSize), children: recursed.children)
        }
        return layoutNode(child, in: constraints, origin: childOrigin)
    }

    private func totalContainerSize(
        from childNodes: [LayoutNode],
        isVertical: Bool,
        spacing: Float,
        constraints: LayoutConstraints
    ) -> Size {
        let gapTotal = Float(max(childNodes.count - 1, 0)) * spacing
        let totalWidth: Float
        let totalHeight: Float
        if isVertical {
            totalWidth = childNodes.map { $0.frame.size.width }.max() ?? 0
            totalHeight = childNodes.reduce(0) { $0 + $1.frame.size.height } + gapTotal
        } else {
            totalWidth = childNodes.reduce(0) { $0 + $1.frame.size.width } + gapTotal
            totalHeight = childNodes.map { $0.frame.size.height }.max() ?? 0
        }
        return Size(
            width: min(totalWidth, constraints.maxWidth),
            height: min(totalHeight, constraints.maxHeight)
        )
    }

    private func layoutZStackNode(_ zStack: ZStackView, in constraints: LayoutConstraints, origin: Point) -> LayoutNode {
        let childNodes = zStack.zStackChildren.map { layoutNode($0, in: constraints, origin: origin) }
        let maxWidth = childNodes.map { $0.frame.size.width }.max() ?? 0
        let maxHeight = childNodes.map { $0.frame.size.height }.max() ?? 0
        let size = Size(
            width: min(maxWidth, constraints.maxWidth),
            height: min(maxHeight, constraints.maxHeight)
        )
        return LayoutNode(frame: Rect(origin: origin, size: size), children: childNodes)
    }

    private func layoutWrappedTextNode(_ wt: WrappedText, in constraints: LayoutConstraints, origin: Point) -> LayoutNode {
        let lines = wt.wrappedLines(measurer: textMeasurer, maxWidth: constraints.maxWidth)
        let childNodes = lines.enumerated().map { (i, line) -> LayoutNode in
            let lineWidth = textMeasurer.map { $0(line, wt.fontSize).width } ?? (wt.fontSize * Float(line.count))
            let childOrigin = Point(x: origin.x, y: origin.y + Float(i) * wt.fontSize)
            return LayoutNode(frame: Rect(origin: childOrigin, size: Size(width: lineWidth, height: wt.fontSize)))
        }
        let height = Float(lines.count) * wt.fontSize
        return LayoutNode(
            frame: Rect(origin: origin, size: Size(width: constraints.maxWidth, height: height)),
            children: childNodes
        )
    }
}
