# ATDD Infrastructure Policy

Per `nw-distill` § Project Infrastructure Policy. One file per project. Apply-if-exists;
write-if-absent; rewrite with `--policy=fresh`. Git history is the audit trail.

Bootstrapped 2026-07-22 during the `progress-bar` DISTILL wave, back-filled from the conventions
already in use across `Tests/GameUITests/acceptance/`.

**Project shape note.** GameUI is a pure library: a declarative view layer plus a pure layout
function. It performs no I/O, opens no connection, and holds no reference type. Consequently the
"driven internal" and "driven external" tables are near-empty by construction, not by omission.
The single injected dependency in the whole codebase is `LayoutEngine.textMeasurer`.

## Driving

| Port | Mechanism | Note |
|---|---|---|
| Swift public API (`LayoutEngine.layout(_:in:)`) | Direct in-process call from the test | No subprocess, no HTTP. The library IS the entry point; a test call is the user's real invocation path. |
| Swift public API (view type initialisers, e.g. `ProgressBar.init`) | Direct construction | Declaring a view is the user-facing action. |
| Swift public API (`hitTestButton(view:node:at:)`) | Direct in-process call | Pure query over a layout tree. |
| Pure derived accessors (`WrappedText.clippedLines`, `ProgressBar.clampedValue`) | Direct call | These are the renderer-facing contract surface — a test call is exactly what a renderer does. |

## Driven internal (real)

| Port | Mechanism | Note |
|---|---|---|
| — | — | None. GameUI has no repository, cache, or shared mutable state. `LayoutTree` is an immutable return value, not a store. |

## Driven external / non-deterministic (fake)

| Port | Fake | Note |
|---|---|---|
| `LayoutEngine.textMeasurer` (`(String, Float) -> Size`) | `stubMeasurer` — local function, `width = fontSize × charCount`, `height = fontSize` | Real measurement is renderer/font-dependent and therefore non-deterministic across platforms. Every text-related acceptance file declares its own copy; the shape is identical across `WrappedText*Tests.swift`. Not used by `ProgressBar`, which has no text to measure. |

## Notes

- The renderer is **not** a port of GameUI. GameUI never invokes it; it consumes the `LayoutTree`
  value independently. Renderer expectations are verified by asserting on the values a renderer
  would read (`node.frame`, `clampedValue`, `clippedLines`), not by driving a renderer double.
- No test framework beyond `swift-testing` is permitted (`CLAUDE.md`: no third-party dependencies).
  This rules out Gherkin runners and property-based-testing libraries; properties are expressed as
  parametrized `@Test(arguments:)` plus a seeded in-repo generator.
