// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KstatiModules",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MemoryCore", targets: ["MemoryCore"]),
        .library(name: "MemoryPersistence", targets: ["MemoryPersistence"]),
        .library(name: "MemoryOCR", targets: ["MemoryOCR"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
        .package(url: "https://github.com/swiftlang/swift-testing.git", exact: "6.2.3"),
    ],
    targets: [
        .target(name: "MemoryCore", path: "MemoryCore/Sources"),
        .target(
            name: "MemoryPersistence", dependencies: ["MemoryCore", .product(name: "GRDB", package: "GRDB.swift")],
            path: "MemoryPersistence/Sources"),
        .target(name: "MemoryOCR", dependencies: ["MemoryCore", "MemoryPersistence"], path: "MemoryOCR/Sources"),
        .testTarget(
            name: "MemoryCoreTests", dependencies: ["MemoryCore", .product(name: "Testing", package: "swift-testing")],
            path: "MemoryCore/Tests"),
        .testTarget(
            name: "MemoryPersistenceTests",
            dependencies: ["MemoryPersistence", "MemoryCore", .product(name: "Testing", package: "swift-testing")],
            path: "MemoryPersistence/Tests"),
        .testTarget(
            name: "MemoryOCRTests",
            dependencies: [
                "MemoryOCR", "MemoryPersistence", "MemoryCore", .product(name: "Testing", package: "swift-testing"),
            ], path: "MemoryOCR/Tests"),
    ]
)
