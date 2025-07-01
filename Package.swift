// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FlirtFrame",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "FlirtFrame",
            targets: ["FlirtFrame"]
        ),
    ],
    targets: [
        .target(
            name: "FlirtFrame",
            path: "Sources"
        ),
        .testTarget(
            name: "FlirtFrameTests",
            dependencies: ["FlirtFrame"],
            path: "Tests"
        ),
    ]
)