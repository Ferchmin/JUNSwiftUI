// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JSONToSwiftUI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "JSONToSwiftUI",
            targets: ["JSONToSwiftUI"]
        )
    ],
    targets: [
        .target(
            name: "JSONToSwiftUI",
            dependencies: [],
            path: "Sources/JSONToSwiftUI"
        ),
        .testTarget(
            name: "JSONToSwiftUITests",
            dependencies: ["JSONToSwiftUI"],
            path: "Tests/JSONToSwiftUITests"
        )
    ]
)
