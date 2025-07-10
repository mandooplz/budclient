// swift-tools-version: 6.2
// The swift-Values-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BudClient",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        // MARK: BudClient
        .library(
            name: "BudClient",
            targets: ["BudClient"]
        ),
        
        // MARK: Values
        .library(
            name: "Values",
            targets: ["Values"]
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
                "Values",
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
                "Values",
                "BudCache"]
        ),
        
        
        // MARK: BudServer
        .target(
            name: "BudServer",
            dependencies: [
                "Values",
                "BudServerLocal",
                "BudServerMock",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
            ]
        ),
        
        // MARK: BudServerLocal
        .target(
            name: "BudServerLocal",
            dependencies: [
                "Values",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "Collections", package: "swift-collections")
            ]
        ),
        
        
        // MARK: BudServerMock
        .target(
            name: "BudServerMock",
            dependencies: [
                "Values",
                .product(name: "Collections", package: "swift-collections")
            ]
        ),
        .testTarget(
            name: "BudServerMockTests",
            dependencies: ["Values", "BudServerMock"]
        ),
        
        
        // MARK: BudCache
        .target(
            name: "BudCache",
            dependencies: [
                "Values", "BudServer"
            ]
        ),
        
        
        // MARK: Values
        .target(
            name: "Values",
            dependencies: [
                .product(name: "Collections", package: "swift-collections")
            ]
        )
    ]
)

