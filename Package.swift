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
          .upToNextMinor(from: "1.0.4")
        )
    ],
    targets: [
        // MARK: BudClient
        .target(
            name: "BudClient",
            dependencies: [
                "Tools",
                "BudServer", "BudServerMock",
                "BudCache",
                .product(name: "Collections", package: "swift-collections")
            ]
        ),
        .testTarget(
            name: "BudClientTests",
            dependencies: [
                "BudClient",
                "BudServer", "BudServerMock",
                "Tools",
                "BudCache"]
        ),
        
        
        // MARK: BudServer
        .target(
            name: "BudServer",
            dependencies: [
                "Tools",
                "BudServerMock",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "Collections", package: "swift-collections")
            ]
        ),
        
        
        // MARK: BudServerMock
        .target(
            name: "BudServerMock",
            dependencies: [
                "Tools",
                .product(name: "Collections", package: "swift-collections")
            ]
        ),
        .testTarget(
            name: "BudServerMockTests",
            dependencies: ["Tools", "BudServerMock"]
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
            name: "Tools",
            dependencies: [
                .product(name: "Collections", package: "swift-collections")
            ]
        )
    ]
)

