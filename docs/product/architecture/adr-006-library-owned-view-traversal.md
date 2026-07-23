# ADR-006: Library-Owned View-Tree Traversal and the `GameUITesting` Target

## Status

Accepted

---

## Context

Two independent downstream projects that consume GameUI have each hand-written a test helper that
walks a view tree and extracts the views of a given type, so their tests can assert on the *declared
UI* rather than on layout geometry. The field evidence is
`SpaceSim/Tests/SpaceSimTests/TestDoubles/RecordingGameUIAdapter.swift`:

```swift
private func children<V: GameUI.View>(of view: V) -> [any GameUI.View] {
    if let framed = view as? any HasFrameSize { return [framed.framedContent] }
    if let padded = view as? any AnyDirectionalPaddingModifier { return [padded.paddingContent] }
    if let button = view as? any AnyButton { return [button.anyContent] }
    if let zStack = view as? ZStackView { return zStack.zStackChildren }
    if let container = view as? ContainerView { return container.containerChildren }
    if V.Body.self != Never.self { return [view.body] }
    return []
}
```

That is a hand-copy of the dispatch chain in `LayoutEngine.layoutNode`
(`Sources/GameUI/LayoutEngine.swift:35-68`).

The failure mode is not "the helper crashes". It is **silent under-traversal**: a branch missing from
a copy means a whole subtree is never visited, `collect` returns `[]`, and the test asserting
`#expect(buttons.isEmpty)` *passes for the wrong reason*. This has happened twice. `brief.md` records
one instance verbatim: *"`RecordingGameUIAdapter` requires a `HasFrameSize` traversal fix"*
(§ wrapped-text-max-lines, Reuse Analysis).

### The incidents were distribution failures, not drift failures

This distinction sets the scope of the decision, and an earlier draft of this ADR got it wrong.

In both incidents, **GameUI already had the branch**. The bug was that a copy living in a repository
whose authors do not maintain GameUI's dispatch chain had fallen behind it. The failure was not that
GameUI's knowledge was wrong; it was that GameUI's knowledge had been *transcribed* into places that
could not be kept honest.

Shipping one working `collect(_:from:)` from GameUI kills both incidents outright, because the
downstream projects stop having a chain at all. **Moving the chain from the consumer site to the
library site is most of the value here, because it relocates the mistake to where the knowledge
is.** A branch omitted in `Sources/GameUI/` is omitted by someone who is looking at the view types
while they omit it, in a repository with 175 tests and a CI job; a branch omitted downstream is
omitted by someone who has never read `layoutNode`.

There is a *second*, genuinely different problem: in-repo drift between `layoutNode`, `hitTestNode`
and a new traversal helper, all three of which carry an `as?` chain. That problem is real, but it is
not the problem the incidents demonstrate, and conflating the two led the earlier draft to propose a
large refactor of shipped layout code on the strength of evidence that did not support it.

### Three questions

**Question 1 — where does the helper live: `GameUI`, a new target, or both?** The `collect` entry
point is domain-neutral. The *conveniences* (`collectTexts`, `collectTextColors`, …) are test-shaped:
they name intent at an assertion site, and no game screen has any use for "every `Text` in this
subtree, flattened".

**Question 2 — how is completeness enforced going forward?** Swift gives no exhaustiveness check over
a chain of `if let x = view as? P`. A child-bearing view type added in six months is, by construction,
invisible to a traversal that has no branch for it. Any solution that does not make that omission
*loud* re-ships the bug class in a tidier wrapper — and that standard has to be applied to whatever
this ADR proposes, not only to what it rejects.

**Question 3 — how much shipped code does this feature touch?** `layoutNode` and `hitTestNode` are the
two most load-bearing functions in the package.

---

## Decision

### Decision 1 — A new `GameUITesting` target and library product

`Package.swift` gains a plain `.target(name: "GameUITesting", dependencies: ["GameUI"])` — **not** a
`.testTarget` — and a second `.library(name: "GameUITesting", targets: ["GameUITesting"])` product.
`Tests/GameUITests` depends on it, and so may any downstream test target, via a normal
`import GameUITesting`.

`GameUITesting` ships `collect(_:from:)` and the domain-neutral conveniences `collectTexts`,
`collectButtons`, `collectTextColors`, `collectProgressBars`, `collectTextures`. It ships **no
traversal logic** — see Decision 2. `collectPlayerStatus` is SpaceSim domain vocabulary and does not
travel; downstream expresses it as `collect(PlayerStatusView.self, from: view).first`.

**Rationale.** The split is drawn where the audience changes. `collectTextColors(from:)` is a
sentence a test says and a game screen never says; six such functions on the module every consumer
imports is a permanent tax on discoverability. A `.testTarget`, meanwhile, produces no importable
product, which defeats the entire purpose.

`GameUITesting` is a **shipped** target and is bound by every § Technology Constraints rule: Swift
6.2, `swiftLanguageModes: [.v6]`, no Foundation, `Float`-only, zero third-party dependencies. It
falls inside `Sources/`, so the CI `constraints` job sweeps it with no workflow change.

`@testable import GameUI` from `GameUITesting` is **rejected**. `@testable` requires the imported
module to have been compiled with `-enable-testing`, which is a property of a *test build*, not of a
released library. A downstream project consuming GameUI as a package dependency builds it in release
configuration without testing enabled, so a `@testable` import would compile here and fail at every
consumer — the one place it must work.

### Decision 2 — `childViews(of:)` is public API on `GameUI`, not private to `GameUITesting`

New file `Sources/GameUI/ViewTraversal.swift`:

```
public func childViews<V: View>(of view: V) -> [any View]
```

Branch order mirrors today's `layoutNode` — `Text`, `HasFrameSize`, `AnyButton`, `ZStackView`,
`WrappedText`, `ContainerView`, `AnyDirectionalPaddingModifier` — with one branch `layoutNode` does
not have (`ChildrenProviding`, below) and the same `V.Body.self != Never.self` composite fallback.
`GameUITesting.collect` calls it and contains **no `as?` casts of its own**.

**Rationale.** The chain belongs in the same module and the same directory as the types it dispatches
on. A developer adding a new child-bearing view type to `Sources/GameUI/` should encounter the
traversal registry (Decision 3) in the folder they are already editing, not in a sibling module they
may not have open. Placing it in `GameUITesting` would put the knowledge one module away from the
knowledge it must track — a smaller version of the original defect.

It is `public` rather than `internal` because a downstream author writing a custom renderer needs to
walk the same tree GameUI walks, and today has no supported way to do it. Unlike `collectTextColors`,
`childViews` is not test-shaped: it is the library describing its own structure.

**`childViews` must be generic over `V: View`.** `Body` is an associated type, so inside a function
typed `any View`, `view.body` is unreachable — that is the exact trap that produced the field's
composite-view miss. The corollary is narrower than it is usually stated: *call sites may hold
`any View`*, because Swift opens an existential implicitly when it is passed to a generic parameter.
That is why the field helper's `collectTexts(from: any View)` works today. The rule is **"any
function that must reach `.body` has to be generic"**, not "existentials are forbidden".

**A `ChildrenProviding` branch is added, which `layoutNode` does not have.** `TupleView2/3/4` conform
to `ChildrenProviding` and to nothing else, and `ChildrenProviding` is consumed only at
`Containers.swift:22`, `:43` and `:67` — i.e. only when a container unwraps its own content. A bare
`TupleViewN` reaching `layoutNode` directly therefore matches no branch, so a composite view whose
`body` is a multi-statement `@ViewBuilder` block lays out as an empty fill-constraints box **and** is
invisible to every traversal. `childViews` returns its children, so `collect` sees them. The *layout*
half of that gap is not fixed here — fixing it requires deciding a stacking axis and spacing for an
unadorned tuple, which is a design question, not a refactor. Recorded as ODQ-VT-03.

### Decision 3 — Completeness is enforced by a CI traversal registry, not by the type system

`Sources/GameUI/ViewTraversal.swift` carries a mandatory, greppable registry: **every type conforming
to `View` anywhere in `Sources/GameUI/` must appear exactly once**, in one of two forms.

```
// traversal: VStack       children ContainerView.containerChildren
// traversal: TupleView2   children ChildrenProviding.viewChildren
// traversal: ProgressBar  leaf
// traversal: Never        leaf   (extension Never: View — allowlisted)
```

A new step in the existing `constraints` job extracts the declared conformances, extracts the
registry annotations, and fails on the set difference in either direction, printing the offending
type names. The exact step is specified in `brief.md` § Architectural Enforcement, precise enough for
DELIVER to implement verbatim.

**Rationale — why a registry and not the compiler.** The two candidates with real compile-time
enforcement are a `ViewKind` discriminated union (Alternative B) and a `childViews` requirement on
the `View` protocol itself (Alternative C). Both were considered seriously and both are rejected
below. Given that, the honest choice is between a check that runs in seconds on an existing alpine
job and no check at all.

**Rationale — why the annotation form is mandatory even for leaves.** The type names of child-bearing
views never appear literally in `childViews`: the branches cast to *protocols* (`ContainerView`,
`HasFrameSize`), so `VStack` is nowhere in the source. A grep for the concrete name would therefore
fail for exactly the types that matter. Requiring one annotation line per type, with
`children <Accessor>` or `leaf` as the discriminator, makes "I forgot" and "it genuinely has no
children" **different lines in the diff**. A reviewer sees `// traversal: Grid leaf` and can ask
whether a `Grid` really has no children; a reviewer sees nothing at all when a branch is merely
absent.

**Rationale — why the check targets `childViews` and not `layoutNode`.** The two failure modes are
not symmetric. A `layoutNode` omission is **loud**: the new view type renders as an empty box the
first time anyone looks at it, and the person who notices is the person who just added it. A
`childViews` omission is **silent**: a test passes for the wrong reason, possibly for months.
Enforcement is spent where silence is.

**The limit, stated plainly.** The grep verifies a type was *considered*. It does not verify that the
accessor written for it is *correct*, and it cannot: `// traversal: Grid leaf` on a type that
actually has children satisfies the grep and reproduces the bug. The second half is covered by the
coverage test DISTILL must author — construct each child-bearing type around a sentinel child and
assert `collect(Sentinel.self, from:)` returns it. **Both are required; neither alone suffices**, and
they fail differently: the grep fails on the type you forgot, the coverage test fails on the type you
mis-described.

### Decision 4 — `layoutNode` and `hitTestNode` are not modified

No existing source file changes. `layoutNode` keeps its `as?` chain; `hitTestNode` keeps its own.

**Rationale.** The only argument for touching them was unifying the in-repo chains behind `ViewKind`,
and that has been deferred (Alternative B). Absent it, migrating `hitTestNode` would be churn on a
shipped public function in service of a mechanism this ADR does not adopt. This also restores the
strongest available regression guarantee: **zero existing source files modified**, the same
structural guarantee `progress-bar` had, rather than a behavioural promise about identical layout
output.

The cost is accepted and named: `Sources/GameUI/` will contain **three** `as?` chains — `layoutNode`,
`hitTestNode` and `childViews`. They can drift from each other. The registry check makes the most
dangerous drift (a type absent from `childViews`) loud, and the `layoutNode` variant is loud on its
own. The `hitTestNode` variant is the weakest link and is the strongest remaining argument for
Alternative B when it is revisited.

**ODQ-VT-02 survives this decision unchanged and must not be lost.** During this design it emerged
that `hitTestNode` takes `any View` and therefore has **no composite branch at all**: `hitTestButton`
currently returns `nil` for any button nested inside a user-defined composite view. That is a genuine
latent defect in shipped code. It is not fixed here — fixing it changes observable behaviour *and*
renumbers button indices for any tree containing a composite, so it needs its own acceptance criteria.
It is recorded as **ODQ-VT-02**, to be scheduled as its own feature.

### Decision 5 — the entry point is named `collect(_:from:)`

`collect<T>(_ type: T.Type, from view: some View) -> [T]`, generic over `T` so it serves both concrete
types (`collect(ProgressBar.self, from: v)`) and existentials
(`collect((any AnyButton).self, from: v)`).

**Rationale.** It is already the name in both downstream hand-copies, so migration is deletion, not
rewriting: a call site keeps its arguments and loses its receiver. `findAll` implies a predicate-based
search this is not. `views(ofType:)` reads badly at the existential call site
(`views(ofType: (any AnyButton).self)`) and misdescribes a result that is a `[T]` of protocol
existentials.

---

## Consequences

**Positive.** Both field incidents are eliminated at the root: downstream projects stop having a
traversal chain. The next downstream project inherits a correct traversal instead of copying a stale
one. The ~20 lines each project was maintaining are deleted. A missing branch inside GameUI is caught
by CI in seconds, by name, on the alpine job that already exists.

**Positive.** Zero existing source files are modified — the strongest form of the no-regression
guarantee, and the same one `progress-bar` achieved.

**Positive, incidental.** `childViews` makes multi-statement `@ViewBuilder` bodies traversable for the
first time, and makes the corresponding layout gap (ODQ-VT-03) visible.

**Negative — accepted.** `Sources/GameUI/` now contains three `as?` chains that can drift. The
registry check covers the one whose drift is silent; the other two are loud or weak-but-unchanged.
This is a deliberate trade of in-repo tidiness for zero blast radius on shipped code, and it is what
Alternative B exists to revisit.

**Negative — accepted.** The registry annotation is a human-maintained comment. A developer can
satisfy it dishonestly (`leaf` on a child-bearing type). The coverage test is the compensating
control, and this ADR does not claim otherwise.

**Negative — accepted.** A second product means a downstream consumer adds one line to its test
target's dependencies. Standard Swift convention for test-helper libraries.

**Constraint created.** Every type conforming to `View` in `Sources/GameUI/` must carry exactly one
`// traversal:` registry line in `ViewTraversal.swift`. Enforced by CI.

**Constraint created.** `Sources/GameUITesting/` must contain **no** `as?` cast to `ContainerView`,
`ZStackView`, `AnyButton`, `HasFrameSize`, `AnyDirectionalPaddingModifier` or `ChildrenProviding`. If
`collect` ever grows one, the library has a fourth chain in the one place the registry check does not
look. Enforced by CI grep.

---

## Alternatives Considered

### Alternative A — Re-derive the chain inside `GameUITesting`, leaving `GameUI` untouched

Promote the downstream copy into `GameUITesting` verbatim. No new public API on `GameUI` at all.

**Evaluation.** Rejected on knowledge locality. It solves the distribution problem, but it puts the
chain in a different module from the types it dispatches on, so the developer adding `Grid` to
`Sources/GameUI/` has no reason to open the file that needs updating. The registry check could still
be written against a file in `GameUITesting`, but it would be checking one module's declarations
against another module's comments — coherent, and a worse place to keep the knowledge.

**Quality attribute impact.** Neutral on Safety. Negative on Maintainability (#3): the traversal and
the types it traverses evolve in different modules with no co-location cue.

### Alternative B — `ViewKind` discriminated union as the primary enforcement mechanism

*This was the earlier draft's central decision. The analysis is preserved because it is correct on
its own terms and will be needed when it is revisited.*

A `public enum ViewKind` with one case per dispatch branch, each carrying the matched protocol
existential as payload, produced by `viewKind<V: View>(of:)`. `layoutNode`, `hitTestNode` and
`childViews` all `switch` over it with **no `default:` clause**, so adding a case is a compile error
at every consumer.

**What the analysis got right, and keeps.** A shared `childViews(of:) -> [any View]` genuinely
*cannot* be consumed by `layoutNode`. There is no point in `layoutNode` where "recurse over the
children" is the operation: every branch recurses with branch-specific constraints, origin and node
assembly, and `Text`/`WrappedText` do not recurse over views at all. Any unification of the three
in-repo chains must therefore carry **branch identity plus payload**, not a children list — which is
what a discriminated union is for. That conclusion stands, and it is the reason Alternative B, rather
than some list-shaped variant, is the option to revisit. It is also why `childViews` as decided here
is a *second* chain rather than a shared one: `layoutNode` cannot consume it, so it is not offered to
it.

**Why it is deferred, not rejected.** Its claim was that it makes omission *unrepresentable*. It does
not. `viewKind(of:)` is itself an `as?` chain: add a child-bearing type, forget its case, and it lands
in `.opaqueLeaf` — silently. The enum moves the single silent failure point from three sites to one;
it does not remove it. By this ADR's own Question 2 standard, that is a tidier wrapper around the
same bug class, and the earlier draft applied the standard to every option except its own.

Its real merit is different and narrower: it collapses three in-repo chains into one, which is a
maintainability win worth having. But the registry check makes drift loud *whether or not* the chains
are unified — so the enum must now be judged as a refactor on its own merits, not as the enforcement
mechanism. It also costs a modification to `layoutNode` and `hitTestNode`, a ten-case public enum
that is source-breaking to extend, and the loss of the zero-files-modified guarantee. Recorded as
**ODQ-VT-06**.

**Quality attribute impact.** Positive on Maintainability (#3) — one chain instead of three, with
compiler-enforced consistency *between them*. Neutral on Correctness (#1) against the actual
incidents, which were distribution failures the enum does not address. Negative on Backward
Compatibility (#2) — it trades a structural regression guarantee for a behavioural one on the
package's two most load-bearing functions.

### Alternative C — A `childViews` requirement on the `View` protocol itself

Add `var childViews: [any View] { get }` to `View` with no default implementation. Every conforming
type must supply it or fail to compile. This is the **only** design in the set with true compile-time
enforcement, including for types GameUI cannot see.

**Evaluation.** Rejected on cost-versus-benefit. Its sole advantage over the CI registry is covering
*downstream* types, and downstream can realistically only add **composite** views — a
`struct PlayerStatusView: View` with a real `body`. Those are already handled for free by the
`V.Body.self != Never.self` branch, and always will be. A downstream child-bearing *primitive* would
need a `layoutNode` branch it has no way to add, so it cannot exist as a working type in the first
place. The requirement would therefore be source-breaking for every `View` in every consuming project
in exchange for covering a case that cannot occur.

**Quality attribute impact.** Strongly positive on Correctness (#1) in principle. Strongly negative on
Compatibility and Usability: every downstream view type breaks, and every leaf view author writes
`var childViews: [any View] { [] }` forever to satisfy a check that buys nothing at that call site.

### Alternative D — A `HasChildViews` marker protocol

`public protocol HasChildViews { var traversalChildren: [any View] { get } }`, conformed by every
child-bearing type. Traversal becomes one cast.

**Evaluation.** Rejected. Adding a type and **forgetting the conformance** is not a compile error — it
is silent under-traversal with a new and more plausible-looking way to commit it. It has the same
enforcement profile as the status quo while adding a protocol, and unlike Alternative C it does not
even cover downstream.

**Quality attribute impact.** Positive on Maintainability (smallest surface). Fails Correctness (#1)
at the one requirement the feature exists to satisfy.

### Alternative E — `@testable import GameUI` from `GameUITesting`

Keep traversal `internal` and reach it with `@testable`. `GameUI`'s public surface does not grow.

**Evaluation.** Rejected as non-functional, not merely undesirable. `@testable` requires
`-enable-testing`, which SwiftPM applies to test builds of the local package and **not** to a package
consumed as a release dependency. `GameUITesting` would compile here and fail at every downstream
consumer.

**Quality attribute impact.** Fails Portability outright. Positive on encapsulation, which is not a
ranked attribute here and is not worth a library that cannot be consumed.

### Alternative F — Put `collect` and the conveniences on `GameUI` directly

One target, one product, no `Package.swift` change; downstream needs no new dependency.

**Evaluation.** Rejected on surface hygiene. Six flattening helpers on the module every game developer
imports is a permanent discoverability tax for a benefit measured in one line of `Package.swift`.
Note that `childViews` **is** placed on `GameUI` under this same test and passes it (Decision 2): it
is the library describing its own structure, and a custom-renderer author needs it.

**Quality attribute impact.** Neutral on Safety and Correctness. Negative on Maintainability (#3) and
Usability — the public API stops describing one coherent audience.

### Alternative G — A SwiftSyntax-based registry checker instead of a regex

Parse `Sources/GameUI/` with `swift-syntax` and enumerate `View` conformances structurally, including
conformances declared in extensions, generic constraints and conditional conformances. Immune to the
formatting assumptions a regex makes.

**Evaluation.** Rejected for now on cost, with the cost stated rather than gestured at. `swift-syntax`
is a third-party SPM package, so it would require a **separate** package manifest under `Tools/`,
never a dependency of GameUI's own `Package.swift` (§ Technology Constraints: zero third-party
dependencies — a tool that is never linked into the shipped library does not violate that rule, but a
`Package.swift` entry would). It also requires a network fetch and a multi-minute `swift-syntax`
build on every CI run, on a job that currently completes in seconds on alpine with no Swift toolchain
at all.

The regex has **18/18 recall on the current corpus with zero false positives**, and the one
conformance it cannot see — `extension Never: View` (`Sources/GameUI/View.swift:9`) — is allowlisted
explicitly and documented as such. Revisit if a second extension-declared or conditional conformance
ever appears; that is the trigger, and it is a visible one.

**Quality attribute impact.** Positive on Correctness at the margin (conditional conformances).
Strongly negative on Performance Efficiency (CI wall-clock) and Maintainability (a second package
manifest and a toolchain requirement on a job that has none) for a gap that does not currently exist.

---

*Supersedes nothing. Related: ADR-003 (dispatch-order fragility as a maintenance liability — the
same class of concern, here accepted rather than eliminated, with CI as the compensating control),
ADR-005 (a protocol earns its place by serving a dispatch site — the test `HasChildViews` fails in
Alternative D).*
