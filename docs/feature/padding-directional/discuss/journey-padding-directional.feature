Feature: Directional padding modifier for asymmetric horizontal/vertical insets

  As a game developer using GameUI
  I want to apply different horizontal (x) and vertical (y) padding to any view
  So that I can control layout insets precisely without nesting two padding modifiers

  Background:
    Given the GameUI LayoutEngine is initialised with no textMeasurer

  # ---------------------------------------------------------------------------
  # Happy path: symmetric-looking but axially distinct values
  # ---------------------------------------------------------------------------

  Scenario: Correct outer size with distinct horizontal and vertical padding
    Given a Rectangle view with intrinsic size width 100 and height 50
    And the view is wrapped with .padding(x: 20, y: 10)
    And layout constraints are maxWidth 400 and maxHeight 300
    When LayoutEngine.layout is called with those constraints
    Then the root LayoutNode frame width is 140
    And the root LayoutNode frame height is 70
    And the child LayoutNode frame origin x is 20
    And the child LayoutNode frame origin y is 10

  # ---------------------------------------------------------------------------
  # Zero x-padding: only vertical inset applied
  # ---------------------------------------------------------------------------

  Scenario: Zero horizontal padding leaves width unchanged
    Given a Rectangle view with intrinsic size width 80 and height 40
    And the view is wrapped with .padding(x: 0, y: 10)
    And layout constraints are maxWidth 400 and maxHeight 300
    When LayoutEngine.layout is called with those constraints
    Then the root LayoutNode frame width is 80
    And the root LayoutNode frame height is 60
    And the child LayoutNode frame origin x is 0
    And the child LayoutNode frame origin y is 10

  # ---------------------------------------------------------------------------
  # Zero y-padding: only horizontal inset applied
  # ---------------------------------------------------------------------------

  Scenario: Zero vertical padding leaves height unchanged
    Given a Rectangle view with intrinsic size width 80 and height 40
    And the view is wrapped with .padding(x: 10, y: 0)
    And layout constraints are maxWidth 400 and maxHeight 300
    When LayoutEngine.layout is called with those constraints
    Then the root LayoutNode frame width is 100
    And the root LayoutNode frame height is 40
    And the child LayoutNode frame origin x is 10
    And the child LayoutNode frame origin y is 0

  # ---------------------------------------------------------------------------
  # Constraint clamping: outer size must not exceed available space
  # ---------------------------------------------------------------------------

  Scenario: Outer size is clamped when padding would exceed constraints
    Given a Rectangle view with intrinsic size width 90 and height 90
    And the view is wrapped with .padding(x: 20, y: 20)
    And layout constraints are maxWidth 100 and maxHeight 100
    When LayoutEngine.layout is called with those constraints
    Then the root LayoutNode frame width is at most 100
    And the root LayoutNode frame height is at most 100

  # ---------------------------------------------------------------------------
  # Negative values treated as zero
  # ---------------------------------------------------------------------------

  Scenario: Negative padding values are clamped to zero
    Given a Rectangle view with intrinsic size width 60 and height 40
    And the view is wrapped with .padding(x: -5, y: -10)
    And layout constraints are maxWidth 400 and maxHeight 300
    When LayoutEngine.layout is called with those constraints
    Then the root LayoutNode frame width is 60
    And the root LayoutNode frame height is 40

  # ---------------------------------------------------------------------------
  # Hit-test: button wrapped in directional padding is reachable
  # ---------------------------------------------------------------------------

  Scenario: hitTestButton returns correct index through directional padding
    Given a single Button view with label "Attack"
    And the button is wrapped with .padding(x: 10, y: 5)
    And the layout tree is computed with constraints maxWidth 200 maxHeight 100
    When hitTestButton is called with a point inside the padded button frame
    Then hitTestButton returns the button index 0
    And the button action is not invoked during the traversal

  Scenario: hitTestButton returns nil for a point in the padding band (outside button)
    Given a single Button view with label "Attack"
    And the button is wrapped with .padding(x: 10, y: 5)
    And the layout tree is computed with constraints maxWidth 200 maxHeight 100
    When hitTestButton is called with a point that is outside the outer padded frame entirely
    Then hitTestButton returns nil

  Scenario: hitTestButton reaches a directional-padded button nested inside a VStack
    Given a VStack containing two buttons "Move" and "Attack"
    And the "Attack" button is wrapped with .padding(x: 8, y: 4)
    And the layout tree is computed with constraints maxWidth 200 maxHeight 200
    When hitTestButton is called with a point inside the padded "Attack" button frame
    Then hitTestButton returns the index corresponding to "Attack"
