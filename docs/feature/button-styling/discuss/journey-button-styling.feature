Feature: Button Styling via Semantic Tag
  As Riku Nakamura, a game developer building SpaceSim menus,
  I want to declare a semantic role for each button at the call site
  So that my renderer can apply role-appropriate visual styles without per-screen duplication

  Background:
    Given GameUI is a Swift 6.2 library with no Foundation import
    And AnyButton is a protocol with anyContent, anyAction, and isFocused properties
    And Button<Content> is a struct that conforms to AnyButton

  # ---------------------------------------------------------------------------
  # HAPPY PATH — Core tag declaration and renderer inspection
  # ---------------------------------------------------------------------------

  Scenario: Button constructed with primary tag carries tag property
    Given Riku declares a Button with tag "primary"
    When the Button struct is initialised
    Then the button's tag property equals "primary"
    And the button conforms to AnyButton
    And the tag is accessible via the AnyButton protocol

  Scenario: Button constructed without tag argument uses empty string default
    Given Riku declares a Button without specifying a tag argument
    When the Button struct is initialised
    Then the button's tag property equals ""
    And existing Button call sites require no code change

  Scenario: Tag has no effect on layout geometry
    Given a Button with tag "primary" and a Button with tag "" are declared with identical content
    When both buttons are laid out with identical LayoutConstraints
    Then both LayoutNodes have identical frame width
    And both LayoutNodes have identical frame height

  Scenario: Renderer reads tag from AnyButton cast to differentiate button roles
    Given a view hierarchy containing one Button with tag "primary" and one Button with tag "secondary"
    And a LayoutTree produced from that view
    When the renderer casts each leaf view to AnyButton
    Then the first button's tag equals "primary"
    And the second button's tag equals "secondary"
    And the renderer can apply distinct draw parameters to each without inspecting button text content

  Scenario: isFocused and tag are independent — both are readable simultaneously
    Given a Button constructed with tag "primary" and isFocused true
    When the button is cast to AnyButton
    Then the button's tag equals "primary"
    And the button's isFocused equals true
    And neither property affects the other

  # ---------------------------------------------------------------------------
  # ERROR PATH — Missing tag and unrecognised tag
  # ---------------------------------------------------------------------------

  Scenario: Renderer handles unrecognised tag without crashing
    Given a Button with tag "custom-role" that is not in the renderer's switch statement
    When the renderer casts the view to AnyButton and reads the tag
    Then the tag value "custom-role" is returned without error
    And the renderer's default case can handle any unrecognised tag string

  Scenario: Legacy button with no tag argument is layout-compatible with tagged buttons
    Given a VStack containing one Button(tag: "primary") and one legacy Button() without tag
    When the VStack is laid out
    Then the layout completes without error
    And both buttons appear in the resulting LayoutTree
    And the legacy button's tag is accessible as ""
