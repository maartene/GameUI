# Evolution: progress-bar

**Date**: 2026-07-22
**Feature ID**: progress-bar
**Status**: Delivered
**Wave path**: DISCUSS → DESIGN → DISTILL → DELIVER

---

## Feature Summary

Added `ProgressBar` — a display-only horizontal bar leaf view. `ProgressBar(value:label:fillColor:trackColor:)` turns a `0.0…1.0` magnitude into a layout-participating view with a track and a proportional fill. Colours are chosen at the call site (`fillColor: Color = .green`, `trackColor: Color = .darkGray`). The renderer-facing accessor `clampedValue: Float` is guaranteed to lie in `0.0...1.0` for **every** `Float` input, including NaN and ±infinity; `value` remains readable verbatim as declared, so clamping is a rendering guarantee rather than data loss.

No `onTap`, no `AnyButton` conformance, no hit-test participation. Sizing comes from the caller's `.frame(...)`, or from the fill-constraints default when declared bare.

**Business context**: Riku Nakamura (game developer, SpaceSim HUD, custom raylib renderer) had no way to express "a bar filled 65% in green on a dark track". Every progress indicator was a bespoke pair of `Rectangle` views plus hand-written fill-width arithmetic, duplicated and divergent per screen, with no protection against a mid-frame `shieldCharge` of `1.4` painting past the track edge. JOB-06.

---

## The Defining Property: One New File, Zero Modified Files

The total production change surface is `Sources/GameUI/ProgressBar.swift` — a single new file, 41 lines. No existing source file was touched.

All layout and hit-test behaviour was obtained by reuse:

| Behaviour | Obtained from | Change |
|---|---|---|
| Bare `ProgressBar` fills the constraint box, childless node | `LayoutEngine.swift:68` fill-constraints default | none |
| Framed `ProgressBar` sized by `.frame(...)` | existing `HasFrameSize` branch, `LayoutEngine.swift:38-45` | none |
| `ProgressBar` never reported as hit | `HitTest.swift` terminal `return nil` — matches no branch | none |

`ProgressBar.body` is `Never`, so the composite-body branch is skipped and dispatch falls through to the default. AC-06 (never hit-tested) is satisfied structurally by the *absence* of code, and stays satisfied only as long as no protocol conformance is added. This is why ADR-005 records a hard constraint: `ProgressBar` must never conform to `AnyButton`, `ContainerView`, `ZStackView`, `HasFrameSize`, or `AnyDirectionalPaddingModifier`.

This property is the reason the feature was cheap, and it is the reason nine tests were already green before implementation started (see below).

---

## Key Decisions

### DISCUSS

| ID | Decision | Rationale |
|---|---|---|
| D5 | Display-only — no `onTap`, no `AnyButton`, no `HitTest.swift` change | "Slider without the drag handle" means no input affordance at all, not a disabled one. |
| D6 | Four properties: `value`, `label`, `fillColor`, `trackColor` | Colours declarative so a loading bar, health bar and mana bar differ at the call site, not by renderer branching on `label`. |
| D7 | Out-of-range values clamped inside `ProgressBar` | Safety is the project's #1 quality attribute. A single clamped accessor gives every renderer author the guarantee for free. Deliberately diverges from `Slider`. |
| D8 | No `LayoutEngine` branch | No children, no intrinsic content size — the existing fill-constraints default is already correct. |
| D9 | Indeterminate state out of scope | Would require an animation-time contract with the renderer, which no GameUI view currently has. |

### DESIGN

| ID | Decision | Rationale |
|---|---|---|
| DDD-3 | `clampedValue` computed, not clamped at init | Satisfies "`value` readable as declared" (AC-14) structurally rather than by discipline. No storage; one or two comparisons per bar per frame. |
| DDD-6 | CREATE NEW, not EXTEND `Slider` | ADR-005. `Slider` is not generalised, not unified, not touched. |
| DDD-8 | Renderer contract: two ordered draw calls | Track over `node.frame`, then fill over the left `clampedValue` fraction. Draw order is normative — reversing it hides the fill. Three lines of geometry (KPI-3 target ≤3). |

---

## ADR-005 Inverts the ADR-003 Precedent

Future readers will ask why `ProgressBar` is not simply a mode of `Slider`. The two types are structurally near-identical, and this repo has a recent precedent for unifying exactly such a pair: ADR-003 collapsed uniform and directional padding behind one protocol.

ADR-003's reasoning turns on a specific test — *in an immutable value-type system, is there any operation that distinguishes the two types post-construction?* For padding the answer was no, so unification was safe. Applying the identical test to `ProgressBar` and `Slider` yields the **opposite** verdict: invoking `onTap` distinguishes them. A `Slider` with `showsHandle: false` still carries a callback a renderer or input layer can fire; a `ProgressBar` categorically cannot be interacted with. That is an observable behavioural difference surviving construction — precisely the condition ADR-003 required to be absent.

The relationship is also inverted from the square/rectangle case. Uniform padding is a *narrowing* of directional padding. `ProgressBar` is not a narrowing of `Slider`; `Slider` is `ProgressBar` **plus an affordance**. Unifying would make the display-only type inherit an interaction surface documented as never used.

Option B (a shared `AnyFillableBar` protocol) was rejected as premature: every protocol in this codebase earns its place by serving a dispatch site, and `AnyFillableBar` would have zero — neither type appears in `layoutNode` or `hitTestNode`. Revisit only if a third bar-like type appears **and** a dispatch site materialises.

The accepted cost is two types that look alike. It is bounded: both are frozen value shapes of ~20 and ~40 lines with no behaviour to drift.

---

## The NaN Trap

`clampedValue` as shipped:

```swift
public var clampedValue: Float {
    if !(value > 0) { return 0 }  // negated comparison: NaN lands here
    if value > 1 { return 1 }
    return value
}
```

This form is **normative, not stylistic**, and it is the reason the clamp warranted an ADR rather than being left as an implementation detail. The obvious `min(1, max(0, value))` is wrong: Swift's `min`/`max` propagate NaN, so a NaN input returns NaN and the safety guarantee fails silently at exactly the input it exists for. The negated comparison is NaN-safe because every comparison against NaN is false, so NaN falls into the zero branch.

The trap is documented three times over — in ADR-005 Decision 2, in the roadmap step's implementation notes, and as an `- Important:` doc comment on the property itself — specifically so a future "simplification" toward `min`/`max` is caught at review.

Incidental, not specified: `-0.0 > 0` is false, so the first guard returns the literal `0`, normalising negative zero to positive zero. ADR-005 guarantees only the range.

---

## Nine of Twenty Tests Passed Before Implementation

DISTILL wrote all 20 acceptance tests against a Mandate-7 scaffold whose `clampedValue` returned `.nan`. (`.nan` was chosen over `fatalError` deliberately: a trap aborts the whole test process, whereas `.nan` fails every equality and range assertion cleanly. Swift is compiled, so the stored properties, initialiser and `body` had to be real or the suite would classify BROKEN rather than RED.)

RED gate result: **11 failing, all `MISSING_FUNCTIONALITY`**; zero `IMPORT_ERROR` / `FIXTURE_BROKEN` / `SETUP_FAILURE` / `WRONG_ASSERTION`. Zero regressions in the 155 pre-existing tests.

The other **9 passed at DISTILL time**, classified `ALREADY_SATISFIED_BY_REUSE` (AC-01, 02, 03, 04, 04b, 06, 06b, 07, 14). This is the direct consequence of the one-new-file property: once the type exists at all, layout and hit-test behaviour is already correct.

Two planning consequences, reached independently by `red-classification.md` and by the Sentinel roadmap reviewer, and again by the `nw-software-crafter-reviewer` during adversarial review — three arrivals at the same nine-test set:

1. **Slice 01's learning hypothesis was answered at the RED gate, and it held.** The brief said Slice 01 would *disprove* D8/DDD-4 ("a display-only bar needs no `LayoutEngine` branch") if the fill-constraints default turned out wrong for a bar. It was not wrong. The bet paid off at the cheapest possible moment, before a line of production code.
2. **The two planned slices collapsed into one DELIVER cycle.** Slice 01's only remaining RED tests (AC-05, AC-05b — fill width) both read `clampedValue`, which was Slice 02's work. DELIVER ran a single step; all 20 tests went green together.

The nine remain valuable as **characterization tests**, not tautology: they would fail loudly if anyone added one of the protocol conformances ADR-005 forbids. The adversarial reviewer flagged them as possible testing theater and dismissed the concern on exactly this ground.

---

## An Unsatisfiable AC Was Caught in DESIGN

AC-03 as written in DISCUSS demanded a root layout node with `frame.size == 200 × 20` **and zero children**. `.frame(...)` structurally cannot produce that: the `HasFrameSize` branch always constructs the frame node with exactly one child — the node for the content it wraps. The two halves of the AC contradicted each other.

The "zero children" property was real but belonged to a different node: the `ProgressBar`'s own node, which reaches the fill-constraints default and is constructed with no `children:` argument. DESIGN corrected AC-03 to assert both claims on the nodes that actually hold them, additionally pinning parent→child size propagation, which the original silently omitted. Back-propagated to DISCUSS via `design/upstream-changes.md` UC-01 before any scenario was written. Impact on scope, effort and slice boundaries: none.

Reviewer note (Eclipse, LOW, accepted as a process finding): the error shows DISCUSS did not check AC feasibility against layout dispatch. Future DISCUSS waves should validate each AC against dispatch behaviour before asserting DoR.

---

## Steps Completed

| Step | Phase | Status | Timestamp |
|---|---|---|---|
| 01-01 | RED | EXECUTED / PASS | 2026-07-22T08:35:50Z |
| 01-01 | GREEN | EXECUTED / PASS | 2026-07-22T08:36:22Z |
| 01-01 | COMMIT | EXECUTED / PASS | 2026-07-22T08:36:36Z |

**Step 01-01** — Replace the RED-scaffold body of `ProgressBar.clampedValue` (`.nan`) with the ADR-005 Decision 2 clamp; delete the `__SCAFFOLD__` marker and its comment block. One production file, three lines of logic.

Commit `23fd197` — 3 files, 365 insertions. Trailers `Step-Id: 01-01`, `Task-Id: progress-bar`.

**Refactoring L1–L6: assessed as a no-op, not skipped.** No duplication (L1); `clampedValue` is the domain term used throughout the ADR and renderer contract (L2); three statements, nothing to extract (L3); the negated-comparison order is normative and any "simplification" toward `min`/`max` reintroduces the NaN defect (L4); no abstraction or pattern available that would not violate ADR-005's constraint against new protocols (L5–L6).

**Mutation testing: skipped** per `CLAUDE.md` (Muter unavailable in this environment). Compensating evidence — the adversarial reviewer traced four mutations by hand and named a killing test for each: `min`/`max` substitution → AC-10 + AC-12 sweep; guard reordering → AC-10; negation removed → AC-09 + AC-10; second guard removed → AC-08 + AC-05.

---

## Test Summary

| Category | Count |
|---|---|
| New acceptance tests (2 files, one per slice) | 20 |
| Error / edge-case share of new tests | 9 of 20 (45%) |
| Passing at RED by reuse | 9 |
| Turned green by step 01-01 | 11 |
| Total passing after delivery | 175 (30 suites, 0 issues) |
| Pre-existing tests broken or modified | 0 |
| Existing test files modified | 0 |

AC-12 (`clampedValue ∈ 0…1` for arbitrary `Float`) is expressed as a property two ways, stdlib only: a curated 23-value special set (`0`, `±0`, `1`, `1±ulp`, `±∞`, `NaN`, `signalingNaN`, subnormals, `greatestFiniteMagnitude`) and a 4096-value sweep over raw `Float` bit patterns via an in-repo seeded SplitMix64. Fixed seeds (`0xC0FFEE`, `0x5EED`) make any counterexample exactly reproducible; the sweeps report the **first** counterexample rather than all of them. This pattern is now the project's reference for property-shaped testing without a third-party library and is recorded in `CLAUDE.md` § nWave Standing Exemptions.

---

## Review Gates

| Gate | Reviewer | Verdict | Blocker / High / Low |
|---|---|---|---|
| DISCUSS | Eclipse (`nw-product-owner-reviewer`) | approved | 0 / 0 / 2 |
| DESIGN | Architect (`nw-solution-architect-reviewer`) | approved | 0 / 0 / 0 |
| DEVOPS skip justification | Forge (`nw-platform-architect-reviewer`) | conditionally_approved | 0 / 2 / 1 |
| DISTILL | Sentinel (`nw-acceptance-designer-reviewer`) | approved | 0 / 0 / 0 |
| Roadmap | Sentinel | approved — "one step correct", 20/20 accounted, 0 orphans | 0 / 0 / 0 |
| Post-commit adversarial | `nw-software-crafter-reviewer` over `23fd197` | approved | 0 / 0 / 0 |

**Synthesis finding, attributable to no single reviewer.** Eclipse validated the DoR checklist as "8/8" — it has **nine** items, and the one silently dropped was "Outcome KPIs defined with measurable targets", precisely the item Forge independently found broken (KPI-5 measured adoption inside SpaceSim, a repo GameUI cannot observe). Neither reviewer caught it alone; the gap surfaced only when the two reviews were combined. DoR is recorded as 7/9 clean + 2 conditional rather than the original 9/9. KPI-5 was withdrawn as a GameUI KPI and reclassified as a game-team collaboration outcome.

Also corrected: Forge proposed a CI check `grep -rn "import Foundation" Sources/` "must exit 0". That is inverted — `grep` exits `0` when it *finds* matches. The gate must fail on `0` and pass on `1`.

---

## Known-Deferred and Open

- **`Slider` still stores `value` unguarded.** The public API is now inconsistent in value safety. ADR-005 accepts this deliberately (ODQ-PB-03): retrofitting `Slider` changes the behaviour of a shipped type and belongs in its own change with its own acceptance criteria. If `Slider` is later given the same treatment, ADR-005 should be superseded by one covering both types.
- **Out of scope by decision**: indeterminate / unknown-duration bars (needs an animation-time contract no GameUI view has), percentage or value text inside the bar (compose a `Text` in a `ZStack`), segmented / stepped bars, vertical orientation, animation or easing, click-to-seek (explicitly excluded by D5 — reintroducing it means `onTap` plus a `HitTest.swift` branch, a separate feature).

### Process findings carried forward

- **F-1 — the repo has no CI.** `docs/product/architecture/brief.md` names "Linux CI catches any inadvertent `import Foundation`" as the enforcement mechanism in **five** feature sections. There is no `.github/workflows/`, no `.gitlab-ci.yml`, no `.circleci`, no `Jenkinsfile`. The no-Foundation and `Float`-only constraints are enforced by code review alone. Verified independently by Forge; repo-wide and pre-dating this feature. **OPEN**, logged as backlog per user decision. Until CI exists, treat "Linux CI catches it" in `brief.md` as aspirational across all five features that claim it. Related (F-5): `swift test` requires the SwiftPM sandbox disabled in this environment, which may hide issues on a CI runner — verify with the sandbox enabled once CI exists.
- **`des-commit` cannot emit the `Task-Id` trailer.** It appends only `Step-Id`, but the stop-hook `StepCompletionValidator` requires both on the same commit. The first commit was structurally incomplete and had to be amended (message-only; identical blobs). Until `des-commit` gains a `--task-id` flag, write `Task-Id: <feature>` into the `--message` body at commit time. Affects every step in every feature in this repo.
- **`nwave-ai outcomes register` is broken in 3.13.0.** `_SCHEMA_PATH` resolves to `<site-packages>/docs/product/outcomes/schema.json`, which is not shipped; every invocation raises `FileNotFoundError`. `docs/product/outcomes/registry.yaml` was written by hand. `outcomes check-delta` is unaffected and passes — though for this feature it passed *vacuously*, since the registry did not yet exist at the time of the check. Recorded so a later reader does not mistake the exit `0` for a positive signal.

All three are recorded in `CLAUDE.md` § nWave Standing Exemptions and in the feature-delta's Upstream Issues.

---

## Lessons Learned

1. **Apply a precedent's test, not its verdict.** ADR-003's unification of padding was the nearest analogy available, and it pointed the wrong way. The analogy held only until its own distinguishing-operation test was actually run against the new pair. Citing a precedent's conclusion would have produced a `Slider` with a dead callback; citing its *reasoning* produced the opposite and correct answer.

2. **A design whose change surface is one new file makes RED partially green — and that is signal, not noise.** Nine tests passing against the scaffold was the earliest and cheapest possible confirmation of the no-layout-branch bet. Classifying them explicitly as `ALREADY_SATISFIED_BY_REUSE` (rather than letting them read as suspicious passes) is what turned that into actionable planning: the two slices were collapsed at the gate rather than after a wasted cycle.

3. **Behaviour obtained by absence needs tests that pin the absence.** `ProgressBar` is never hit-tested because it matches no `hitTestNode` branch. Nothing in the source states that. The characterization tests plus ADR-005's explicit prohibition list are the only things that will make a future `HasFrameSize` conformance fail loudly instead of silently redirecting both layout and hit-test.

4. **Standard-library convenience functions can violate the guarantee they appear to provide.** `min`/`max` propagate NaN. Any clamp written for values sourced from live game state must be checked against the degenerate input before the convenient form is accepted. The negated-comparison idiom belongs in every future GameUI clamp.

5. **Feasibility-check acceptance criteria against real dispatch code during DISCUSS.** AC-03 was unsatisfiable by construction. Caught in DESIGN it cost one back-propagation note; caught after RED it would have invalidated a committed test.

6. **Independent reviewers can each be individually correct and jointly wrong.** Eclipse's "8/8" and Forge's KPI-5 finding were each defensible in isolation; the dropped ninth DoR item was visible only when the two were read together. Where reviews are dispatched in parallel, the synthesis step is a gate in its own right, not a formality.

---

## Source Files

**Added**
- `Sources/GameUI/ProgressBar.swift` — `ProgressBar` struct, `clampedValue` computed property

**Modified**: none.

**Tests added**
- `Tests/GameUITests/acceptance/ProgressBarSlice1DeclareAndFillTests.swift` — 10 tests (AC-01…AC-07)
- `Tests/GameUITests/acceptance/ProgressBarSlice2ValueSafetyTests.swift` — 10 tests (AC-08…AC-14, incl. property sweeps)

---

## Related Artifacts

| Artifact | Location |
|---|---|
| ADR-005: ProgressBar / Slider Separation and In-View Value Clamping | `docs/product/architecture/adr-005-progressbar-slider-separation.md` |
| Renderer contract (track-then-fill draw order) | `docs/product/architecture/brief.md` § progress-bar Feature |
| Journey (declare → layout → render) | `docs/product/journeys/progress-bar.yaml` |
| JOB-06 | `docs/product/jobs.yaml` |
| Persona | `docs/product/personas/riku-nakamura.yaml` |
| Outcomes OUT-1 (operation), OUT-2 (invariant) | `docs/product/outcomes/registry.yaml` |
| ATDD infrastructure policy (bootstrapped this feature) | `docs/architecture/atdd-infrastructure-policy.md` |
| Full four-wave record | `docs/feature/progress-bar/feature-delta.md` |

**Related ADRs**: ADR-001 (renderer dumbness, pure derived accessors), ADR-003 (immutable-value unification test — inverted here), ADR-004 (pure accessor as renderer contract).
