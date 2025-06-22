// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BudClient",
    products: [
        .library(
            name: "BudClient",
            targets: ["BudClient"]
        ),
    ],
    targets: [
        .target(
            name: "BudClient"
        ),
        .testTarget(
            name: "BudClientTests",
            dependencies: ["BudClient"]
        ),
    ]
)
