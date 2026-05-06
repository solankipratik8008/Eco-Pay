// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EcoPayNetworking",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "EcoPayNetworking",
            targets: ["EcoPayNetworking"]
        ),
    ],
    targets: [
        .target(
            name: "EcoPayNetworking"
        ),
    ]
)
