# RED Classification — progress-bar

Pre-DELIVER fail-for-the-right-reason gate. Run against the Mandate-7 scaffold
(`Sources/GameUI/ProgressBar.swift`, `clampedValue` returns `.nan`).

Command: `swift test --disable-sandbox --filter ProgressBar`
Result: **20 tests, 11 failing, 9 passing, 62 issues.**
Full suite: **175 tests, 62 issues — all 62 from the two new suites. Zero regressions.**

DELIVER reads this file at PREPARE to confirm RED is genuine.

---

## Failing — all `MISSING_FUNCTIONALITY` (correct RED)

Every failure is an assertion firing on a `.nan` `clampedValue`. None is an import
error, a build failure, or a fixture problem. Swift compiles, the suites load, the
assertions are reached and reject the scaffold's value.

| Test | AC | Classification |
|---|---|---|
| `fill width for a 65 percent bar in a 200 wide node is 130` | AC-05 | MISSING_FUNCTIONALITY |
| `full bar fill width equals track width and empty bar fill width is zero` | AC-05b | MISSING_FUNCTIONALITY |
| `a shield charge of 1 point 4 clamps to a full bar` | AC-08 | MISSING_FUNCTIONALITY |
| `a shield charge of minus 0 point 2 clamps to an empty bar` | AC-09 | MISSING_FUNCTIONALITY |
| `a NaN shield charge resolves to an empty bar rather than crashing or filling` | AC-10 | MISSING_FUNCTIONALITY |
| `positive infinity fills the bar and negative infinity empties it` | AC-11 | MISSING_FUNCTIONALITY |
| `clamped value lies within zero and one for every special float` (23 cases) | AC-12 | MISSING_FUNCTIONALITY |
| `clamped value lies within zero and one across a seeded sweep of the whole float domain` | AC-12 | MISSING_FUNCTIONALITY |
| `fill width never exceeds track width across a seeded sweep of the whole float domain` | AC-12b | MISSING_FUNCTIONALITY |
| `clamped value is the same on repeated reads` (23 cases) | AC-12c | MISSING_FUNCTIONALITY |
| `an in-range shield charge passes through unchanged` (5 cases) | AC-13 | MISSING_FUNCTIONALITY |

Zero tests classified `IMPORT_ERROR`, `FIXTURE_BROKEN`, `SETUP_FAILURE`,
`WRONG_ASSERTION`, or `OBSERVABLE_NOT_AT_PORT`. **The gate passes — handoff to
DELIVER is not blocked.**

---

## Passing at DISTILL time — `ALREADY_SATISFIED_BY_REUSE`

Nine tests pass against the scaffold. This is **not** a wrong-RED failure and not a
test defect; it is the direct consequence of DDD-4 / DDD-5, which decided that layout
and hit-test behaviour would be obtained by reuse rather than new code. Once the type
exists at all, that behaviour is already correct.

| Test | AC | Why it passes on the scaffold |
|---|---|---|
| `ProgressBar carries value label fillColor and trackColor as declared` | AC-01 | Stored properties must be real for the suite to compile. |
| `ProgressBar declared without colours defaults to green fill on darkGray track` | AC-02 | Default arguments are part of the initialiser signature. |
| `framed ProgressBar is sized by its frame and the bar node itself has no children` | AC-03 | Existing `HasFrameSize` branch (`LayoutEngine.swift:38-45`), unmodified. |
| `bare ProgressBar fills the whole constraint box and has no children` | AC-04 | Existing fill-constraints default (`LayoutEngine.swift:68`), unmodified. |
| `bare ProgressBar lays out identically to a bare Slider` | AC-04b | Both reach the same default branch. |
| `hit testing a ProgressBar returns nil at every point including its own frame` | AC-06 | `ProgressBar` matches no `hitTestNode` branch → terminal `return nil`. |
| `a ProgressBar beside a Button does not consume a hit-test index` | AC-06b | Same — it never enters the traversal count. |
| `ProgressBar is a primitive view whose Body is Never` | AC-07 | `body: Never` is required for the type to be a leaf. |
| `an out-of-range shield charge is still readable as declared` | AC-14 | `value` is stored verbatim; the scaffold does not overwrite it. |

### What this means for DELIVER

**Slice 01's learning hypothesis is already answered — it holds.** The brief stated the
slice would disprove DDD-4/D8 ("a display-only bar needs no `LayoutEngine` branch") if
the fill-constraints default turned out wrong for a bar. It is not wrong: AC-03, AC-04,
AC-04b, AC-06 and AC-06b are green with zero new layout code. The bet paid off at the
cheapest possible moment.

The consequence is that Slice 01 has almost no TDD content left — only AC-05/AC-05b
(fill width), and those depend on `clampedValue`, which is Slice 02's work. **The two
slices have effectively collapsed into one.** DELIVER should plan a single cycle
implementing `clampedValue`, after which all 20 tests go green together. This is worth
recording rather than pretending the original two-slice sequence still holds.

These nine tests remain valuable as **characterization tests**: they pin the reuse
decisions so that a future conformance added to `ProgressBar` (to `HasFrameSize`,
`AnyButton`, …) breaks them loudly. That is exactly the constraint ADR-005 records.
