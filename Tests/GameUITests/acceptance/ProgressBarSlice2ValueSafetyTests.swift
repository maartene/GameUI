// ProgressBar Slice 2 — Value Safety Acceptance Tests
// Driving port: ProgressBar.clampedValue
// US-02: Trust Any Value From Game State  (AC-08 … AC-14)
//
// Real SpaceSim failure values: 1.4 (shield recharge burst overshoot),
// -0.2 (damage applied before the frame's own clamp), NaN (division by a
// destroyed hull's zero max-shield capacity).
//
// AC-12 is a property, not an example. CLAUDE.md forbids third-party
// dependencies, so there is no Hypothesis/SwiftCheck available. The property is
// expressed as a curated special-value sweep plus a seeded bit-pattern sweep
// over the whole Float domain — see `seededFloatSweep` below. (Resolves ODQ-PB-02.)
//
// Enable tests one at a time in DELIVER; each maps to one TDD cycle.

import Testing
@testable import GameUI

// MARK: - Seeded generator (stdlib only — no Foundation)

/// SplitMix64. Deterministic across runs and platforms, so a property failure is
/// always reproducible from the seed printed in the failure message.
private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// Arbitrary `Float` values drawn from raw bit patterns, so the sweep includes
/// NaNs, infinities, subnormals and both zeroes — not just the "nice" range a
/// uniform `Float.random(in:)` would produce.
private func seededFloatSweep(seed: UInt64, count: Int) -> [(seed: UInt64, value: Float)] {
    var rng = SplitMix64(seed: seed)
    return (0..<count).map { _ in
        let bits = UInt32(truncatingIfNeeded: rng.next())
        return (seed: UInt64(bits), value: Float(bitPattern: bits))
    }
}

/// Every `Float` that has ever been observed to break a naive clamp, plus the
/// boundaries of the valid range.
private let specialFloats: [Float] = [
    0.0, -0.0, 1.0, 0.65, 0.5,
    1.4, -0.2, 2.0, -1.0, 100.0, -100.0,
    .nan, .signalingNaN, .infinity, -.infinity,
    .leastNonzeroMagnitude, -.leastNonzeroMagnitude,
    .leastNormalMagnitude, .greatestFiniteMagnitude, -.greatestFiniteMagnitude,
    .ulpOfOne, 1.0 - .ulpOfOne, 1.0 + .ulpOfOne,
]

private func bar(_ value: Float) -> ProgressBar {
    ProgressBar(value: value, label: "Shield charge")
}

@Suite("ProgressBar — Value Safety")
struct ProgressBarSlice2ValueSafetyTests {

    // -------------------------------------------------------------------------
    // AC-08: Shield recharge burst overshoot is clamped to a full bar
    // -------------------------------------------------------------------------

    @Test func `a shield charge of 1 point 4 clamps to a full bar`() {
        #expect(bar(1.4).clampedValue == 1.0)
    }

    // -------------------------------------------------------------------------
    // AC-09: Damage applied before the frame's own clamp yields an empty bar
    // -------------------------------------------------------------------------

    @Test func `a shield charge of minus 0 point 2 clamps to an empty bar`() {
        #expect(bar(-0.2).clampedValue == 0.0)
    }

    // -------------------------------------------------------------------------
    // AC-10: NaN resolves to empty — not a crash, and emphatically not a full bar
    // This is the case a min/max implementation silently fails.
    // -------------------------------------------------------------------------

    @Test func `a NaN shield charge resolves to an empty bar rather than crashing or filling`() {
        #expect(bar(.nan).clampedValue == 0.0)
        #expect(bar(.signalingNaN).clampedValue == 0.0)
    }

    // -------------------------------------------------------------------------
    // AC-11: Infinities resolve to the nearest endpoint
    // -------------------------------------------------------------------------

    @Test func `positive infinity fills the bar and negative infinity empties it`() {
        #expect(bar(.infinity).clampedValue == 1.0)
        #expect(bar(-.infinity).clampedValue == 0.0)
    }

    // -------------------------------------------------------------------------
    // AC-13: In-range values pass through exactly, including both endpoints
    // -------------------------------------------------------------------------

    @Test(arguments: [Float(0.0), 0.25, 0.65, 0.999, 1.0])
    func `an in-range shield charge passes through unchanged`(value: Float) {
        #expect(bar(value).clampedValue == value)
    }

    // -------------------------------------------------------------------------
    // AC-14: The declared value stays readable verbatim
    // Clamping is a rendering guarantee, not silent data loss.
    // -------------------------------------------------------------------------

    @Test(arguments: [Float(1.4), -0.2, 42.0])
    func `an out-of-range shield charge is still readable as declared`(value: Float) {
        #expect(bar(value).value == value)
    }

    // -------------------------------------------------------------------------
    // AC-12 (property, curated): clampedValue lies in 0...1 for every special Float
    // -------------------------------------------------------------------------

    @Test(arguments: specialFloats)
    func `clamped value lies within zero and one for every special float`(value: Float) {
        let clamped = bar(value).clampedValue
        #expect(clamped >= 0.0 && clamped <= 1.0, "input \(value) produced \(clamped)")
    }

    // -------------------------------------------------------------------------
    // AC-12 (property, swept): clampedValue lies in 0...1 across the Float domain
    // 4096 values drawn from raw bit patterns — includes NaNs, infinities and
    // subnormals. Seed is fixed so any failure reproduces exactly.
    // -------------------------------------------------------------------------

    @Test func `clamped value lies within zero and one across a seeded sweep of the whole float domain`() {
        let counterexample = seededFloatSweep(seed: 0xC0FFEE, count: 4096).first { _, value in
            let clamped = bar(value).clampedValue
            return !(clamped >= 0.0 && clamped <= 1.0)
        }
        #expect(
            counterexample == nil,
            """
            bit pattern \(counterexample?.seed ?? 0) → input \(counterexample?.value ?? 0) \
            produced \(bar(counterexample?.value ?? 0).clampedValue)
            """
        )
    }

    // -------------------------------------------------------------------------
    // AC-12b (property): a fill can never be drawn wider than its track
    // The invariant JOB-06 exists to guarantee, stated in renderer terms.
    // -------------------------------------------------------------------------

    @Test func `fill width never exceeds track width across a seeded sweep of the whole float domain`() {
        let trackWidth: Float = 200
        let counterexample = seededFloatSweep(seed: 0x5EED, count: 4096).first { _, value in
            let fillWidth = trackWidth * bar(value).clampedValue
            return !(fillWidth >= 0.0 && fillWidth <= trackWidth)
        }
        #expect(
            counterexample == nil,
            """
            bit pattern \(counterexample?.seed ?? 0) → input \(counterexample?.value ?? 0) \
            produced fill width \(trackWidth * bar(counterexample?.value ?? 0).clampedValue)
            """
        )
    }

    // -------------------------------------------------------------------------
    // AC-12c (property): clampedValue is deterministic
    // Renderers may read it several times per frame.
    // -------------------------------------------------------------------------

    @Test(arguments: specialFloats)
    func `clamped value is the same on repeated reads`(value: Float) {
        let subject = bar(value)
        #expect(subject.clampedValue == subject.clampedValue)
    }
}
