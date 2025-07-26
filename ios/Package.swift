// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "babieta",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "babieta",
            targets: ["babieta"])
    ],
    dependencies: [
        // Removed Supabase dependency - using self-hosted backend instead
    ],
    targets: [
        .target(
            name: "babieta",
            dependencies: [
                // Removed Supabase dependency
            ]
        )
    ]
)
