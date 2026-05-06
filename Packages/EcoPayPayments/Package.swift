// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EcoPayPayments",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "EcoPayPayments",
            targets: ["EcoPayPayments"]
        ),
    ],
    dependencies: [
        .package(path: "../EcoPayNetworking")
    ],
    targets: [
        .target(
            name: "EcoPayPayments",
            dependencies: ["EcoPayNetworking"]
        ),
    ]
)
