// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "GameUI",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "GameUI", targets: ["GameUI"])
    ],
    targets: [
        .target(
            name: "GameUI"
        ),
        .testTarget(
            name: "GameUITests",
            dependencies: ["GameUI"]
        )
    ],
    swiftLanguageModes: [.v6]
)
