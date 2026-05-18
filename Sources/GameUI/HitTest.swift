// HitTest.swift — Hit testing for button views in the GameUI layout system.
//
// Precondition: `view` and `node` must be produced from the same layout pass
// (structurally isomorphic). Behaviour is undefined if trees diverge.

/// Returns the traversal-order index of the first `AnyButton` in `view` whose
/// `LayoutNode.frame` contains `point`, or `nil` if no button frame contains
/// the point.
///
/// Traversal is depth-first, matching view-tree construction order.
/// This function is pure: it has no side effects and never invokes any button's action.
public func hitTestButton(view: any View, node: LayoutNode, at point: Point) -> Int? {
    var index = 0
    return hitTestNode(view, node, at: point, index: &index)
}

private func hitTestNode(_ view: any View, _ node: LayoutNode, at point: Point, index: inout Int) -> Int? {
    if let button = view as? any AnyButton {
        let capturedIndex = index
        index += 1
        if node.frame.contains(point) {
            return capturedIndex
        }
        // Recurse into button content (handles nested views inside button)
        if !node.children.isEmpty {
            return hitTestNode(button.anyContent, node.children[0], at: point, index: &index)
        }
        return nil
    }
    if let container = view as? ContainerView {
        let children = container.containerChildren
        for (child, childNode) in zip(children, node.children) {
            if let hit = hitTestNode(child, childNode, at: point, index: &index) {
                return hit
            }
        }
        return nil
    }
    if let zStack = view as? ZStackView {
        let children = zStack.zStackChildren
        for (child, childNode) in zip(children, node.children) {
            if let hit = hitTestNode(child, childNode, at: point, index: &index) {
                return hit
            }
        }
        return nil
    }
    if let framed = view as? any HasFrameSize {
        if !node.children.isEmpty {
            return hitTestNode(framed.framedContent, node.children[0], at: point, index: &index)
        }
        return nil
    }
    if let padded = view as? any AnyPaddingModifier {
        if !node.children.isEmpty {
            return hitTestNode(padded.paddingContent, node.children[0], at: point, index: &index)
        }
        return nil
    }
    return nil
}
