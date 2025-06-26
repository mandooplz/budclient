// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BudClient",
    platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18)],
    products: [
        // MARK: BudClient
        .library(
            name: "BudClient",
            targets: ["BudClient"]
        ),
        
        // MARK: BudServerLink
        .library(
            name: "BudServer",
            targets: ["BudServer"]
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
            dependencies: ["BudServer", "Tools"]
        ),
        .testTarget(
            name: "BudClientTests",
            dependencies: ["BudClient", "BudServer", "Tools"]
        ),
        
        
        // MARK: BudServerLink
        .target(
            name: "BudServer",
            dependencies: [
                "Tools",
                "BudServerMock",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ]
        ),
        .testTarget(
            name: "BudServerTests",
            dependencies: ["Tools", "BudServer"]
        ),
        
        // MARK: BudServerMock
        .target(
            name: "BudServerMock",
            dependencies: ["Tools"]
        ),
        .testTarget(
            name: "BudServerMockTests",
            dependencies: ["Tools", "BudServerMock"]
        ),
        
        
        // MARK: Tools
        .target(
            name: "Tools")
    ]
)

