# SnapshotTestingWatchOS

watchOS image snapshot strategies for Point-Free's
[swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing).

`SnapshotTestingWatchOS` renders SwiftUI views with `ImageRenderer` and compares the resulting
PNG images pixel by pixel. It mirrors the familiar `.image` API from `SnapshotTesting`.

## Requirements

- watchOS 10 or later
- Swift 6.0 or later
- swift-snapshot-testing 1.19.5 or later

## Installation

Add this package to your package dependencies:

```swift
.package(
    url: "https://github.com/PhilLibs/swift-snapshot-testing-watchos",
    branch: "main"
)
```

Then add `SnapshotTestingWatchOS` to your watchOS test target:

```swift
.product(
    name: "SnapshotTestingWatchOS",
    package: "swift-snapshot-testing-watchos"
)
```

## Usage

```swift
import SnapshotTesting
import SnapshotTestingWatchOS
import SwiftUI
import Testing

@Test @MainActor
func scoreView() {
    assertSnapshot(
        of: ScoreView(),
        as: .image(
            layout: .fixed(width: 162, height: 197),
            scale: 2
        )
    )
}
```

The strategy supports fixed and size-to-fit layouts, configurable display scale, and pixel
precision. As with every `ImageRenderer`-based approach, views implemented by native platform
frameworks may not render exactly as they do in a running app.

## Acknowledgments

`SnapshotTestingWatchOS` extends
[Point-Free's swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)
with watchOS support. Its rendering strategy is based on work by
[`choule99`](https://github.com/choule99) in the
[`modern-swift-dev` fork](https://github.com/modern-swift-dev/swift-snapshot-testing/commit/8f760443854897edf08d39da4e0fcff9cd6023c4).

## License

This library is released under the MIT License. See [LICENSE](LICENSE).
