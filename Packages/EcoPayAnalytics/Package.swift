// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EcoPayAnalytics",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "EcoPayAnalytics",
            targets: ["EcoPayAnalytics"]
        ),
    ],
    targets: [
        .target(
            name: "EcoPayAnalytics"
        ),
    ]
)
