// Collect.swift — type-directed collection over a declared view tree.
//
// `GameUITesting` is a plain `.target` with a `.library` product, NOT a `.testTarget`: only
// a plain target produces something a *downstream* test target can `import`. It is shipped
// code and is bound by every § Technology Constraints rule that binds `GameUI` — Swift 6.2,
// no Foundation, `Float`-only geometry, zero third-party dependencies. It falls inside
// `Sources/`, so the CI `constraints` job sweeps it with no workflow change.
//
// `@testable import GameUI` is rejected (ADR-006 Alternative E): `@testable` requires
// `-enable-testing`, which SwiftPM applies to a test build of the local package and not to
// a package consumed as a release dependency. It would compile here and fail at every
// consumer — the one place it must work.
//
// CONSTRAINT (ADR-006, enforced by CI grep). This target must contain **no** `as?` cast to
// `ContainerView`, `ZStackView`, `AnyButton`, `HasFrameSize`, `AnyDirectionalPaddingModifier`
// or `ChildrenProviding`. All traversal knowledge lives in `GameUI.childViews(of:)`. A
// fourth dispatch chain here would sit in the one place the registry check does not look.

import GameUI

/// Every view of type `T` in the tree rooted at `view`, in depth-first declaration order.
///
/// `T` may be concrete (`collect(ProgressBar.self, from: screen)`) or existential
/// (`collect((any AnyButton).self, from: screen)`). The root itself is included when it
/// matches.
///
/// Traversal is delegated wholly to `GameUI.childViews(of:)`; this function performs no
/// dispatch of its own. That is the entire point of the feature: downstream stops
/// maintaining a copy of GameUI's dispatch chain, so it can no longer fall behind it.
///
/// - Precondition: the view tree is finite. Inherited from `childViews` (ODQ-VT-04).
public func collect<T>(_ type: T.Type, from view: some View) -> [T] {
    var found: [T] = []
    if let match = view as? T {
        found.append(match)
    }
    // A `for` loop with a named binding, not `children.flatMap { ... }`: implicit
    // existential opening fails for a closure parameter of implicit type (ODQ-VT-09).
    for child in childViews(of: view) {
        found.append(contentsOf: collect(type, from: child))
    }
    return found
}
