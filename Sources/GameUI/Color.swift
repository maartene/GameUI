// Color.swift — Domain color type for GameUI.
// No raylib import — maps to raylib.Color in GameUIRaylibRenderer at render time.

public struct Color: Equatable, Sendable {
    public let r: UInt8
    public let g: UInt8
    public let b: UInt8
    public let a: UInt8

    public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    public static let white     = Color(r: 255, g: 255, b: 255)
    public static let black     = Color(r: 0,   g: 0,   b: 0)
    public static let darkGray  = Color(r: 80,  g: 80,  b: 80)
    public static let gray      = Color(r: 130, g: 130, b: 130)
    public static let lightGray = Color(r: 200, g: 200, b: 200)
    public static let red       = Color(r: 214, g:  76, b:  70)
    public static let green     = Color(r:  96, g: 186, b: 112)
    public static let blue      = Color(r:  80, g: 112, b: 196)
    public static let yellow    = Color(r: 232, g: 214, b:  96)
    public static let clear     = Color(r: 0,   g: 0,   b: 0,   a: 0)
    public static let orange    = Color(r: 224, g: 148, b:  62)
    public static let gold      = Color(r: 220, g: 178, b:  70)
    public static let skyBlue   = Color(r: 118, g: 178, b: 222)
    public static let softGrey  = Color(r: 150, g: 150, b: 150)
}
