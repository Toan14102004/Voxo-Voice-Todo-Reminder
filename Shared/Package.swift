// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "VoxoShared",
    // macOS is listed so `swift test` runs natively, without a simulator.
    platforms: [.iOS(.v16), .watchOS(.v10), .macOS(.v13)],
    products: [
        .library(name: "VoxoShared", targets: ["VoxoShared"]),
        .library(name: "VoxoDesign", targets: ["VoxoDesign"])
    ],
    targets: [
        // No resources: the Core Data model is built in code (see Model/VoxoModel.swift), because
        // SwiftPM's command-line build does not run momc on .xcdatamodeld bundles.
        .target(name: "VoxoShared"),
        // Design tokens and shared SwiftUI components. Kept out of VoxoShared so the logic
        // module stays free of UI, per PLAN.md §2.
        .target(name: "VoxoDesign", dependencies: ["VoxoShared"]),
        .testTarget(name: "VoxoSharedTests", dependencies: ["VoxoShared"])
    ]
)
