// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JUNSwiftUI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "JUNSwiftUI",
            targets: ["JUNSwiftUI"]
        )
    ],
    targets: [
        .target(
            name: "JUNSwiftUI",
            dependencies: [],
            path: "Sources/JUNSwiftUI"
        ),
        .testTarget(
            name: "JUNSwiftUITests",
            dependencies: ["JUNSwiftUI"],
            path: "Tests/JUNSwiftUITests"
        )
    ]
)
