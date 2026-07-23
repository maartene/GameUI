// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "GameUI",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "GameUI", targets: ["GameUI"]),
        // GameUITesting is a plain .target with a .library product, never a .testTarget:
        // only a plain target produces something a downstream *test* target can import.
        // It is shipped code and is bound by every § Technology Constraints rule. See ADR-006.
        .library(name: "GameUITesting", targets: ["GameUITesting"]),
    ],
    targets: [
        .target(
            name: "GameUI"
        ),
        .target(
            name: "GameUITesting",
            dependencies: ["GameUI"]
        ),
        .testTarget(
            name: "GameUITests",
            dependencies: ["GameUI", "GameUITesting"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
