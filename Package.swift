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
        
        // MARK: BudServer
        .library(
            name: "BudServer",
            targets: ["BudServer"]
        ),
        
        // MARK: BudCache
        .library(
            name: "BudCache",
            targets: ["BudCache"]
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
        
        
        // MARK: BudServer
        .target(
            name: "BudServer",
            dependencies: [
                "Tools",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ]
        ),
        .testTarget(
            name: "BudServerTests",
            dependencies: ["Tools", "BudServer"]
        ),
        
        
        // MARK: BudCache
        .target(
            name: "BudCache",
            dependencies: [
                "Tools"
            ]
        ),
        .testTarget(
            name: "BudCacheTests",
            dependencies: [
                "BudCache", "Tools",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
            ]
        ),
        
        
        // MARK: Tools
        .target(
            name: "Tools")
    ]
)

