// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-snapshot-testing-watchos",
    platforms: [
        .watchOS(.v10),
    ],
    products: [
        .library(
            name: "SnapshotTestingWatchOS",
            targets: ["SnapshotTestingWatchOS"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            from: "1.19.5"
        ),
    ],
    targets: [
        .target(
            name: "SnapshotTestingWatchOS",
            dependencies: [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
        .testTarget(
            name: "SnapshotTestingWatchOSTests",
            dependencies: [
                "SnapshotTestingWatchOS",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
    ]
)
