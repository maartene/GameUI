Feature: WrappedText — Render Multi-Line Constrained Text
  As Riku Nakamura, a game developer using GameUI
  I want to declare a WrappedText component that word-wraps automatically
  So that long text in HUD panels, dialogue boxes, and quest logs does not overflow the available area

  Background:
    Given the GameUI LayoutEngine is initialised

  # ── Happy Path ──────────────────────────────────────────────────────────────

  Scenario: Multi-line text splits to fit within constraint width
    Given a LayoutEngine with a textMeasurer that returns width as fontSize * charCount
    And a WrappedText with content "The ancient relic pulses with an eerie blue glow said to grant its bearer visions of the past" fontSize 14 color white
    When layout runs with LayoutConstraints maxWidth 200
    Then the root LayoutNode has 2 or more children
    And no child LayoutNode frame width exceeds 200
    And the first child LayoutNode origin y equals 0

  Scenario: Child LayoutNode y-origins are stacked by lineHeight
    Given a LayoutEngine with a textMeasurer returning height fontSize for each measurement
    And a WrappedText that produces exactly 3 wrapped lines at fontSize 16
    When layout runs with LayoutConstraints maxWidth 200
    Then child node 0 has origin y equal to 0
    And child node 1 has origin y equal to 16
    And child node 2 has origin y equal to 32

  Scenario: Root node frame height equals total stacked line height
    Given a WrappedText that produces 3 wrapped lines each of height 14
    When layout runs with LayoutConstraints maxWidth 200
    Then the root LayoutNode frame height equals 42

  Scenario: Single short text that fits on one line produces exactly one child node
    Given a LayoutEngine with a textMeasurer
    And a WrappedText with content "HP" fontSize 14 color white
    And LayoutConstraints maxWidth 200
    When layout runs
    Then the root LayoutNode has exactly 1 child
    And the child frame width is less than or equal to 200

  # ── Fallback ─────────────────────────────────────────────────────────────────

  Scenario: Word-wrap uses char-count fallback when no measurer injected
    Given a LayoutEngine with no textMeasurer
    And a WrappedText with content "Short text for testing fallback" fontSize 10 color white
    And LayoutConstraints maxWidth 100
    When layout runs
    Then at least 1 child LayoutNode is produced
    And no crash or assertion failure occurs

  # ── Edge Cases ──────────────────────────────────────────────────────────────

  Scenario: Empty content produces zero children and zero-height root
    Given a WrappedText with content "" fontSize 14 color white
    When layout runs with any LayoutConstraints
    Then the root LayoutNode has zero children
    And the root LayoutNode frame height equals 0

  Scenario: Single word wider than maxWidth is placed on its own line without crash
    Given a LayoutEngine with a textMeasurer
    And a WrappedText with content "Superlongitemnamedunbreakable" fontSize 14 color white
    And LayoutConstraints maxWidth 50
    When layout runs
    Then exactly 1 child LayoutNode is produced
    And the layout engine completes without looping or crashing

  Scenario: Near-zero maxWidth places each word on its own line
    Given a LayoutEngine with a textMeasurer
    And a WrappedText with content "Hello world" fontSize 14 color white
    And LayoutConstraints maxWidth 1
    When layout runs
    Then the root LayoutNode has exactly 2 children
    And the layout engine completes without looping or crashing

  Scenario: Multi-word text with near-zero maxWidth and unbreakable words
    Given a LayoutEngine with a textMeasurer
    And a WrappedText with content "Go now" fontSize 14 color white
    And LayoutConstraints maxWidth 1
    When layout runs
    Then the root LayoutNode has exactly 2 children

  # ── Protocol Conformance ────────────────────────────────────────────────────

  Scenario: WrappedText conforms to View protocol with Never body
    Given a WrappedText value is created
    When it is passed to LayoutEngine.layout as a View
    Then the call compiles and produces a LayoutTree

  Scenario: WrappedText carries color and fontSize accessible to renderer
    Given a WrappedText with fontSize 18 and color white
    When the value is pattern-matched in the renderer
    Then fontSize equals 18
    And color equals white
