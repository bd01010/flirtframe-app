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
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0")
    ],
    targets: [
        .target(
            name: "FlirtFrame",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
                .product(name: "FirebasePerformance", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "FlirtFrameTests",
            dependencies: ["FlirtFrame"],
            path: "Tests"
        ),
    ]
)