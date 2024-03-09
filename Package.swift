// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PullToRefreshSwiftUI",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "PullToRefreshSwiftUI",
            targets: ["PullToRefreshSwiftUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.4.0")
    ],
    targets: [
        .target(
            name: "PullToRefreshSwiftUI",
            dependencies: [.product(name: "Lottie", package: "lottie-spm")]),
        .testTarget(
            name: "PullToRefreshSwiftUITests",
            dependencies: ["PullToRefreshSwiftUI"]),
    ]
)
