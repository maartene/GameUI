# GameUI — Claude Code Guidelines

## Development Paradigm

object-oriented

Protocol-oriented value types consistent with existing Swift codebase. All new types are structs. No classes beyond what Swift 6.2 requires for `Sendable`. Crafter: @nw-software-crafter.

## Mutation Testing Strategy

per-feature

Muter is not reliably available in this environment. Skip mutation testing phases when running nWave DELIVER.

## Technology Constraints

- Swift 6.2
- No Foundation import
- `Float` geometry only (`Size`, `Rect`, `Point` are project-internal)
- Swift Testing framework (not XCTest)
- No third-party dependencies

## Test Naming Convention

Use backtick-quoted function names — not string labels with a separate function name:

```swift
// Correct
@Test func `Button constructed with isFocused true carries isFocused == true`() { }

// Wrong
@Test("Button constructed with isFocused true carries isFocused == true")
func buttonConstructedWithIsFocusedTrueCarriesTrue() { }
```

## Running Tests

```
swift test --disable-sandbox
```

`--disable-sandbox` is required in this environment. Without it SwiftPM fails with
`sandbox-exec: sandbox_apply: Operation not permitted` and a misleading "Invalid manifest"
error — an environment constraint, not a code defect. Ignore any nWave skill that hardcodes
`uv run pytest ...`; this is a Swift package.

## CI

`.forgejo/workflows/ci.yml` — Forgejo Actions, on push to `main`, on PR, and manual dispatch.

| Job | Runner | Gates |
|---|---|---|
| `constraints` | `docker` (alpine) | No `import Foundation`/`Darwin`/`Glibc`, no `CGFloat`/`Double`, no leftover `__SCAFFOLD__` — all in `Sources/` |
| `test-linux` | `docker` (`swift:6.2`, ARM64) | `swift build --build-tests` + `swift test` |
| `test-macos` | `macos-arm64` | `swift build --build-tests` + `swift test` |

The Linux job is the real enforcer of the § Technology Constraints purity rules: on Linux an
inadvertent `import Foundation` or `CGFloat` fails to **compile**, so it cannot reach `main`.
The `constraints` job just reports it faster and more legibly than a compiler error.

The `CGFloat`/`Double` grep strips trailing `//` comments before matching — without that,
`LayoutTypes.swift:2` ("no CGFloat, no Foundation") is a false positive.

**Do not add `uses: actions/checkout@vN` to these jobs.** It is a JavaScript action: the runner
executes it with `node` *inside the job container*, and neither `alpine` nor the official `swift`
image ships Node, so it dies with `exec: "node": executable file not found in $PATH` (exit 127)
before any step of ours runs. Each job therefore clones with plain `git`, which needs no Node and
behaves the same on macOS and Linux. The same applies to any other JS action — prefer a `run:`
step, or add Node to the container deliberately.

## nWave: Standing Exemptions

nWave's reasoning waves (DISCUSS / DESIGN / DISTILL / review gates) apply here and carry
their weight. Its **executable** mandates are Python-first and largely do not. The exemptions
below are **settled project facts — do not re-derive, re-justify, or re-decide them per
feature**, and never satisfy one by inventing a Python-shaped artifact in a Swift package.

| nWave mandate | Status | What we do instead |
|---|---|---|
| Gherkin `.feature` files + step definitions (pytest-bdd/cucumber) | **N/A** | `swift-testing` suites in `Tests/GameUITests/acceptance/`, one file per slice. The `.swift` files ARE the scenario SSOT. |
| Property-based testing library (Hypothesis / SwiftCheck / fast-check) | **N/A** — no third-party deps | Curated special-value sets via `@Test(arguments:)`, plus a seeded in-repo SplitMix64 sweep over `Float(bitPattern:)` with fixed seeds. Report the FIRST counterexample, not all of them. Reference: `ProgressBarSlice2ValueSafetyTests.swift`. |
| `assert_state_delta` / universe port (`tests/common/state_delta.*`) | **Vacuous** | Every type here is a frozen immutable value with no driven ports and no mutable state. There is no state delta to declare. Contracts are pure-function shapes: assert on the return value. |
| Mandate-12: `domain_types.py`, step-reuse ratio ≥4× | **Undefined** | The ratio is `step_invocations / step_decorators`; with no step decorators it has no value. Do not report a number. |
| Mandate-10 Tier B: `RuleBasedStateMachine` in-memory journey | **N/A** | No state machine to model. Tier A only. |
| Mutation testing (mutmut / PIT / Muter) | **Skip** | See § Mutation Testing Strategy above. |
| Phase 3.5 Elevator Pitch demo gate (subprocess + stdout) | **Adapted** | This is a library with no CLI. The driving port IS the public API, so the "demo" is an API call whose observable output is the returned `LayoutTree` / accessor value. Capture real values; do not fabricate a subprocess. |
| ATDD Infrastructure Policy | **Recorded** | `docs/architecture/atdd-infrastructure-policy.md`. Driving ports are direct in-process calls; zero driven adapters; the only fake is the `stubMeasurer` closure for `LayoutEngine.textMeasurer`. |

### Known broken nWave tooling (nwave-ai 3.13.0)

Verified defects — work around them, and do not mistake them for usage errors:

- **`nwave-ai outcomes register` always fails.** `registry_service._SCHEMA_PATH` resolves to
  `<site-packages>/docs/product/outcomes/schema.json`, which exists only in the nwave-ai source
  repo and is not shipped. Raises `FileNotFoundError` on every invocation. Write registry rows
  into `docs/product/outcomes/registry.yaml` by hand, in the key order
  `nwave_ai.outcomes.domain.serialization.outcome_to_dict` produces.
  `nwave-ai outcomes check-delta` is unaffected and works.
- **`scripts/shared/telemetry.py` and `scripts/shared/density_config.py` do not exist** in the
  installed package, though several skills instruct you to call them. Emit density telemetry via
  the underlying contract instead: `DocumentationDensityEvent(...).to_audit_event()` →
  `JsonlAuditLogWriter().log_event(...)`, with `PYTHONPATH` set to
  `<site-packages>/nWave/lib/python`. Resolve density by reading `~/.nwave/global-config.json`
  directly.

### Wave right-sizing

Small changes on an established pattern do not need all six waves. A new leaf view following
the `Slider` / `Checkbox` shape needs an ADR (if it makes a non-obvious structural choice),
acceptance tests, and the implementation — not a JTBD analysis, persona file, and emotional-arc
journey. Reserve the full wave sequence for features that introduce a genuinely new mechanism.
