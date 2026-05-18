// ButtonTagTests.swift — Acceptance tests for tag: String on AnyButton and Button
// Feature: button-styling | Step: 01-01
// Scenario: Button constructed with tag "primary" carries tag == "primary"
//
// Driving ports:
//   Button<Content> init        — public initialiser (driving port for constructor tests)
//   AnyButton protocol          — existential access port
//   LayoutEngine.layout(_:in:)  — public method on LayoutEngine (geometry orthogonality)
//   AnyDirectionalPaddingModifier.paddingContent — traversal port
//   ContainerView.containerChildren             — traversal port

import Testing
@testable import GameUI

// MARK: - AC1 & AC2: Constructor — explicit tag stored and default tag

@Suite("Button Tag — Constructor (AC1, AC2)")
struct ButtonTagConstructorTests {

    @Test func `Button constructed with tag "primary" carries tag == "primary"`() {
        let button = Button(tag: "primary", action: {}) { Rectangle() }

        #expect(button.tag == "primary")
    }

    @Test func `Button constructed without tag carries tag == ""`() {
        let button = Button(action: {}) { Rectangle() }

        #expect(button.tag == "")
    }
}

// MARK: - AC3: Protocol existential access

@Suite("Button Tag — AnyButton Protocol Access (AC3)")
struct ButtonTagProtocolTests {

    @Test func `tag is readable via AnyButton existential for button with tag "primary"`() {
        let button = Button(tag: "primary", action: {}) { Rectangle() }
        let anyButton = button as? any AnyButton

        #expect(anyButton?.tag == "primary")
    }
}

// MARK: - AC4: Tag has no effect on layout geometry

@Suite("Button Tag — Layout Geometry Orthogonality (AC4)")
struct ButtonTagLayoutOrthogonalityTests {

    @Test func `Button with tag "primary" and button with tag "" produce identical layout frames`() {
        let constraints = LayoutConstraints(maxWidth: 200, maxHeight: 100)

        let taggedButton = Button(tag: "primary", action: {}) {
            Rectangle().frame(width: 80, height: 40)
        }
        let untaggedButton = Button(tag: "", action: {}) {
            Rectangle().frame(width: 80, height: 40)
        }

        let taggedTree = LayoutEngine().layout(taggedButton, in: constraints)
        let untaggedTree = LayoutEngine().layout(untaggedButton, in: constraints)

        #expect(taggedTree.root.frame.size.width == untaggedTree.root.frame.size.width)
        #expect(taggedTree.root.frame.size.height == untaggedTree.root.frame.size.height)
        #expect(taggedTree.root.frame.origin.x == untaggedTree.root.frame.origin.x)
        #expect(taggedTree.root.frame.origin.y == untaggedTree.root.frame.origin.y)
    }
}

// MARK: - AC5: Tag and isFocused are orthogonal

@Suite("Button Tag — Orthogonality with isFocused (AC5)")
struct ButtonTagOrthogonalityTests {

    @Test func `Button with tag "primary" and isFocused true stores both properties independently`() {
        let button = Button(tag: "primary", isFocused: true, action: {}) { Rectangle() }

        #expect(button.tag == "primary")
        #expect(button.isFocused == true)
    }
}

// MARK: - AC6 & AC7: Tag survives PaddingModifier and DirectionalPaddingModifier wrapping

@Suite("Button Tag — Traversal Through Padding Modifiers (AC6, AC7)")
struct ButtonTagPaddingTraversalTests {

    @Test func `tag survives wrapping in PaddingModifier — paddingContent as AnyButton yields tag "destructive"`() {
        let paddedView = Button(tag: "destructive", action: {}) { Rectangle() }
            .padding(10)

        let anyPadding = paddedView as? any AnyDirectionalPaddingModifier
        let innerButton = anyPadding?.paddingContent as? any AnyButton

        #expect(innerButton?.tag == "destructive")
    }

    @Test func `tag survives wrapping in DirectionalPaddingModifier — paddingContent as AnyButton yields tag "secondary"`() {
        let paddedView = Button(tag: "secondary", action: {}) { Rectangle() }
            .padding(x: 8, y: 4)

        let anyPadding = paddedView as? any AnyDirectionalPaddingModifier
        let innerButton = anyPadding?.paddingContent as? any AnyButton

        #expect(innerButton?.tag == "secondary")
    }
}

// MARK: - AC doc comment: Open-ended contract — any String value is valid

@Suite("Button Tag — Open-Ended Contract (doc comment AC)")
struct ButtonTagOpenEndedContractTests {

    @Test func `Button constructed with custom tag "custom-value" carries tag == "custom-value"`() {
        let button = Button(tag: "custom-value", action: {}) { Rectangle() }

        #expect(button.tag == "custom-value")
    }
}

// MARK: - AC8: Tag accessible via ContainerView traversal

@Suite("Button Tag — ContainerView Traversal (AC8)")
struct ButtonTagContainerTraversalTests {

    @Test func `VStack containerChildren cast to AnyButton yields tags ["primary", "secondary"] in order`() {
        let stack = VStack {
            Button(tag: "primary", action: {}) { Rectangle() }
            Button(tag: "secondary", action: {}) { Rectangle() }
        }

        let container = stack as? any ContainerView
        let tags = container?.containerChildren.compactMap { ($0 as? any AnyButton)?.tag }

        #expect(tags == ["primary", "secondary"])
    }
}
