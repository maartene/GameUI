// RectTests.swift — Unit tests for Rect.contains boundary behavior
// Driving port: Rect.contains(_ point: Point) — pure function, public API

import Testing
@testable import GameUI

@Suite("Rect — contains boundary")
struct RectTests {

    @Test func `Rect contains point on bottom-right boundary (inclusive)`() {
        let rect = Rect(origin: Point(x: 0, y: 0), size: Size(width: 100, height: 100))
        #expect(rect.contains(Point(x: 100, y: 100)) == true)
    }

    @Test func `Point just outside bottom-right boundary is not contained`() {
        let rect = Rect(origin: Point(x: 0, y: 0), size: Size(width: 100, height: 100))
        #expect(rect.contains(Point(x: 100.1, y: 100.1)) == false)
    }
}
