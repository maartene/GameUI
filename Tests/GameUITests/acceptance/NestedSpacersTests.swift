//
//  NestedSpacersTests.swift
//  GameUI
//
//  Created by Engels, Maarten MAK on 21/07/2026.
//

import Testing
@testable import GameUI

@Suite struct NestedSpacersTests {
    struct ExampleView: View {
        var body: some View {
            VStack {
                HStack {
                    Text(content: "Player", fontSize: 20)
                    Spacer()
                    Text(content: "Target", fontSize: 20)
                }
                Spacer()
                HStack {
                    Text(content: "Weapons", fontSize: 20)
                    Spacer()
                    Text(content: "Comms", fontSize: 20)
                }
            }
        }
    }
    
    let layoutEngine = LayoutEngine { string, size in
        Size(width: size * Float(string.count), height: size)
    }
    
    let constraints = LayoutConstraints(maxWidth: 1280, maxHeight: 720)
    
    @Test func `Nested containers with nested spacers have at least one root node`() {
        let view = ExampleView()
        
        let layout = layoutEngine.layout(view, in: constraints)
        
        #expect(layout.root.children.isEmpty == false)
    }
    
    @Test func `Nested containers with spacers respect constraints`() {
        let view = ExampleView()
        
        let layout = layoutEngine.layout(view, in: constraints)
        
        let childFrame = layout.root.children[2].children[2].frame
        #expect(childFrame.size.width + childFrame.origin.x <= constraints.maxWidth)
        #expect(childFrame.size.height + childFrame.origin.y  <= constraints.maxHeight)
    }
}
