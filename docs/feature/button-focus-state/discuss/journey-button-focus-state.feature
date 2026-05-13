Feature: Button Focus State
  As a game developer using GameUI
  I want Button to carry an isFocused flag
  So that my renderer can visually distinguish the focused button for gamepad/keyboard players

  Background:
    Given the GameUI library is available
    And no GUIContext changes are made

  # --- Happy Path ---

  Scenario: isFocused: true produces a focused node in the view tree
    Given a Button constructed with isFocused: true
    When the view tree is evaluated
    Then the Button carries isFocused == true

  Scenario: isFocused defaults to false — existing call sites unchanged
    Given a Button constructed without isFocused
    When the view tree is evaluated
    Then the Button carries isFocused == false

  Scenario: Multiple buttons — only the focused one carries isFocused == true
    Given three Buttons, the second constructed with isFocused: true
    And the first and third constructed without isFocused
    When the view tree is evaluated
    Then exactly one Button carries isFocused == true
    And that Button is the second one

  # --- Safety Scenarios ---

  Scenario: Focus flag does not fire the action
    Given a Button constructed with isFocused: true
    When the view tree is evaluated
    Then the action has not been invoked

  Scenario: Action fires only when the consumer calls it
    Given a Button constructed with isFocused: true
    When the consumer explicitly invokes the action
    Then it fires exactly once

  # --- Error Path ---

  Scenario: Renderer can inspect isFocused without a Raylib window
    Given a Button constructed with isFocused: true
    When isFocused is read from the Button value
    Then isFocused == true without any rendering context
