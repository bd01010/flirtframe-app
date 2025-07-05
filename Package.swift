// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FlirtFrame",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "FlirtFrame",
            targets: ["FlirtFrame"]),
    ],
    dependencies: [
        // Firebase
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.20.0"),
    ],
    targets: [
        .target(
            name: "FlirtFrame",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
            ],
            path: "Sources",
            resources: [
                .process("../GoogleService-Info.plist"),
            ]
        ),
        .testTarget(
            name: "FlirtFrameTests",
            dependencies: ["FlirtFrame"],
            path: "Tests"
        ),
    ]
)