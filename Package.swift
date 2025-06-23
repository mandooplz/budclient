// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BudClient",
    products: [
        // MARK: BudClient
        .library(
            name: "BudClient",
            targets: ["BudClient"]
        ),
        
        // MARK: BudServer
        .library(
            name: "BudServer",
            targets: ["BudServer"]
        ),
        
        // MARK: Tools
        .library(
            name: "Tools",
            targets: ["Tools"]
        )
    ],
    targets: [
        // MARK: BudClient
        .target(
            name: "BudClient"
        ),
        .testTarget(
            name: "BudClientTests",
            dependencies: ["BudClient"]
        ),
        
        
        // MARK: BudServer
        .target(
            name: "BudServer"
        ),
        .testTarget(
            name: "BudServerTests"
        ),
        
        
        // MARK: Tools
        .target(
            name: "Tools")
    ]
)
