// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EcoPayAuthKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "EcoPayAuthKit",
            targets: ["EcoPayAuthKit"]
        ),
    ],
    dependencies: [
        // EcoPayAuthKit depends on EcoPayNetworking for API calls
        .package(path: "../EcoPayNetworking")
    ],
    targets: [
        .target(
            name: "EcoPayAuthKit",
            dependencies: ["EcoPayNetworking"]
        ),
    ]
)
