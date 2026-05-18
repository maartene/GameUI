# JTBD Job Stories — button-styling

## Context

Feature: `button-styling`
Persona: Riku Nakamura — game developer building SpaceSim menus
Design decision under analysis: Tag/metadata vs. color injection for button visual differentiation

No DISCOVER/DIVERGE artifacts exist for this feature. Job stories are derived from the problem statement,
the established `AnyButton` pattern, and the `button-focus-state` precedent.

---

## Job 1: Visually Distinguish Button Types

### Job Story

When I am building a SpaceSim menu that has multiple button roles (primary action, secondary navigation,
dangerous/destructive action), I want to declare a button's role at the call site so my renderer can
draw each role with a distinct visual style, so players immediately understand which button is the
primary action and which buttons are secondary or dangerous without reading button labels.

### Dimensions

**Functional**: Attach a semantic role identifier to each `Button` at construction time. Renderer reads
the identifier and applies role-appropriate colors, borders, or sizing.

**Emotional**: Riku feels confident that the button's meaning is encoded in the view tree, not scattered
across renderer conditionals that reference button text content. The meaning travels with the view.

**Social**: Riku's SpaceSim ships with menus that meet player expectations shaped by AAA game conventions
(green/blue = confirm, red = danger). Riku is seen as a professional who ships polished UIs.

### Example Instances

- "Start Game" button → primary role → rendered with bright accent color, larger font
- "Settings" button → secondary role → rendered with muted tone, normal sizing
- "Quit" button → destructive role → rendered in red/warning palette

---

## Job 2: Apply Consistent Theming Across All Buttons of a Type

### Job Story

When I have 12 menu screens across SpaceSim, all with primary/secondary/destructive buttons, I want
to define visual rules for each button type in one place (my renderer), not at every call site, so I
can change the "primary button" color for all 12 screens by editing one switch statement instead of
hunting through 40 Button declarations.

### Dimensions

**Functional**: The button's semantic category is encoded in the view tree. The renderer owns the
visual mapping from category → colors/style. Call sites declare intent ("this is primary"), renderer
decides appearance ("primary means blue").

**Emotional**: Riku feels liberated from the fear of inconsistency. Changing a theme is a one-line
edit, not a 40-file search-and-replace.

**Social**: Riku's SpaceSim demonstrates design consistency that signals craft and intentionality.
Other developers who adopt GameUI see theming as easy to achieve.

### Example Instances

- Riku changes primary button color from `#4488FF` to `#22CCAA` for a new game chapter → edits
  renderer switch case once → all 12 screens update automatically
- SpaceSim introduces a "Premium" theme with gold-tinted primaries → Riku adds one conditional in the
  renderer, no call-site changes

---

## Job 3: Renderer Inspects Button Metadata Without Knowing All Categories in Advance

### Job Story

When I am writing a generic GameUI renderer that I intend to ship alongside GameUI (or distribute
to other game developers), I want to inspect button metadata without hard-coding an exhaustive list
of semantic categories, so my renderer remains open to new categories game developers invent without
requiring a library update.

### Dimensions

**Functional**: The metadata type must be open/extensible. A `String` tag or a hashable identifier
allows renderer authors to switch on values they document in their own renderer, without GameUI
constraining the set.

**Emotional**: The renderer author feels confident that their renderer will not break when a game
developer declares a new button role. The system is forwards-compatible by construction.

**Social**: GameUI positions itself as a flexible primitive, not an opinionated design system. Third-party
renderer authors (community) trust GameUI to be extensible.

### Example Instances

- SpaceSim adds a "highlighted" category for tutorial buttons → renderer switch gains one new case,
  GameUI library unchanged
- A community renderer author ships a "neon" renderer that handles "primary", "secondary", "accent" →
  game developers using that renderer simply declare `Button(tag: "accent")` without forking GameUI
