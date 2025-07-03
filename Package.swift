// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BudClient",
    platforms: [.macOS(.v15), .iOS(.v18)],
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
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            .upToNextMajor(from: "11.0.0")
        ),
        .package(
          url: "https://github.com/apple/swift-collections.git",
          .upToNextMinor(from: "1.2.0")
        )
    ],
    targets: [
        // MARK: BudClient
        .target(
            name: "BudClient",
            dependencies: [
                "BudServer", "Tools", "BudCache",
                .product(name: "Collections", package: "swift-collections")
            ]
        ),
        .testTarget(
            name: "BudClientTests",
            dependencies: ["BudClient", "BudServer", "Tools", "BudCache"]
        ),
        
        
        // MARK: BudServer
        .target(
            name: "BudServer",
            dependencies: [
                "Tools",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "Collections", package: "swift-collections")
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
                "Tools", "BudServer"
            ]
        ),
        
        
        // MARK: Tools
        .target(
            name: "Tools")
    ]
)

