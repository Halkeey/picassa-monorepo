// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Picassa",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Picassa",
            targets: ["Picassa"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.19.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.5.0")
    ],
    targets: [
        .target(
            name: "Picassa",
            dependencies: [
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestoreSwift", package: "firebase-ios-sdk"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "."
        )
    ]
) 