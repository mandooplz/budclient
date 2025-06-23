// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BudClient",
    platforms: [.macOS(.v15)],
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
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.24.0")
    ],
    targets: [
        // MARK: BudClient
        .target(
            name: "BudClient",
            dependencies: ["BudServer", "Tools"]
        ),
        .testTarget(
            name: "BudClientTests",
            dependencies: ["BudClient", "Tools"]
        ),
        
        
        // MARK: BudServer
        .target(
            name: "BudServer",
            dependencies: [
                "Tools",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
            ],
            resources: [
                .process("GoogleService-Info.plist")
            ]
        ),
        .testTarget(
            name: "BudServerTests",
            dependencies: ["Tools", "BudServer"]
        ),
        
        .target(
            name: "BudServerMock"
        ),
        
        
        
        // MARK: Tools
        .target(
            name: "Tools")
    ]
)

