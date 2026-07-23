# RED Classification — view-tree-traversal-test-support

Pre-DELIVER fail-for-the-right-reason gate. Produced by DISTILL; read by DELIVER at PREPARE
to confirm RED is genuine.

Command: `swift test --disable-sandbox` (the `--disable-sandbox` flag is an environment
constraint, not a code defect — see `CLAUDE.md` § Running Tests).

## Summary

| Measure | Before DISTILL | After DISTILL |
|---|---|---|
| Total tests | 175 | 218 |
| Suites | 30 | 32 |
| Pre-existing tests failing | 0 | **0** |
| Pre-existing test files modified | — | **0** |
| Existing source files modified | — | **0** (only `Package.swift`, which DESIGN requires) |
| New tests | — | 43 |
| New tests RED | — | **42** |
| New tests green at scaffold | — | 1 (a control test — see below) |
| Recorded issues | 0 | 65, **all `Expectation failed`** |

Classification of every recorded issue: **65 / 65 `MISSING_FUNCTIONALITY`**. Zero
`COMPILE_ERROR`, zero `LINK_ERROR`, zero `TRAP`, zero `SETUP_FAILURE`. Verified mechanically —
`grep -o 'recorded an issue at .*: [A-Za-z ]*'` yields exactly one issue kind,
`Expectation failed`, 65 times, and the suite contains no `Fatal error` / signal / linker
diagnostic.

Scaffolds return empty values and never trap. That is deliberate: in Swift `fatalError`,
`preconditionFailure` and `assertionFailure` terminate the whole test process, which the Red
Gate classifies as BROKEN rather than RED. Every new test therefore fails as a clean
assertion naming the behaviour that is missing.

## Per-scenario classification

All rows are `MISSING_FUNCTIONALITY` — the assertion fires because `childViews` /
`collect` are scaffolds returning empty. One row is not RED and is labelled as such.

### Slice 1 — `ViewTraversalSlice1CollectTests` (18 tests, 18 RED)

| Scenario | Classification |
|---|---|
| a declared HUD screen reports the shield charge a downstream test asserts on | MISSING_FUNCTIONALITY |
| collect finds a progress bar nested inside a composite body | MISSING_FUNCTIONALITY |
| collect finds a progress bar declared at the root of the tree | MISSING_FUNCTIONALITY |
| collect reaches a progress bar through frame padding and button layers | MISSING_FUNCTIONALITY |
| collect reaches every view of a multi-statement builder body | MISSING_FUNCTIONALITY |
| collect visits the tree depth first in declaration order | MISSING_FUNCTIONALITY |
| collect keeps visiting later siblings after it finds a match | MISSING_FUNCTIONALITY |
| collect reaches a progress bar twelve modifier layers deep | MISSING_FUNCTIONALITY |
| collect finds every button through the existential button type | MISSING_FUNCTIONALITY |
| a concrete button specialisation matches fewer buttons than the existential | MISSING_FUNCTIONALITY |
| each convenience agrees with the collect call it wraps | MISSING_FUNCTIONALITY |
| collectTexts reports both Text and WrappedText content | MISSING_FUNCTIONALITY |
| collectTextColors reports colours for Text only and leaves WrappedText out | MISSING_FUNCTIONALITY |
| collect returns nothing when the tree contains no view of that type | MISSING_FUNCTIONALITY |
| collect returns nothing for a bare leaf that is not the sought type | MISSING_FUNCTIONALITY |
| collect returns nothing from a container holding only views of another type | MISSING_FUNCTIONALITY |
| collect resolves a composite whose body is directly the sought view | MISSING_FUNCTIONALITY |
| collect returns the same result when called repeatedly on the same tree | MISSING_FUNCTIONALITY |

### Slice 2 — `ViewTraversalSlice2CoverageTests` (25 tests, 24 RED, 1 control)

| Scenario | Classification |
|---|---|
| VStack reports its declared children and the sentinel inside is reached | MISSING_FUNCTIONALITY |
| HStack reports its declared children and the sentinel inside is reached | MISSING_FUNCTIONALITY |
| ZStack reports its declared children and the sentinel inside is reached | MISSING_FUNCTIONALITY |
| a stack holding a single view reaches that view | MISSING_FUNCTIONALITY |
| FrameModifier reports its framed content and the sentinel inside is reached | MISSING_FUNCTIONALITY |
| PaddingModifier reports its padded content and the sentinel inside is reached | MISSING_FUNCTIONALITY |
| DirectionalPaddingModifier reports its padded content and the sentinel inside is reached | MISSING_FUNCTIONALITY |
| Button reports its content and the sentinel inside is reached | MISSING_FUNCTIONALITY |
| TupleView2 reports both children and both sentinels are reached | MISSING_FUNCTIONALITY |
| TupleView3 reports all three children and all three sentinels are reached | MISSING_FUNCTIONALITY |
| TupleView4 reports all four children and all four sentinels are reached | MISSING_FUNCTIONALITY |
| a composite view reports its body and the sentinel inside is reached | MISSING_FUNCTIONALITY |
| every child-bearing view type reports at least one child | MISSING_FUNCTIONALITY |
| Text is a leaf and is still reached when nested | MISSING_FUNCTIONALITY |
| WrappedText is a leaf and is still reached when nested | MISSING_FUNCTIONALITY |
| Rectangle is a leaf and is still reached when nested | MISSING_FUNCTIONALITY |
| Texture is a leaf and is still reached when nested | MISSING_FUNCTIONALITY |
| Spacer is a leaf and is still reached when nested | MISSING_FUNCTIONALITY |
| Slider is a leaf and is still reached when nested | MISSING_FUNCTIONALITY |
| Checkbox is a leaf and is still reached when nested | MISSING_FUNCTIONALITY |
| ProgressBar is a leaf conforming to no dispatch protocol and is still reached when nested | MISSING_FUNCTIONALITY |
| every registered leaf type reports no children yet is reachable when nested | MISSING_FUNCTIONALITY |
| no registered leaf type traps when asked for its children | MISSING_FUNCTIONALITY |
| collecting from a view whose body contains itself terminates rather than hanging | MISSING_FUNCTIONALITY (exit test: scaffold returns `[]`, child exits 0, expected `.failure`) |
| **reading a primitive view's body traps** | **NOT_RED — CONTROL, correctly green** |

## The one test that is green, and why that is correct

`reading a primitive view's body traps` asserts that
`Text(content:fontSize:).body` terminates the process. It exercises **shipped, unchanged**
behaviour (`LeafViews.swift:29` — `fatalError("Text is a primitive view")`), not anything this
feature adds, so it has no RED obligation. It exists to make its neighbours non-vacuous: it
proves the `Never`-body trap is genuinely reachable, which is what turns "`childViews(of:
Text(...))` returned without trapping" from a tautology into an observation. If `childViews`
ever mis-routes a primitive down the composite `V.Body.self != Never.self` branch, that trap
is what fires.

It is a Swift Testing **exit test** (`await #expect(processExitsWith: .failure) { … }`): the
closure runs in a spawned child process, so the trap is an assertable outcome rather than
something that kills the run. Asserts `.failure`, never a specific signal — `fatalError`
surfaces as SIGILL or SIGTRAP depending on platform, and both CI jobs must agree.

## Vacuous-green audit (why 5 tests were rewritten mid-wave)

A first draft left 7 new tests green at scaffold. Five were green **vacuously** — they were
negative assertions (`collect(...).isEmpty`, `first == second`,
`collectButtons(...) == collect(...)`) satisfied by a traversal that returns nothing for
everything.

That is not a cosmetic problem. It is *this feature's entire bug class*: silent
under-traversal makes `#expect(bars.isEmpty)` pass for the wrong reason, and that is what
shipped twice in the field. A vacuous negative test in the suite meant to eliminate the bug
would be the bug, in the guard.

Each of the five now carries a **positive control in the same test** — an assertion that the
walk demonstrably happened, alongside the assertion about what it did not find. All five are
now RED. This is a standing rule for this suite: no negative assertion without a positive
control beside it.

## Gate verdict

**PASS.** Handoff to DELIVER is unblocked.

- Every new test fails for the right reason (assertion, not infrastructure).
- No test fails for setup, import, link or trap reasons.
- The pre-existing 175-test suite is green and byte-for-byte untouched.
- The registry CI step (`brief.md` § Architectural Enforcement, verbatim) was executed
  locally against the authored registry: **19 declared conformances, 19 registered, 0 missing,
  0 stale.**
- The `Sources/GameUITesting/` no-dispatch-cast grep finds nothing (exit 1 = pass).

## Known, intentional CI failure on this branch

`Sources/GameUI/ViewTraversal.swift`, `Sources/GameUITesting/Collect.swift` and
`Sources/GameUITesting/Conveniences.swift` each carry a `__SCAFFOLD__` marker. The
`constraints` job greps `Sources/` for it and fails. That is by design (Mandate 7) and is why
this work sits on a feature branch. DELIVER removes all six markers as it implements; the job
goes green when the last one is gone.
