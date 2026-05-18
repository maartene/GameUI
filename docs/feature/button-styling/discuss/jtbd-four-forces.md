# JTBD Four Forces Analysis — button-styling

## Overview

The Four Forces model (Jobs-to-be-Done, Bob Moesta) identifies the competing motivations that drive
a developer to adopt (or resist) a new solution. Applied here to both design candidates:

- **Option A — Tag/metadata**: Add `tag: String` to `AnyButton`. Renderer inspects tag.
- **Option B — Color injection**: Add `backgroundColor`/`foregroundColor` to `AnyButton`. Button
  carries colors. Renderer uses them directly.

---

## Forces for Job 1 — Visually Distinguish Button Types

### Push (frustration with current state)

- All buttons look identical to the renderer because `AnyButton` exposes no semantic information
  beyond `isFocused`.
- Riku must inspect button _text content_ ("Quit" === red) to apply role-appropriate styling,
  coupling renderer logic to content rather than intent.
- Adding a new button role requires editing both the call site _and_ adding a new text-content
  conditional in the renderer — two places of change for one conceptual operation.

### Pull (attraction toward new solution)

- **Option A Pull**: A `tag` on `AnyButton` makes semantic intent machine-readable. The renderer
  switches on tag values that are decoupled from display text. Renaming "Quit" to "Exit" does not
  change rendering behavior.
- **Option B Pull**: Color injection is the simplest mental model — "the button carries its own
  colors." No renderer switch required; colors fall through directly to the draw call. Minimal
  cognitive overhead for simple games.

### Anxiety (fear about the new solution)

- **Option A Anxiety**:
  - "What if I forget to set `tag` on a button? What's the fallback?" → Need a sensible default
    (empty string / "default" tag treated as unstyled).
  - "What if two developers use different tag name conventions ('primary' vs 'Primary')?"
    → Convention friction; no type safety.
- **Option B Anxiety**:
  - "Now my call site knows about colors, but I want to change the theme globally. I have to
    update every `Button(backgroundColor: .blue)` declaration." → Central theming breaks.
  - "My renderer author receives colors they did not choose. How do they signal 'use default
    renderer colors' vs 'use my injected color'?" → Requires Optional Color + nil-means-default
    logic in every renderer.
  - "What happens if I inject colors but the renderer ignores them? Silent visual bugs." → No
    contract enforcement.

### Habit (inertia from existing workflow)

- Current pattern: Riku checks `isFocused` (a Boolean on `AnyButton`) in the renderer. A `tag`
  string follows the exact same inspection pattern. Low friction.
- Riku is accustomed to SwiftUI's `.buttonStyle` modifier pattern where role is declared at call
  site and rendering handled by the environment. Option A's semantic tag mirrors this mental model.
- A color injection approach is unfamiliar because existing GameUI primitives (`Text`, `Button`)
  carry _content_ properties, not _appearance_ properties. Injecting colors would break the
  content/appearance separation established by the library's design philosophy.

---

## Forces for Job 2 — Consistent Theming Across Screens

### Push

- Riku currently has no way to express "this is a primary button" in 12 screens; styling is either
  uniform or driven by text content heuristics.
- Any attempt at consistency requires copy-pasting color values or writing a custom renderer helper,
  neither of which scales.

### Pull

- **Option A Pull**: One `tag` string per button, one switch in the renderer. Theme changes are
  one-line edits. The "source of truth for appearance" is the renderer, not the 40 call sites.
- **Option B Pull**: Defining a constant `Color` and passing it everywhere achieves consistency
  _if_ all call sites reference the same constant. Possible but fragile (constant drift).

### Anxiety

- **Option B Anxiety**: If a new developer joins the SpaceSim team and adds a button with a
  hard-coded `Color`, the theme silently diverges. There is no enforcement mechanism.
- **Option A Anxiety**: Tag typos produce invisible bugs (button renders as default, not as intended).
  Type safety (enum over string) would eliminate this, but an enum constrains extensibility (Job 3).

### Habit

- Riku already channels all appearance decisions through the renderer for `isFocused`. Extending
  that pattern to a semantic tag is zero new learning.
- Color injection would require a new mental mode: "some appearance lives in the view tree, some
  in the renderer" — a split that increases cognitive load.

---

## Forces for Job 3 — Renderer Extensibility

### Push

- A closed enum for button roles (e.g., `ButtonRole.primary`) would force a library update every
  time a game developer needs a new role.
- Hard-coding a fixed set of roles in GameUI imposes the library author's UX opinions on all users.

### Pull

- **Option A Pull**: `String` tag is infinitely extensible. Any game developer can invent any
  category. Any renderer author can handle any subset. No library updates required.
- **Option B Pull**: No extensibility question arises if colors are injected — the renderer simply
  uses the provided color. But this pushes the burden of extensibility to the call site author,
  not the renderer author.

### Anxiety

- **Option A Anxiety**: Untyped strings require documentation discipline. "What tags does the
  renderer support?" is answered outside the type system.
- **Option B Anxiety**: A renderer that ignores colors silently breaks game developer expectations.
  The renderer contract becomes "I will use your colors" — a promise every renderer must explicitly
  make and keep.

### Habit

- `String` is the least surprising type for an open-ended metadata field. It follows the pattern
  of HTML class attributes, CSS class names, and game engine object tags — widely understood.
- Optional `Color` pairs are unfamiliar as a view-tree metadata mechanism in declarative UI
  frameworks.

---

## Forces Verdict

| Criterion | Option A (Tag) | Option B (Colors) |
|---|---|---|
| Central theming (Job 2) | Strong pull, no anxiety | Weak (call-site scatter risk) |
| Renderer extensibility (Job 3) | Strong pull, minor anxiety (typos) | Eliminates Job 3 entirely |
| Content/appearance separation | Preserves established GameUI philosophy | Breaks it |
| Consistency with `isFocused` pattern | Identical inspection pattern | New pattern; different mental model |
| Habit friction for Riku | Low (same renderer switch pattern) | Medium (split appearance logic) |
| Habit friction for renderer authors | Low (switch on string, like CSS class) | High (must consume colors, handle nil) |

**Conclusion**: Option A (tag/metadata) resolves all three jobs with lower anxiety and lower habit
friction than Option B. Option B solves only Job 1 (simple case) and is actively harmful for
Job 2 and Job 3. A principled combination would be Option A as the primary API, with `tag`
defaulting to an empty string for backwards-compatible rendering.
