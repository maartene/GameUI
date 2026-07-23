# Evolution: view-tree-traversal-test-support

**Date**: 2026-07-23
**Feature ID**: view-tree-traversal-test-support
**Status**: Delivered
**Wave path**: DESIGN → DISTILL → DELIVER (DISCUSS deliberately skipped — see Wave Right-Sizing)

---

## Feature Summary

GameUI now owns view-tree traversal instead of leaving each consumer to reimplement it.

- `GameUI.childViews(of:)` — a public generic function carrying the single dispatch chain, alongside a
  mandatory `// traversal:` registry comment naming every `View`-conforming type in the module.
- `GameUITesting` — a new second target and library product (a plain `.target`, never a `.testTarget`,
  so a downstream *test* target can import it) with `collect(_:from:)` and five domain-neutral
  conveniences: `collectTexts`, `collectButtons`, `collectTextColors`, `collectProgressBars`,
  `collectTextures`.
- Two new CI gates in the `constraints` job, plus a release-product build in `test-linux`.

**Business context**: two independent projects consuming GameUI had each hand-copied
`LayoutEngine.layoutNode`'s `as?` dispatch chain into a test helper so their tests could pull views out
of a tree and assert on them. Twice, a branch was missing from a copy and subtrees were **silently
skipped** — assertions passed against a tree that was never visited. `brief.md` § wrapped-text-max-lines
already recorded one instance before this feature existed.

---

## The Defining Insight: Distribution, Not Drift

The first design draft misdiagnosed the problem. It proposed a public `ViewKind` discriminated union
that `layoutNode`, `hitTestNode` and `collect` would all `switch` over exhaustively, and claimed this
made omission *unrepresentable*.

Both halves were wrong, and the correction reshaped the feature:

1. **The enum does not eliminate the failure — it relocates it.** `viewKind(of:)` is itself an `as?`
   chain. Add a view type, forget its case, and it lands in `.opaqueLeaf` silently. Three silent
   failure sites become one; none becomes zero.
2. **The field incidents were distribution failures, not drift failures.** GameUI *had* the branch;
   copies maintained by people who do not maintain GameUI's dispatch chain had fallen behind it.
   Shipping one working `collect(_:from:)` kills both outright, because downstream stops having a
   chain at all. In-repo drift is a different problem that the incidents do not demonstrate.

What survives from the enum analysis, and why it still matters: `layoutNode` needs branch *identity
plus payload* — `paddingX`, `frameWidth`, spacing, axis — not an undifferentiated children list. So any
future unification must be a discriminated union rather than a shared `childViews`. That is the reason
`childViews` is deliberately a **second** in-repo chain rather than one offered to `layoutNode`.
Preserved as ADR-006 Alternative B and ODQ-VT-06.

**Moving the chain from the consumer site to the library site is most of the value, because it
relocates the mistake to where the knowledge is.**

---

## Enforcement Is Honest About Its Limits

Swift cannot enforce "every new view type declares its children" without a `View` protocol requirement,
which was considered and rejected (ADR-006 Alternative C): its only advantage over CI is covering
downstream types, and downstream can realistically add only *composite* views, already handled free by
the `V.Body.self != Never.self` fallback. A downstream child-bearing *primitive* would need a
`layoutNode` branch it cannot add.

So enforcement is two mechanisms, each covering what the other cannot:

| Mechanism | Proves | Cannot prove |
|---|---|---|
| CI registry grep (`constraints` job) | every `View` type was **considered** | that its accessor is **correct** |
| `ViewTraversalCoverageTests` sentinel tests | each type's children are **actually reached** | that a *new* type was registered at all |

`// traversal: Grid leaf` written on a child-bearing type passes the grep and reproduces the original
bug. That limit is stated in ADR-006, in `brief.md`, and in the feature-delta rather than papered over —
and it is why the sentinel test is not optional garnish.

---

## Key Decisions

| ID | Decision |
|---|---|
| DDD-1/2 | `GameUITesting` as a separate target; `childViews` public on `GameUI` for knowledge locality — the developer adding a type meets the registry in the folder they are already editing |
| DDD-4 | Completeness enforced by CI registry grep, **not** the type system |
| DDD-7 | Free function, not `extension View` — a member on a universal protocol can be silently shadowed by a conforming type |
| DDD-9 | A `ChildrenProviding` branch `layoutNode` lacks, so multi-statement `@ViewBuilder` bodies are traversable for the first time |
| DDD-11 | `layoutNode` and `hitTestNode` **not modified** — zero existing source files changed |
| DDD-12/13/14/15 | `ViewKind`, the `View` protocol requirement, `@testable`, and a SwiftSyntax checker all rejected or deferred, each with its argument recorded |

ADR: `docs/product/architecture/adr-006-library-owned-view-traversal.md`.

---

## Latent Defects Found and Deliberately Not Fixed

Forcing three dispatch chains side by side surfaced two real bugs in shipped code. Both were recorded
rather than absorbed, because each changes observable behaviour and needs its own acceptance criteria:

- **ODQ-VT-02** — `hitTestButton` cannot reach a button nested inside a composite view. `hitTestNode`
  is `any View`-typed and therefore has no composite branch *at all*. Fixing it renumbers button
  indices for any tree containing a composite. It is now the only in-repo dispatch chain no gate
  covers, which also makes it the strongest trigger for ODQ-VT-06.
- **ODQ-VT-03** — a bare `TupleViewN` matches no `layoutNode` branch, so a composite whose `body` is a
  multi-statement `@ViewBuilder` block lays out as an empty fill-constraints box. Traversal was fixed
  here; layout was not, because fixing it means deciding a stacking axis and spacing for an unadorned
  tuple — a design question, not a refactor.

---

## The Bug Class Kept Reappearing Inside Its Own Fix

Three times, the exact failure mode this feature exists to eliminate — *a check that returns the
reassuring answer without doing the work* — turned up inside the work:

1. **Five vacuously-green tests at DISTILL.** `collect(...).isEmpty` and `first == second` are both
   satisfied by a traversal that returns nothing for everything: green before AND after
   implementation. The author caught them and added positive controls, then made it a standing rule
   for the suite.
2. **A CI gate that could never fire.** The no-dispatch-cast grep lived in a markdown table cell,
   where a raw `|` splits the cell — so it had been escaped to `\|`, which `grep -E` reads as a
   literal pipe rather than alternation. Copied into CI as written it would have passed forever while
   checking nothing. Verified empirically, then moved into its own fenced block with a warning.
3. **An unguarded order contract.** `collectTexts` promises declaration order across `Text` and
   `WrappedText`. Both existing fixtures place the `Text` first, so they pass identically against
   `collect(Text.self, …) + collect(WrappedText.self, …)`, which concatenates by *type*. The shipped
   implementation was correct, but a later "simplification" would have kept all 218 tests green while
   silently reordering every caller's results. A regression guard was added and **proven to
   discriminate**: substituting the two-walk body makes it the only failing test of 219.

The lesson worth carrying: for any negative or emptiness assertion — in tests or in CI — the question
is not "does it pass?" but "have I watched it fail?"

---

## Wave Right-Sizing

DISCOVER, DIVERGE and DISCUSS were skipped deliberately. The job was validated by field evidence (two
projects, two incidents, one already recorded in the SSOT); there was no persona to discover and no
user journey to map. Running them would have produced documents restating the problem statement.

The full six-wave sequence stays reserved for features introducing a genuinely new mechanism. The
counter-example is `progress-bar`, which ran every wave for what became a four-line change.

---

## Verification

| Gate | Result |
|---|---|
| Test suite | 219/219, 32 suites |
| Pre-existing tests | 175/175, zero files modified |
| DES integrity | 3 steps, complete RED→GREEN→COMMIT traces, exit 0 |
| Phase 4 adversarial review | approved — 0 blockers, 0 high, 0 low, 0 refactoring opportunities |
| Traversal registry gate | 19 of 19 types; verified firing on an unregistered type |
| No-dispatch gate | clean; verified firing on a planted cast |
| Purity | no Foundation/Darwin/Glibc, no CGFloat, no Double |
| Scaffold markers | 0 remaining of 8 |
| Mutation testing | skipped — Muter unavailable (`CLAUDE.md` § Mutation Testing Strategy) |

Commits: `8828ad1`, `6601cc3`, `4ce3f59`, `f8f64d7`, `1cdc9a0`.

---

## Downstream Migration

No lockstep release required. GameUI can ship `GameUITesting` before either consumer migrates — the
existing hand-copies keep compiling, because every accessor they use was already public and none
changed. Migration is deletion: a consumer removes its local `children(of:)` and `collect(_:from:)`,
adds `GameUITesting` to its test target's dependencies, and keeps its call sites verbatim, since
`collect(_:from:)` was named to match what those projects already wrote. Domain-specific helpers
(SpaceSim's `collectPlayerStatus`) stay where they are.
