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
        // Firebase - using the official package name
        .package(
            name: "Firebase",
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            .upToNextMajor(from: "10.20.0")
        ),
    ],
    targets: [
        .target(
            name: "FlirtFrame",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "Firebase"),
                .product(name: "FirebaseAuth", package: "Firebase"),
                .product(name: "FirebaseFirestore", package: "Firebase"),
                .product(name: "FirebaseStorage", package: "Firebase"),
                .product(name: "FirebaseCrashlytics", package: "Firebase"),
                .product(name: "FirebasePerformance", package: "Firebase"),
                .product(name: "FirebaseRemoteConfig", package: "Firebase"),
            ],
            path: "Sources",
            resources: [
                .process("../GoogleService-Info.plist"),
                .process("../Assets.xcassets")
            ],
            swiftSettings: [
                .unsafeFlags(["-suppress-warnings"])
            ],
            linkerSettings: [
                .unsafeFlags(["-ObjC"])
            ]
        ),
        .testTarget(
            name: "FlirtFrameTests",
            dependencies: ["FlirtFrame"],
            path: "Tests"
        ),
    ]
)