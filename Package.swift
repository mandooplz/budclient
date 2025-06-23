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
        
        // MARK: BudServerLink
        .library(
            name: "BudServerLink",
            targets: ["BudServerLink"]
        ),
        
        // MARK: BudServerMock
        .library(
            name: "BudServerMock",
            targets: ["BudServerMock"]
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
            dependencies: ["BudServerLink", "Tools"]
        ),
        .testTarget(
            name: "BudClientTests",
            dependencies: ["BudClient", "Tools"]
        ),
        
        
        // MARK: BudServerLink
        .target(
            name: "BudServerLink",
            dependencies: [
                "Tools",
                "BudServerMock",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
            ],
            resources: [
                .process("GoogleService-Info.plist")
            ]
        ),
        .testTarget(
            name: "BudServerLinkTests",
            dependencies: ["Tools", "BudServerLink"]
        ),
        
        // MARK: BudServerMock
        .target(
            name: "BudServerMock",
            dependencies: ["Tools"]
        ),
        .testTarget(
            name: "BudServerMockTests",
            dependencies: ["Tools"]
        ),
        
        
        // MARK: Tools
        .target(
            name: "Tools")
    ]
)

