import Testing
@testable import GameUI

@Suite("Button focus state")
struct ButtonFocusStateTests {

    @Test func `Button constructed with isFocused true carries isFocused == true`() {
        let button = Button(isFocused: true, action: {}) { Rectangle() }
        #expect(button.isFocused == true)
    }

    @Test func `Button constructed without isFocused defaults to isFocused == false`() {
        let button = Button(action: {}) { Rectangle() }
        #expect(button.isFocused == false)
    }

    @Test func `Button constructed with isFocused true does not auto-invoke action`() {
        nonisolated(unsafe) var callCount = 0
        let button = Button(isFocused: true, action: { callCount += 1 }) { Rectangle() }
        _ = button
        #expect(callCount == 0)
    }

    @Test func `Button with isFocused true fires action exactly once when explicitly invoked`() {
        nonisolated(unsafe) var callCount = 0
        let button = Button(isFocused: true, action: { callCount += 1 }) { Rectangle() }
        button.anyAction()
        #expect(callCount == 1)
    }

    @Test func `Exactly one button carries isFocused == true and it is the second of three`() {
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
