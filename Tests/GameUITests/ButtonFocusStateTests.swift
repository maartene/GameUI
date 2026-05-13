// ButtonFocusStateTests.swift — Acceptance tests for button-focus-state feature
// Step 01-01: isFocused property on AnyButton protocol and Button<Content> struct
// Test Budget: 5 behaviors x 2 = 10 unit tests max; 5 acceptance tests used.

import Testing
@testable import GameUI

@Suite("Button focus state")
struct ButtonFocusStateTests {

    // AC1: Given a Button constructed with isFocused: true,
    //      when the view tree is evaluated,
    //      then the Button carries isFocused == true
    @Test("Button constructed with isFocused true carries isFocused == true")
    func buttonConstructedWithIsFocusedTrueCarriesTrue() {
        let button = Button(isFocused: true, action: {}) { Rectangle() }
        #expect(button.isFocused == true)
    }

    // AC2: Given a Button constructed without isFocused,
    //      when the view tree is evaluated,
    //      then the Button carries isFocused == false
    @Test("Button constructed without isFocused defaults to isFocused == false")
    func buttonConstructedWithoutIsFocusedDefaultsToFalse() {
        let button = Button(action: {}) { Rectangle() }
        #expect(button.isFocused == false)
    }

    // AC3: Given a Button constructed with isFocused: true,
    //      when the view tree is evaluated,
    //      then the action has not been invoked
    @Test("Button constructed with isFocused true does not auto-invoke action")
    func buttonConstructedWithIsFocusedTrueDoesNotAutoInvokeAction() {
        nonisolated(unsafe) var callCount = 0
        let button = Button(isFocused: true, action: { callCount += 1 }) { Rectangle() }
        _ = button
        #expect(callCount == 0)
    }

    // AC4: Given a Button with isFocused: true,
    //      when the consumer explicitly invokes the action,
    //      then it fires exactly once
    @Test("Button with isFocused true fires action exactly once when explicitly invoked")
    func buttonWithIsFocusedTrueFiresActionExactlyOnceWhenInvoked() {
        nonisolated(unsafe) var callCount = 0
        let button = Button(isFocused: true, action: { callCount += 1 }) { Rectangle() }
        button.anyAction()
        #expect(callCount == 1)
    }

    // AC5: Given three Buttons where the second has isFocused: true,
    //      when the view tree is evaluated,
    //      then exactly one Button carries isFocused == true and it is the second one
    @Test("Exactly one button carries isFocused == true and it is the second of three")
    func exactlyOneButtonCarriesFocusedAndItIsSecond() {
        let first = Button(action: {}) { Rectangle() }
        let second = Button(isFocused: true, action: {}) { Rectangle() }
        let third = Button(action: {}) { Rectangle() }

        let buttons: [any AnyButton] = [first, second, third]
        let focusedCount = buttons.filter { $0.isFocused }.count
        #expect(focusedCount == 1)
        #expect(buttons[1].isFocused == true)
        #expect(buttons[0].isFocused == false)
        #expect(buttons[2].isFocused == false)
    }
}
