// ViewTraversal.swift — library-owned view-tree traversal.
//
// `childViews(of:)` is the single place GameUI describes its own structure. Downstream
// projects used to hand-copy `LayoutEngine.layoutNode`'s dispatch chain into a test helper;
// twice a branch was missing from a copy and whole subtrees were silently skipped, so
// assertions passed against a tree that was never visited. See ADR-006.
//
// It is a free function rather than a `View` extension deliberately (DDD-7): a member on a
// universal protocol can be silently shadowed by a conforming type, which is disqualifying
// for a mechanism whose entire purpose is eliminating silent mis-dispatch. Precedent:
// `hitTestButton`.
//
// It is generic over `V: View` and not `any View`-typed, because `Body` is an associated
// type: inside a function typed `any View`, `view.body` is unreachable. That is the exact
// trap that produced the field's composite-view miss. Call sites *may* hold `any View` —
// Swift opens the existential implicitly at a generic parameter (DDD-8).
//
// PRECONDITION (ODQ-VT-04, confirmed at DISTILL). `childViews` performs no cycle detection
// and imposes no depth cap. A view whose `body` returns a view containing itself recurses
// without bound. This exposure is inherited verbatim from `layoutNode`, which has it today;
// a cap on `childViews` alone would make the two disagree about the same tree, which is a
// worse failure than the one it prevents. The precondition — a view tree is a finite tree,
// not a graph — matches `hitTestButton`'s existing view/node isomorphism precondition.
//
// PARTIALITY. Also inherited, also not introduced here: a user-defined `body` that traps
// (`fatalError`) traps through `childViews`, exactly as it does through `layoutNode`.

// MARK: - Traversal registry
//
// MANDATORY, and enforced by the `constraints` CI job. Every type conforming to `View`
// anywhere in `Sources/GameUI/` must appear exactly once below, in one of two forms:
//
//     // traversal: <TypeName> children <Protocol>.<accessor>
//     // traversal: <TypeName> leaf
//
// The `children`/`leaf` discriminator is load-bearing. Child-bearing type names never
// appear literally in `childViews` — the branches cast to *protocols*, so `VStack` is
// nowhere in the source below — which means a grep for the concrete name would fail for
// precisely the types that matter. Requiring one line per type makes "I forgot this type"
// and "this type genuinely has no children" different lines in a diff.
//
// THE LIMIT, STATED RATHER THAN GLOSSED (DDD-6). This registry proves a type was
// *considered*. It does not prove the accessor written for it is *correct*:
// `// traversal: Grid leaf` on a child-bearing type satisfies the grep and reproduces the
// original bug exactly. The compensating control is `ViewTraversalSlice2CoverageTests`,
// which constructs every child-bearing type around a sentinel child and asserts the
// sentinel is actually reached. Both are required; neither alone suffices, and they fail
// differently — the grep names the type you forgot, the test names the type you
// mis-described.

// traversal: Rectangle                  leaf
// traversal: Text                       leaf
// traversal: Texture                    leaf
// traversal: Spacer                     leaf
// traversal: WrappedText                leaf
// traversal: ProgressBar                leaf
// traversal: Slider                     leaf
// traversal: Checkbox                   leaf
// traversal: Never                      leaf
// traversal: FrameModifier              children HasFrameSize.framedContent
// traversal: Button                     children AnyButton.anyContent
// traversal: ZStack                     children ZStackView.zStackChildren
// traversal: VStack                     children ContainerView.containerChildren
// traversal: HStack                     children ContainerView.containerChildren
// traversal: PaddingModifier            children AnyDirectionalPaddingModifier.paddingContent
// traversal: DirectionalPaddingModifier children AnyDirectionalPaddingModifier.paddingContent
// traversal: TupleView2                 children ChildrenProviding.viewChildren
// traversal: TupleView3                 children ChildrenProviding.viewChildren
// traversal: TupleView4                 children ChildrenProviding.viewChildren
//
// `Never` (`extension Never: View`, View.swift:9) is the one conformance declared in an
// extension. It is invisible to the registry regex by construction and is allowlisted
// explicitly in the CI step. It is a leaf in the only sense available to an uninhabited
// type: there is no value of it to take children from.
//
// `PaddingModifier` also conforms to the deprecated `AnyPaddingModifier`. It gets no branch
// of its own — a second padding branch would resurrect the dispatch-order fragility ADR-003
// closed.

// MARK: - Traversal

/// The child *views* of `view`, in the order a renderer would encounter them.
///
/// Branch order mirrors `LayoutEngine.layoutNode` — `Text`, `HasFrameSize`, `AnyButton`,
/// `ZStackView`, `WrappedText`, `ContainerView`, `AnyDirectionalPaddingModifier` — plus one
/// branch `layoutNode` does not have (`ChildrenProviding`, DDD-9) and the same
/// `V.Body.self != Never.self` composite fallback.
///
/// Total: defined for every `V: View`. A view matching no branch whose `Body` is `Never`
/// returns `[]`. There is no crash and no "unclassified" state.
///
/// `Text` and `WrappedText` return `[]`. Their `LayoutNode` children are generated geometry,
/// not views, and are therefore not collectable.
///
/// Pure and deterministic. `.body` is evaluated only when the view is genuinely composite,
/// exactly as `layoutNode` does.
///
/// - Precondition: the view tree is finite. See the file header (ODQ-VT-04).
public func childViews<V: View>(of view: V) -> [any View] {
    if view is Text {
        return []
    }
    if let framed = view as? any HasFrameSize {
        return [framed.framedContent]
    }
    if let button = view as? AnyButton {
        return [button.anyContent]
    }
    if let zStack = view as? ZStackView {
        return zStack.zStackChildren
    }
    if view is WrappedText {
        return []
    }
    if let container = view as? ContainerView {
        return container.containerChildren
    }
    if let padded = view as? any AnyDirectionalPaddingModifier {
        return [padded.paddingContent]
    }
    // Not in `layoutNode` (DDD-9): a bare `TupleViewN` from a multi-statement
    // `@ViewBuilder` body is a view in its own right and its children must be visible.
    if let provider = view as? ChildrenProviding {
        return provider.viewChildren
    }
    // Composite view: resolve its body. Primitive views use Body == Never and are
    // handled by the branches above; only user-defined composites reach here.
    if V.Body.self != Never.self {
        return [view.body]
    }
    return []
}
