# Feature Delta — view-tree-traversal-test-support

> Single narrative file. All wave findings land here as `## Wave: <WAVE> / [REF|WHY|HOW] <Section>` headings.
> Density: `lean` + `ask-intelligent` (per `~/.nwave/global-config.json`).
> DESIGN is the entry wave for this feature — no DISCUSS artifacts precede it.

---

## Wave: DESIGN / [REF] Decisions

Scope: **Application / components** (@nw-solution-architect). Mode: **propose**.
Paradigm: **OOP / protocol-oriented value types**, inherited from `CLAUDE.md` § Development
Paradigm — unchanged, no write-back needed.

**Driver.** Two downstream projects have each hand-copied `LayoutEngine.layoutNode`'s dispatch chain
into a test helper. Twice, a branch was missing from a copy and subtrees were silently skipped —
assertions passed against a tree that was never visited. `brief.md` § wrapped-text-max-lines already
records one instance ("`RecordingGameUIAdapter` requires a `HasFrameSize` traversal fix").

**Framing that sets the scope.** Both incidents were **distribution** failures, not drift failures:
GameUI already had the branch, and a copy maintained by people who do not maintain GameUI's dispatch
chain had fallen behind it. Shipping one working `collect(_:from:)` kills both outright, because
downstream stops having a chain at all. Moving the chain from the consumer site to the library site
is most of the value, because it relocates the mistake to where the knowledge is. In-repo drift
between `layoutNode` / `hitTestNode` / `childViews` is a *different* problem, not the one the
incidents demonstrate, and is handled separately (DDD-11, DDD-12).

| ID | Decision | Verdict | Rationale |
|---|---|---|---|
| DDD-1 | Distribution vehicle | New `.target` **`GameUITesting`** + second `.library` product | A plain target (not `.testTarget`) is the only shape a downstream *test* target can `import`. |
| DDD-2 | Helper placement | `collect` + conveniences in `GameUITesting`; `childViews(of:)` public on **`GameUI`** | `collectTextColors` is test-shaped noise on a game developer's API. `childViews` is the library describing its own structure — and it must sit in the same directory as the types it dispatches on, so the developer adding a type meets the registry in the folder they are already editing. |
| DDD-3 | Traversal shape | `public func childViews<V: View>(of view: V) -> [any View]` in `Sources/GameUI/ViewTraversal.swift` | Branch order mirrors `layoutNode`, plus a `ChildrenProviding` branch it does not have (DDD-9), plus the `V.Body.self != Never.self` composite fallback. |
| DDD-4 | Enforcement | **CI traversal registry grep** in the existing `constraints` job — not the type system | Every `View`-conforming type in `Sources/GameUI/` must carry exactly one `// traversal:` line in `ViewTraversal.swift`. Seconds, on alpine, no Swift toolchain. Exact step in `brief.md` § Architectural Enforcement. |
| DDD-5 | Registry annotation grammar | `// traversal: <Type> children <Accessor>` or `// traversal: <Type> leaf` — **mandatory for every type** | Child-bearing type names never appear literally in `childViews` (branches cast to protocols), so a name-grep cannot work. The `children`/`leaf` discriminator makes "I forgot" and "genuinely childless" different lines in the diff. |
| DDD-6 | Enforcement limit | Grep + coverage test, **both required** | The grep proves a type was *considered*, not that its accessor is *correct*. `// traversal: Grid leaf` on a child-bearing type passes the grep and reproduces the bug. The sentinel-child coverage test covers the second half. Stated as a limit, not papered over. |
| DDD-7 | Spelling | Free function `childViews(of:)`, not `extension View { var childViews }` | A member on a universal protocol can be silently shadowed by a conforming type. Disqualifying for a mechanism whose purpose is eliminating silent mis-dispatch. Precedent: `hitTestButton`. |
| DDD-8 | Genericity | `childViews<V: View>(of:)`, `collect<T>(_:from: some View)` | `Body` is an associated type; `view.body` is unreachable inside an `any View`-typed function. Call sites *may* hold `any View` — Swift opens the existential implicitly at a generic parameter. |
| DDD-9 | `ChildrenProviding` branch | **Added to `childViews`**, absent from `layoutNode` | `ChildrenProviding` is consumed only at `Containers.swift:22,43,67` — only when a container unwraps its own content. A bare `TupleViewN` reaching `layoutNode` matches no branch, so multi-statement `@ViewBuilder` bodies are invisible to every traversal. `collect` sees them; the layout half stays broken → ODQ-VT-03. |
| DDD-10 | Naming | `collect(_:from:)` | Already the downstream name — migration is deletion, not rewriting. ADR-006 Decision 5. |
| DDD-11 | `layoutNode` and `hitTestNode` | **NOT MODIFIED** | The only argument for touching them was unifying the in-repo chains behind `ViewKind`, which is deferred (DDD-12). Restores the strongest regression guarantee: **zero existing source files modified**. Three `as?` chains remain in-repo; the cost is accepted and named. |
| DDD-12 | `ViewKind` discriminated union | **DEFERRED** to ODQ-VT-06, preserved as ADR-006 Alternative B | It does not make omission unrepresentable — `viewKind(of:)` is itself an `as?` chain, and a forgotten case lands in `.opaqueLeaf` silently. It moves the single silent failure point from three sites to one. Its real merit (collapsing three chains) is a refactor to judge on its own merits, now that the registry check makes drift loud either way. |
| DDD-13 | `childViews` requirement on `View` | **REJECTED** | The only design with true compile-time enforcement, but its sole advantage over CI is covering downstream types — and downstream can realistically only add *composite* views, already handled free by the `body` branch. A downstream child-bearing *primitive* would need a `layoutNode` branch it cannot add. Source-breaking for every consuming project in exchange for a case that cannot occur. ADR-006 Alternative C. |
| DDD-14 | `@testable import GameUI` | **REJECTED** | `@testable` needs `-enable-testing`, which SwiftPM does not apply to a package consumed as a release dependency. Would compile here, fail at every consumer. ADR-006 Alternative E. |
| DDD-15 | SwiftSyntax registry checker | **REJECTED for now** | Separate SPM manifest under `Tools/` (never in GameUI's `Package.swift`), network fetch, multi-minute build on a job that currently runs in seconds with no Swift toolchain. One regex has 18/18 recall, zero false positives. Trigger to revisit: a second extension-declared or conditional conformance. ADR-006 Alternative G. |

---

## Wave: DESIGN / [REF] Component Decomposition

| Component | Path | Change type |
|---|---|---|
| `childViews(of:)` + traversal registry comment block | `Sources/GameUI/ViewTraversal.swift` | **CREATE NEW** (new file) |
| `collect(_:from:)` | `Sources/GameUITesting/Collect.swift` | **CREATE NEW** (new target) |
| `collectTexts` / `collectButtons` / `collectTextColors` / `collectProgressBars` / `collectTextures` | `Sources/GameUITesting/Conveniences.swift` | **CREATE NEW** |
| `GameUITesting` target + library product | `Package.swift` | **MODIFY** — one target, one product, one test-target dependency |
| "Traversal registry covers every View type" step | `.forgejo/workflows/ci.yml`, `constraints` job | **CREATE NEW** (one step; job otherwise unchanged) |
| `LayoutEngine.layoutNode` | `Sources/GameUI/LayoutEngine.swift` | **NO CHANGE** (DDD-11) |
| `hitTestNode` / `hitTestButton` | `Sources/GameUI/HitTest.swift` | **NO CHANGE** (DDD-11) |
| `View`, `Containers`, `LeafViews`, `ViewBuilder`, `WrappedText`, `ProgressBar`, `LayoutTypes`, `Color` | `Sources/GameUI/` | **NO CHANGE** — every accessor traversal needs is already `public` |
| `ViewTraversalCoverageTests` + `collect` acceptance tests | `Tests/GameUITests/acceptance/` | **CREATE NEW** |
| Existing 175 tests | `Tests/GameUITests/` | **NO CHANGE** — zero modifications permitted |

Production change surface: **one new file in `GameUI`, one new target with two files, one
`Package.swift` edit, one CI step. Zero existing source files modified** — the same structural
regression guarantee `progress-bar` achieved.

---

## Wave: DESIGN / [REF] Driving Ports

GameUI is a library; the driving port **is** the public API surface of each module
(per `CLAUDE.md` § nWave Standing Exemptions, Phase 3.5 adaptation). No CLI, no HTTP, no skill.

| Port | Module | Signature | New |
|---|---|---|---|
| Traversal children | `GameUI` | `childViews<V: View>(of view: V) -> [any View]` | Yes |
| Type-directed collection | `GameUITesting` | `collect<T>(_ type: T.Type, from view: some View) -> [T]` | Yes |
| Text extraction | `GameUITesting` | `collectTexts(from view: some View) -> [String]` — `Text.content` **and** `WrappedText.content` | Yes |
| Button extraction | `GameUITesting` | `collectButtons(from view: some View) -> [any AnyButton]` | Yes |
| Text colour extraction | `GameUITesting` | `collectTextColors(from view: some View) -> [Color]` — `Text` only | Yes |
| Progress-bar extraction | `GameUITesting` | `collectProgressBars(from view: some View) -> [ProgressBar]` | Yes |
| Texture extraction | `GameUITesting` | `collectTextures(from view: some View) -> [Texture]` | Yes |
| Layout | `GameUI` | `LayoutEngine.layout(_:in:) -> LayoutTree` | No — unchanged, not touched |
| Hit test | `GameUI` | `hitTestButton(view:node:at:) -> Int?` | No — unchanged, not touched |

`collectTextColors` covers `Text` only while `collectTexts` covers `Text` **and** `WrappedText`. The
asymmetry is inherited verbatim from the field helper and is retained deliberately: `WrappedText`
carries one `color` for all its lines, so a merged list would not be zip-able against
`collectTexts`. Documented, not silently smoothed over.

## Wave: DESIGN / [REF] Driven Ports + Adapters

**None.** Consistent with every prior GameUI feature: the library performs no I/O, holds no reference
type, opens no file, and calls nothing outbound. `childViews` and `collect` are pure functions of an
immutable value tree. There is no adapter to probe, no substrate that can lie, and no `probe()` to
specify — the Earned Trust obligation is satisfied vacuously because the dependency set is empty.

`GameUITesting` depends on `GameUI` only — a library dependency resolved by the compiler, not a
runtime port.

Contract shapes (per the effect-isolation mandate): `childViews` and `collect` are both
**pure-function (return-only)**. Their declared mutation set is empty; they are total over the input
domain except for two partialities inherited from `layoutNode` and not introduced here — a
user-defined `body` that traps (`fatalError`), and a `body` returning a view containing itself, which
recurses without bound (ODQ-VT-04).

---

## Wave: DESIGN / [REF] Technology Choices

| Choice | Version / Detail | Rationale |
|---|---|---|
| Swift | 6.2, `swiftLanguageModes: [.v6]` | Applies to `GameUITesting` identically — it is a shipped target, not a test target. |
| `.target` + `.library` for `GameUITesting` | SwiftPM, `dependencies: ["GameUI"]` | `.testTarget` products are not importable downstream. |
| No Foundation | — | `childViews` uses `as?` and array literals; `collect` uses generics and `+=`. |
| `Float` geometry | Not used at all in the new code | Nothing in traversal is numeric. The CI `CGFloat`/`Double` gate passes trivially. |
| No third-party dependencies | — | Zero added. SwiftSyntax rejected (DDD-15). |
| Enforcement tooling | `grep` / `sed` / `sort` / `comm` on alpine | Matches the `constraints` job's established style — no toolchain, seconds of wall-clock. |
| Swift Testing | Existing | Backtick-quoted test names per `CLAUDE.md`. |

**CI impact.** `Sources/GameUITesting/` falls inside the `constraints` job's `Sources/` sweep
automatically, so the three existing purity greps need **no workflow change** and the new code
triggers none of them. `swift build --build-tests` already builds `GameUITesting` because
`GameUITests` depends on it, and `swift test` is unaffected. Two steps are nonetheless added or
recommended, both specified in `brief.md` § Architectural Enforcement: the **traversal registry
check** (required — it is DDD-4, the feature's enforcement mechanism) and
`swift build -c release --product GameUITesting` in `test-linux` (recommended — the only gate that
catches a regression to `.testTarget` or a reintroduced `@testable import`, both of which compile
fine under `--build-tests` and break every downstream consumer).

---

## Wave: DESIGN / [REF] Reuse Analysis

| Existing Component | File | Overlap | Decision | Justification |
|---|---|---|---|---|
| `RecordingGameUIAdapter.children(of:)` | SpaceSim (downstream) | The hand-copied chain | **REPLACE** | Deleted downstream in favour of `import GameUITesting`. This is the feature's reason to exist and the fix for both field incidents. Not in this repo's change surface. |
| `LayoutEngine.layoutNode` `as?` chain | `LayoutEngine.swift:35-68` | The chain being copied | **REUSE AS REFERENCE — do not modify** | `childViews` mirrors its branch order but is a separate function. `layoutNode` cannot consume a children list: every branch recurses with branch-specific constraints, origin and node assembly, and `Text`/`WrappedText` do not recurse over views at all (ADR-006 Alternative B). Contract shape: pure-function. Assertion mechanism: none needed — the file is untouched, so the existing 175-test suite is the guarantee by construction. |
| `hitTestNode` `as?` chain | `HitTest.swift:18-59` | Second in-repo copy | **REUSE AS REFERENCE — do not modify** | Consumes payload, not children — index capture, frame guard, `zip` against `node.children` all differ per case. Migrating it was deferred with `ViewKind` (DDD-12). Named as the weakest link in ADR-006 Decision 4. Its composite-branch gap is a separate defect → ODQ-VT-02. |
| `ContainerView.containerChildren` | `Containers.swift` | Children accessor | **REUSE AS-IS** | Already `public`. No access widening anywhere in this feature. |
| `ZStackView.zStackChildren` | `Containers.swift` | Children accessor | **REUSE AS-IS** | Already `public`. |
| `AnyButton.anyContent` | `LeafViews.swift` | Child accessor | **REUSE AS-IS** | Already `public`. |
| `HasFrameSize.framedContent` | `View.swift` | Child accessor | **REUSE AS-IS** | Already `public`. |
| `AnyDirectionalPaddingModifier.paddingContent` | `View.swift` | Child accessor | **REUSE AS-IS** | Already `public`. The deprecated `AnyPaddingModifier` gets **no** branch — a second padding branch would resurrect the dispatch-order fragility ADR-003 closed. |
| `ChildrenProviding.viewChildren` | `ViewBuilder.swift` | `TupleViewN` children | **REUSE AS-IS, newly reached** | Already `public` but consumed only at `Containers.swift:22,43,67`. `childViews` adds the top-level branch `layoutNode` lacks. Layout gap unchanged → ODQ-VT-03. |
| `Text` / `WrappedText` | `LeafViews.swift`, `WrappedText.swift` | Leaves with *synthetic* layout children | **REUSE AS-IS** | `childViews` returns `[]` for both: their `LayoutNode` children are generated geometry, not views, and are not collectable. Registry: `leaf`. |
| `Spacer`, `Rectangle`, `Texture`, `Slider`, `Checkbox`, `ProgressBar` | `Sources/GameUI/` | Views matching no branch | **REUSE AS-IS** | All fall through to `[]`. Registry: `leaf`. ADR-005's constraint that `ProgressBar` conform to no dispatch protocol becomes checkable as one registry line plus one assertion. |
| `Never` (`extension Never: View`) | `View.swift:9` | The one extension-declared conformance | **REUSE AS-IS, allowlisted** | Invisible to the registry regex by construction. Explicitly allowlisted in the CI step and documented there. Registry: `leaf`. |
| `hitTestButton` free-function shape | `HitTest.swift:12` | Public entry point that is not a type member | **REUSE AS PATTERN** | Precedent for `childViews(of:)` being a free function rather than a `View` extension. No shared code. |
| `constraints` CI job | `.forgejo/workflows/ci.yml` | Existing alpine grep gate | **EXTEND** | One new step in the established style. No new runner, no toolchain, no container change. |
| `Package.swift` single-target layout | `Package.swift` | Build graph | **EXTEND** | One target, one product, one dependency edge. |

Zero unjustified CREATE NEW decisions. The one contestable row — creating `childViews` as a *second*
in-repo chain rather than unifying — is escalated to ADR-006 Alternative B with the counter-argument
stated and answered.

---

## Wave: DESIGN / [REF] Open Questions

| ID | Question | Deferred to | Note |
|---|---|---|---|
| ODQ-VT-02 | `hitTestButton` cannot reach a button nested inside a composite view — `hitTestNode` is `any View`-typed and has **no composite branch at all**. | **Own feature** | A genuine latent defect in shipped code, discovered during this design and *not* fixed here: recursing changes observable behaviour and renumbers button indices for any tree containing a composite. Needs its own AC. **Must not be dropped.** |
| ODQ-VT-03 | A composite whose `body` is a multi-statement `@ViewBuilder` block lays out as an empty fill-constraints box, because a bare `TupleViewN` matches no `layoutNode` branch. | **Own feature** | Traversal is fixed here (DDD-9); **layout is not**. Fixing layout means deciding a stacking axis and spacing for an unadorned tuple — a design question, not a refactor. |
| ODQ-VT-04 | Should `collect` guard against a cyclic `body` (a view whose `body` returns itself)? | DISTILL / crafter | Unbounded recursion is inherited from `layoutNode`, which has the same exposure today. A depth cap on `collect` alone would make the two disagree. Recommendation: no guard, documented precondition — matching `hitTestButton`'s existing isomorphism precondition. |
| ODQ-VT-05 | Migration ordering for the two downstream repos. | Coordination, not architecture | GameUI can ship `GameUITesting` before either consumer migrates; the old hand-copies keep compiling against unchanged public accessors. No lockstep release needed. |
| ODQ-VT-06 | Should the three in-repo `as?` chains (`layoutNode`, `hitTestNode`, `childViews`) be unified behind a `ViewKind` discriminated union? | **Future refactor** | Preserved in full as ADR-006 Alternative B. Deferred, not rejected: it does not make omission unrepresentable (`viewKind(of:)` is itself an `as?` chain), so it is not the enforcement mechanism — but it is a real maintainability win, to be judged on its own merits. Its strongest trigger is `hitTestNode`, the chain no check currently covers. A natural companion is widening the registry annotation to record each type's *layout* disposition as well as its traversal one. |
| ODQ-VT-07 | Should the registry check also scan `Sources/GameUITesting/` for `View` declarations? | DELIVER | Currently it scans `Sources/GameUI/` for declarations and `ViewTraversal.swift` for annotations. If `GameUITesting` ever declared a `View` type it would be unregistered and unchecked. It should not — the separate constraint "`Sources/GameUITesting/` contains no cast to a child-bearing protocol" covers the realistic failure. Cheap to widen if it becomes relevant. |

---

## Wave: DESIGN / [REF] Wave Decisions Summary

**Architecture summary.** Pattern: move the traversal chain from the consumer site to the library
site, and enforce its completeness with a CI registry rather than the type system. One new public
function on `GameUI` (`childViews(of:)`), one new sibling target (`GameUITesting`) carrying `collect`
and five conveniences, one new CI step. Paradigm unchanged (OOP / protocol-oriented value types).
**Zero existing source files modified.**

**Constraints established.** Every `View`-conforming type in `Sources/GameUI/` must carry exactly one
`// traversal:` line in `ViewTraversal.swift`, with `children <Accessor>` or `leaf` as the
discriminator. `Sources/GameUITesting/` must contain no `as?` cast to a child-bearing protocol.
`GameUITesting` must remain a `.target` with a `.library` product and must never use
`@testable import GameUI`. `childViews` must be generic over `V: View` — any function that must reach
`.body` has to be generic. `childViews`' branch order mirrors `layoutNode`'s.

**Upstream changes.** None — DESIGN is the entry wave for this feature.

**Amendment recorded.** An earlier draft of this design made a public `ViewKind` discriminated union
the primary decision, migrating `layoutNode` and `hitTestNode` to `switch` over it, and claimed that
made omission *unrepresentable*. That claim was wrong: `viewKind(of:)` is itself an `as?` chain, so a
forgotten case lands in `.opaqueLeaf` silently — the enum moves the single silent failure point from
three sites to one rather than removing it. The draft also mis-scoped the driver: both field
incidents were **distribution** failures that shipping `collect` from the library fixes outright,
while the enum addresses in-repo drift, which the incidents do not demonstrate. Both corrections are
adopted. The enum analysis is preserved in full as ADR-006 Alternative B and ODQ-VT-06, because its
central technical finding — that `layoutNode` needs branch *identity plus payload*, so any future
unification must be a discriminated union rather than a children list — remains correct, and is the
reason `childViews` is deliberately a second chain rather than a shared one.

**Handoff.** → `nw-acceptance-designer` (DISTILL). Package: this feature-delta, ADR-006, and
`docs/product/architecture/brief.md` § view-tree-traversal-test-support Feature. Two guard artifacts
are DISTILL's to author and are named in `brief.md` § Architectural Enforcement: the
**`ViewTraversalCoverageTests`** sentinel-child test (every child-bearing type's children actually
reached — the half the grep cannot cover) and the **`collect` acceptance set** (concrete type,
existential type, composite body, nested modifiers, multi-statement `@ViewBuilder` body). No external
integrations exist, so no contract tests are recommended.

---

## Wave: DISTILL / [REF] Inherited commitments

| Origin | Commitment | DDR | Impact |
|--------|------------|-----|--------|
| DESIGN#DDD-3 | `childViews<V: View>(of:) -> [any View]` in `Sources/GameUI/ViewTraversal.swift`, branch order mirroring `layoutNode` | n/a | Scaffolded with the exact signature; 25 coverage tests assert the branch behaviour per registered type |
| DESIGN#DDD-5 | Registry grammar `// traversal: <Type> children <Accessor>` \| `<Type> leaf`, mandatory for every type | n/a | Registry authored for all 18 declared types plus the allowlisted `Never`; verified against the verbatim CI step — 19 declared, 19 registered, 0 missing, 0 stale |
| DESIGN#DDD-6 | Grep and coverage test are BOTH required; neither alone suffices | n/a | `ViewTraversalSlice2CoverageTests` is the compensating control for a dishonest `leaf` annotation; every child-bearing type is constructed around a sentinel and the sentinel asserted reached |
| DESIGN#DDD-9 | `ChildrenProviding` branch added, absent from `layoutNode` | n/a | Newly reachable behaviour, so it gets a dedicated fixture (`AbilityRow`) and three assertions; the layout half stays broken by design (ODQ-VT-03) and is NOT asserted here |
| DESIGN#DDD-11 | `layoutNode` and `hitTestNode` NOT MODIFIED — zero existing source files changed | n/a | Held. Only `Package.swift` is modified, which DESIGN itself requires. The 175 pre-existing tests are green and byte-for-byte untouched |
| DESIGN#DDD-1 | `GameUITesting` is a plain `.target` with a `.library` product, never a `.testTarget` | n/a | `Package.swift` edited accordingly; the new tests consume it via plain `import GameUITesting`, the downstream-realistic path, not `@testable` |
| DESIGN#Driving Ports | `collectTexts` covers `Text` **and** `WrappedText`; `collectTextColors` covers `Text` only | n/a | Asymmetry pinned by two adjacent tests so a future "tidy-up" has to argue with a red test rather than silently merge the lists |
| DESIGN#ODQ-VT-04 | Cyclic-body guard: decide | n/a | **CONFIRMED — no guard, documented precondition.** Now executable rather than prose: an exit test asserts the process terminates. See below |

## Wave: DISTILL / [REF] Scenario list with tags

Two slices, 43 tests. No Gherkin `.feature` files and no step definitions: per `CLAUDE.md`
§ nWave Standing Exemptions the `swift-testing` suites **are** the scenario SSOT, one file
per slice. Tags below are conceptual — expressed as file/suite placement and comment
headers, since `swift-testing` has no tag syntax in use in this project.

### Slice 1 — `ViewTraversalSlice1CollectTests` (18 tests)

| # | Scenario | Tags |
|---|---|---|
| 1 | a declared HUD screen reports the shield charge a downstream test asserts on | `@walking_skeleton` `@driving_port` |
| 2 | collect finds a progress bar nested inside a composite body | `@driving_port` `@field-incident` |
| 3 | collect finds a progress bar declared at the root of the tree | `@driving_port` |
| 4 | collect reaches a progress bar through frame padding and button layers | `@driving_port` `@field-incident` |
| 5 | collect reaches every view of a multi-statement builder body | `@driving_port` `@ddd-9` |
| 6 | collect visits the tree depth first in declaration order | `@driving_port` |
| 7 | collect keeps visiting later siblings after it finds a match | `@driving_port` `@error` |
| 8 | collect reaches a progress bar twelve modifier layers deep | `@driving_port` `@boundary` |
| 9 | collect finds every button through the existential button type | `@driving_port` |
| 10 | a concrete button specialisation matches fewer buttons than the existential | `@driving_port` `@boundary` |
| 11 | each convenience agrees with the collect call it wraps | `@driving_port` |
| 12 | collectTexts reports both Text and WrappedText content | `@driving_port` |
| 13 | collectTextColors reports colours for Text only and leaves WrappedText out | `@driving_port` `@deliberate-asymmetry` |
| 14 | collect returns nothing when the tree contains no view of that type | `@error` `@degenerate` |
| 15 | collect returns nothing for a bare leaf that is not the sought type | `@error` `@degenerate` |
| 16 | collect returns nothing from a container holding only views of another type | `@error` `@degenerate` |
| 17 | collect resolves a composite whose body is directly the sought view | `@boundary` |
| 18 | collect returns the same result when called repeatedly on the same tree | `@property` `@purity` |

### Slice 2 — `ViewTraversalSlice2CoverageTests` (25 tests) — the named guard artifact

| # | Scenario | Tags |
|---|---|---|
| 19–29 | VStack / HStack / ZStack / single-view stack / FrameModifier / PaddingModifier / DirectionalPaddingModifier / Button / TupleView2 / TupleView3 / TupleView4, each around a sentinel | `@registry-coverage` `@child-bearing` |
| 30 | a composite view reports its body and the sentinel inside is reached | `@registry-coverage` `@child-bearing` |
| 31 | every child-bearing view type reports at least one child | `@registry-coverage` `@aggregate` |
| 32–39 | Text / WrappedText / Rectangle / Texture / Spacer / Slider / Checkbox, each "is a leaf and is still reached when nested" | `@registry-coverage` `@leaf` `@boundary` |
| 40 | ProgressBar is a leaf conforming to no dispatch protocol and is still reached when nested | `@registry-coverage` `@leaf` `@adr-005` |
| 41 | every registered leaf type reports no children yet is reachable when nested | `@registry-coverage` `@aggregate` `@boundary` |
| 42 | no registered leaf type traps when asked for its children | `@error` `@never-body` |
| 43 | reading a primitive view's body traps | `@exit-test` `@control` |
| 44 | collecting from a view whose body contains itself terminates rather than hanging | `@exit-test` `@error` `@odq-vt-04` |

**Error / edge / boundary share: 20 of 43 = 47%** — above the 40% target. Counted:
scenarios 7, 8, 10, 14, 15, 16, 17, 32–39 (the leaf/child-bearing boundary, 8 of them),
41, 42, 44.

### Contract shapes

Every scenario is `@contract-shape:pure-function`. `childViews` and `collect` are pure
functions over an immutable value tree with an empty declared mutation set — DESIGN states
this explicitly under § Driven Ports + Adapters. There is no `bounded-change` or
`unbounded-preservation` scenario in this feature because there is nothing to change or
preserve.

## Wave: DISTILL / [REF] Walking-skeleton strategy

Strategy: **Phase-3.5-adapted API demo** (`CLAUDE.md` § Standing Exemptions). GameUI is a
library with no CLI, no HTTP surface and no subprocess. The driving port **is** the public
API, so the demo is an API call whose observable output is the returned array. No subprocess
is fabricated.

Scenario 1, `a declared HUD screen reports the shield charge a downstream test asserts on`,
is the skeleton. It is the whole feature in one call from the audience's point of view: a
downstream test author asks a declared screen what it contains and gets a real answer.
Every layer the feature ships is on its path — the composite branch of `childViews`, the
container branch, `collect`'s recursion, and a convenience wrapper — and it asserts on
concrete captured values (`label == "Shield charge"`, `value == 0.65`,
`collectTexts == ["SYSTEMS", "Shields"]`), not on shapes.

## Wave: DISTILL / [REF] Adapter coverage

**No driven adapters — vacuous.** GameUI performs no I/O, opens no file, holds no reference
type and calls nothing outbound; `GameUITesting` depends only on `GameUI`, a compile-time
edge rather than a runtime port. DESIGN records this under § Driven Ports + Adapters and the
project ATDD Infrastructure Policy records the same. There is no adapter to probe and no
substrate that can lie, so the Mandate-6 obligation is satisfied by having nothing to satisfy
it about. No table is fabricated.

The single fake in the whole project — the `stubMeasurer` closure for
`LayoutEngine.textMeasurer` — is **not used by this feature**. Traversal is structural, never
numeric, and no test here constructs a `LayoutEngine`.

## Wave: DISTILL / [REF] Driving-port coverage

Every driving port in DESIGN's table maps to at least one test.

| Driving port | Module | Covered by |
|---|---|---|
| `childViews<V: View>(of:)` | `GameUI` | Slice 2, scenarios 19–31 (child-bearing arity) and 32–42 (leaf emptiness). Exercised indirectly by all of Slice 1. |
| `collect<T>(_:from:)` | `GameUITesting` | Slice 1 scenarios 2, 3, 10, 15, 16, 17; Slice 2 `sentinelIDs(in:)` helper used by every coverage test |
| `collectTexts(from:)` | `GameUITesting` | Slice 1 scenarios 1, 5, 6, 12, 13, 14, 18 |
| `collectButtons(from:)` | `GameUITesting` | Slice 1 scenario 11 |
| `collectTextColors(from:)` | `GameUITesting` | Slice 1 scenario 13 |
| `collectProgressBars(from:)` | `GameUITesting` | Slice 1 scenarios 1, 5, 7, 11, 18 |
| `collectTextures(from:)` | `GameUITesting` | Slice 1 scenarios 5, 11, 14 |
| `LayoutEngine.layout(_:in:)` | `GameUI` | Not touched — DDD-11. Covered by the 175 pre-existing tests, unchanged. |
| `hitTestButton(view:node:at:)` | `GameUI` | Not touched — DDD-11. Covered by the 175 pre-existing tests, unchanged. |

Existential lookup (`collect((any AnyButton).self, from:)`) is covered by scenarios 9 and 10.
Concrete-vs-existential is deliberately split across two scenarios because they do not mean
the same thing and both spellings are supported.

## Wave: DISTILL / [REF] Scaffolds

RED-ready per Mandate 7. Every scaffold body returns an empty value — **none traps**. In
Swift `fatalError` / `preconditionFailure` / `assertionFailure` kill the whole test process,
which classifies as BROKEN rather than RED; returning `[]` makes each test fail as a clean
assertion naming the missing behaviour.

| File | Contents | `__SCAFFOLD__` markers |
|---|---|---|
| `Sources/GameUI/ViewTraversal.swift` | `childViews(of:)` returning `[]`, plus the full 19-line traversal registry (which is NOT scaffold — it is deliverable content DELIVER's CI step greps) | 2 |
| `Sources/GameUITesting/Collect.swift` | `collect(_:from:)` returning `[]` | 1 |
| `Sources/GameUITesting/Conveniences.swift` | five conveniences returning empty arrays | 5 |
| `Package.swift` | `GameUITesting` target + `.library` product + `GameUITests` dependency | — (not a scaffold; required for the tests to compile at all) |

**The `constraints` CI job will fail on this branch, intentionally.** It greps `Sources/` for
`__SCAFFOLD__`. DELIVER removes all eight markers as it implements; the job goes green when
the last one is gone.

## Wave: DISTILL / [REF] Test placement and precedent

`Tests/GameUITests/acceptance/ViewTraversalSlice{1,2}*.swift` — one file per slice, matching
the established `ProgressBarSlice1DeclareAndFillTests` / `ProgressBarSlice2ValueSafetyTests`
and `WrappedTextSlice{1,2,3}` naming. Suite names (`"View Traversal — collect"`,
`"View Traversal — registry coverage"`) follow the `"ProgressBar — Value Safety"` shape.
Test names are backtick-quoted function names per `CLAUDE.md` § Test Naming Convention.

One deliberate departure from precedent: these files use plain `import GameUI` where every
existing acceptance file uses `@testable import GameUI`. That is the point — this target must
consume `GameUITesting` through its public product exactly as a downstream test target does.
`@testable` would hide a missing `public` and pass here while failing at every consumer.

**No property-based testing library and no seeded sweep.** `ProgressBarSlice2ValueSafetyTests`
uses the in-repo SplitMix64 `Float(bitPattern:)` sweep because its contract is numeric over an
unbounded domain. This feature's contract is **structural** over a closed, enumerable domain:
19 view types, each with one registry line. The right instrument is exhaustive enumeration of
that domain — which is what Slice 2 is — not random sampling of it. A seeded sweep here would
be ceremony that tests nothing the enumeration does not already test exhaustively. Judgement
recorded rather than the pattern applied reflexively.

## Wave: DISTILL / [REF] Pre-requisites

- **DESIGN**: driving-port table, registry grammar (DDD-5), branch order (DDD-3), the
  `ChildrenProviding` addition (DDD-9), and the zero-files-modified constraint (DDD-11).
- **ADR-006**: Decision 3's explicitly stated limit is what makes Slice 2 mandatory rather
  than optional.
- **`brief.md` § Architectural Enforcement**: the verbatim registry CI step. Executed locally
  against the authored registry during this wave — 19 declared, 19 registered, 0 missing,
  0 stale. DELIVER adds the step to `.forgejo/workflows/ci.yml`.
- **`docs/architecture/atdd-infrastructure-policy.md`**: read and applied under
  `--policy=inherit`. Driving ports are direct in-process calls; zero driven adapters. **No
  new policy row is needed** — `childViews` and `collect` are the same port class as every
  existing entry (Swift public API, direct in-process call) and the policy's existing
  "Driving" table already covers the mechanism.
- **DEVOPS**: no DEVOPS wave for this feature. Both CI jobs (`swift:6.2` Linux container,
  native `macos-arm64`) run the new tests unchanged; Swift Testing exit tests are supported
  on both platforms, so no platform gating is needed.
- **DISCUSS**: no DISCUSS wave — DESIGN is the entry wave. Story-to-scenario traceability is
  correspondingly absent by construction, not by omission.

## Wave: DISTILL / [REF] Open Questions

| ID | Question | Verdict |
|---|---|---|
| ODQ-VT-04 | Should `collect` guard against a cyclic `body`? | **RESOLVED — confirmed DESIGN's recommendation: no guard, documented precondition.** Now executable, which DESIGN did not anticipate: `collecting from a view whose body contains itself terminates rather than hanging` is a Swift Testing exit test asserting the child process exits `.failure`. It pins the three-way distinction a caller actually cares about — the process terminates, rather than hanging forever or returning a plausible-but-wrong result a test would then assert against. Asserts `.failure`, never `.signal(SIGSEGV)`: a stack overflow surfaces as SIGSEGV or SIGBUS depending on platform and both CI jobs must agree. Precondition documented in the `ViewTraversal.swift` header alongside the trapping-`body` partiality, both marked as inherited from `layoutNode` rather than introduced here. |
| ODQ-VT-07 | Should the registry check also scan `Sources/GameUITesting/`? | Still DELIVER's. DISTILL adds one data point: the no-dispatch-cast grep over `Sources/GameUITesting/` was run locally and is clean, and the two files there declare no `View` type. The realistic failure is covered. |
| ODQ-VT-02, -03, -05, -06 | — | Untouched by DISTILL. Deliberately **not** asserted: ODQ-VT-03 in particular is tempting to "fix" while writing the `AbilityRow` fixture, and the fixture's comment says in as many words that the layout half stays broken. |
| **NEW — ODQ-VT-09** | Test-authoring note: implicit existential opening fails for a tuple element of an implicitly-typed closure parameter. | **RESOLVED — no design impact; recorded so DELIVER does not rediscover it.** `rows.filter { childViews(of: $0.view).isEmpty }`, where `rows` is `[(name: String, view: any View)]`, fails to compile with `type 'any View' cannot conform to 'View'` (`#ProtocolTypeNonConformance`). A **struct** property in the same position compiles, as does a bare `any View` element, as does the same member access outside a closure; annotating the closure's *parameter* type fixes it, annotating only its *result* type does not. Verified by isolated `swiftc -typecheck -swift-version 6` cases and against real GameUI. This is a type-checker limitation in one syntactic position and **not** a restriction on ADR-006 Decision 2's call-site contract, which holds as written — an earlier DISTILL draft over-generalised it to "opening works only for a named binding" and that claim was struck before it reached the ADR. The two aggregate guard tests in Slice 2 are the only code in the feature holding `any View` in a collection, and they use a `for` loop with a hoisted binding. |
| **NEW — ODQ-VT-08** | Should `GameUI` ship a type-eraser (`AnyView`)? | Surfaced while authoring Slice 2. `childViews` returns `[any View]`, but `any View` does not conform to `View`, so a value taken out of that array cannot be put back into a `VStack { }`. The aggregate leaf test has to build each nested fixture concretely as a result. Not a defect and not in scope — recorded so the next person hits the note rather than the wall. |

## Wave: DISTILL / [REF] Wave Decisions Summary

**43 acceptance tests across two slices, 42 RED for the right reason, 1 correctly-green
control.** The 175 pre-existing tests are green with zero test files and zero source files
modified — only `Package.swift`, which DESIGN requires. Full classification in
`distill/red-classification.md`.

Both guard artifacts named in `brief.md` § Architectural Enforcement are authored:
`ViewTraversalCoverageTests` (as `ViewTraversalSlice2CoverageTests`, 25 tests covering all
11 child-bearing shapes and all 8 leaf types plus two aggregate guards) and the `collect`
acceptance set (18 tests).

**Standing rule established for this suite: no negative assertion without a positive control
in the same test.** A first draft left five tests green vacuously — `collect(...).isEmpty`
and `first == second` are both satisfied by a traversal that returns nothing for everything.
That is not a cosmetic problem; it is precisely this feature's bug class, reproduced inside
the guard meant to eliminate it. All five were rewritten with a positive control and are now
RED.

**Handoff.** → `nw-software-crafter` (DELIVER). Implement in slice order; enable one test at
a time. Remove all eight `__SCAFFOLD__` markers, add the registry CI step verbatim from
`brief.md`, and add `swift build -c release --product GameUITesting` to `test-linux` — the
only gate that catches a regression to `.testTarget` or a reintroduced `@testable import`.

---

## Wave: DELIVER / [REF] Implementation Summary

Shipped in three DES-instrumented steps on branch `feat/view-tree-traversal-test-support`.
`childViews(of:)` became a public function on `GameUI` carrying the single dispatch chain;
`GameUITesting` shipped as a second `.target` + `.library` product with `collect(_:from:)` and five
conveniences; the traversal registry became an enforced CI gate rather than a comment block nobody
reads. Suite went 176/218 → **219/219**. No existing source file was modified — the same structural
regression guarantee `progress-bar` achieved.

## Wave: DELIVER / [REF] Files Modified

| File | Kind | Change |
|---|---|---|
| `Sources/GameUI/ViewTraversal.swift` | production | `childViews(of:)` dispatch chain + the `// traversal:` registry block (19 entries) |
| `Sources/GameUITesting/Collect.swift` | production | `collect(_:from:)` depth-first walk over `childViews` |
| `Sources/GameUITesting/Conveniences.swift` | production | five wrappers; `collectTexts` as a single depth-first pass |
| `Package.swift` | build | `GameUITesting` target + library product + test-target dependency (landed at DISTILL) |
| `.forgejo/workflows/ci.yml` | CI | +70 lines, nothing deleted: registry gate, no-dispatch gate, release-product build |
| `Tests/GameUITests/acceptance/ViewTraversalSlice1CollectTests.swift` | test | +1 regression guard (see Quality Gates) |
| `docs/product/architecture/brief.md`, `distill/red-classification.md` | docs | two enforcement-spec defects fixed |

Untouched, by design: `LayoutEngine.swift`, `HitTest.swift`, `View.swift`, `Containers.swift`,
`LeafViews.swift`, `ViewBuilder.swift`, and all 175 pre-existing tests.

## Wave: DELIVER / [REF] Scenarios Green

**219 of 219**, 32 suites, 2026-07-23. 175 pre-existing + 43 authored at DISTILL + 1 added at DELIVER.
Per-step: 01-01 took 176 → 209, 01-02 took 209 → 218, the DELIVER-added guard took 218 → 219.

## Wave: DELIVER / [REF] Demo Evidence

Phase 3.5 as adapted by `CLAUDE.md` § Standing Exemptions — this is a library with no CLI, so the
driving port IS the public API and the demo is an API call with a captured return value. The
walking-skeleton scenario `a declared HUD screen reports the shield charge a downstream test asserts
on` declares a HUD tree and asserts on the extracted value: `collectProgressBars(from: screen)` returns
one bar whose `label == "Shield charge"` and `value == 0.65`, reached through a composite `body`, a
container and a modifier chain. Real value, not a fabricated subprocess.

## Wave: DELIVER / [REF] Quality Gates

| Gate | Outcome |
|---|---|
| DES integrity (`des-verify-integrity`) | PASS — all 3 steps have complete RED→GREEN→COMMIT traces, exit 0 |
| Full suite | PASS — 219/219 |
| Pre-existing suite untouched | PASS — zero modifications to the 175 |
| Scaffold markers | PASS — all 8 removed; `grep -rc '__SCAFFOLD__' Sources/` = 0 |
| Purity (Foundation/Darwin/Glibc, CGFloat, Double) | PASS |
| No dispatch cast in `Sources/GameUITesting/` | PASS — verified firing: planted cast → exit 1 naming file:line, reverted clean |
| Traversal registry gate | PASS — `OK — traversal registry covers all 19 View-conforming types`; verified firing: unregistered type → named in MISSING, reverted clean |
| `swift build -c release --product GameUITesting` | PASS |
| Phase 4 adversarial review | `approved`, 0 blockers / 0 high / 0 low, 0 refactoring opportunities |
| L1–L6 refactor | Folded into Phase 4 on ~120 lines of pure functions; reviewer found nothing applicable |
| Mutation testing | SKIPPED per `CLAUDE.md` § Mutation Testing Strategy — Muter unavailable |

**One review finding was wrong and was corrected downstream.** Phase 4 recorded interleaved
`Text`/`WrappedText` as covered by the existing fixtures. It was not: both place the `Text` first, so
they pass identically against the vacuous two-walk spelling
`collect(Text.self, …) + collect(WrappedText.self, …)`, which concatenates by type rather than walking
in declaration order. The shipped implementation was already correct, but its contract was unguarded —
a later "simplification" would have kept every test green while silently reordering every caller's
results. A regression guard was added (`collectTexts preserves declaration order when a WrappedText
precedes a Text`) and proven to discriminate: substituting the two-walk body makes it the only failing
test of 219. This is the feature's own bug class caught inside the fix, which is exactly where it was
most likely to hide.

## Wave: DELIVER / [REF] Open Questions

| ID | Status |
|---|---|
| ODQ-VT-07 | **RESOLVED — NO.** The registry gate scans `Sources/GameUI/` only. Widening would make one module's comment block authoritative over another module's declarations — the knowledge-locality objection ADR-006 rejected Alternative A on, inverted. The realistic failure ("GameUITesting grows a traversal chain") is covered by name by the no-dispatch gate. Verdict and revisit trigger recorded as a comment above the registry step in `ci.yml`. Trigger: the first `: View` conformance anywhere under `Sources/GameUITesting/`. |
| ODQ-VT-02 | Still open — own feature. `hitTestButton` cannot reach a button nested inside a composite view; `hitTestNode` is `any View`-typed and has no composite branch. Live defect in shipped code. Now the only in-repo dispatch chain no gate covers. |
| ODQ-VT-03 | Still open — own feature. A bare `TupleViewN` matches no `layoutNode` branch, so a multi-statement `@ViewBuilder` body lays out as an empty box. Traversal was fixed here; layout was not. |
| ODQ-VT-06 | Deferred refactor — unifying the three in-repo `as?` chains behind a `ViewKind` discriminated union. Its strongest trigger is ODQ-VT-02. |
| ODQ-VT-08 | Recorded — no type-eraser (`AnyView`) in GameUI, so a value out of `[any View]` cannot go back into a `VStack { }`. |
| ODQ-VT-09 | Resolved at DISTILL — implicit existential opening fails only for a tuple element of an implicitly-typed closure parameter. ADR-006 Decision 2's contract holds as written. |
