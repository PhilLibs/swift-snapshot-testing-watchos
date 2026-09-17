#if os(watchOS)
    import SnapshotTesting
    @testable import SnapshotTestingWatchOS
    import SwiftUI
    import Testing
    import UIKit

    struct SnapshotTestingWatchOSTests {
        @Test("Renders a fixed layout at the requested scale")
        @MainActor
        func rendersFixedLayoutAtRequestedScale() async {
            // GIVEN
            let strategy = Snapshotting<Color, UIImage>.image(
                layout: .fixed(width: 20, height: 30),
                scale: 2
            )

            // WHEN
            let image = await snapshot(Color.red, using: strategy)

            // THEN
            #expect(image.size == CGSize(width: 20, height: 30))
            #expect(image.cgImage?.width == 40)
            #expect(image.cgImage?.height == 60)
        }

        @Test("Accepts identical images")
        @MainActor
        func acceptsIdenticalImages() async {
            // GIVEN
            let strategy = Snapshotting<Color, UIImage>.image(
                layout: .fixed(width: 10, height: 10)
            )
            let image = await snapshot(Color.red, using: strategy)

            // WHEN
            let difference = strategy.diffing.diffV2(image, image)

            // THEN
            #expect(difference == nil)
        }

        @Test("Reports changed pixels")
        @MainActor
        func reportsChangedPixels() async {
            // GIVEN
            let strategy = Snapshotting<Color, UIImage>.image(
                layout: .fixed(width: 10, height: 10)
            )
            let reference = await snapshot(Color.red, using: strategy)
            let current = await snapshot(Color.blue, using: strategy)

            // WHEN
            let difference = strategy.diffing.diffV2(reference, current)

            // THEN
            #expect(difference != nil)
            #expect(difference?.1.count == 2)
        }

        @MainActor
        private func snapshot<Value>(
            _ value: Value,
            using strategy: Snapshotting<Value, UIImage>
        ) async -> UIImage {
            await withCheckedContinuation { continuation in
                strategy.snapshot(value).run { image in
                    continuation.resume(returning: image)
                }
            }
        }
    }
#endif
