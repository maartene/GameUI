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
    
    @Test func `Nested contains with nested spacers have at least one root node`() {
        let view = ExampleView()
        
        let layout = layoutEngine.layout(view, in: constraints)
        
        #expect(layout.root.children.isEmpty == false)
    }
}
