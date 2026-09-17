#if os(watchOS)
    import CoreGraphics
    import SnapshotTesting
    import SwiftUI
    import UIKit

    @available(watchOS 10.0, *)
    @MainActor
    public extension Snapshotting where Value: SwiftUI.View, Format == UIImage {
        /// A snapshot strategy for comparing SwiftUI views rendered on watchOS.
        static var image: Snapshotting {
            .image()
        }

        /// A snapshot strategy for comparing SwiftUI views rendered on watchOS.
        ///
        /// - Parameters:
        ///   - precision: The fraction of pixels that must match, from `0` through `1`.
        ///   - layout: The size constraint applied to the rendered view.
        ///   - scale: The number of pixels per point in the rendered image.
        static func image(
            precision: Float = 1,
            layout: SwiftUISnapshotLayout = .sizeThatFits,
            scale: CGFloat = 1
        ) -> Snapshotting {
            precondition((0 ... 1).contains(precision), "precision must be between 0 and 1")
            precondition(scale > 0, "scale must be greater than zero")

            return Snapshotting(
                pathExtension: "png",
                diffing: .image(precision: precision, scale: scale)
            ) { view in
                let renderer = ImageRenderer(
                    content: WatchSnapshottingView(layout: layout, content: view)
                )
                renderer.scale = scale

                guard let image = renderer.uiImage else {
                    preconditionFailure("Could not render the SwiftUI view as an image.")
                }
                return image
            }
        }
    }

    @available(watchOS 10.0, *)
    @MainActor
    public extension Diffing where Value == UIImage {
        /// A pixel-diffing strategy for images rendered on watchOS.
        static var image: Diffing {
            .image()
        }

        /// A pixel-diffing strategy for images rendered on watchOS.
        ///
        /// - Parameters:
        ///   - precision: The fraction of pixels that must match, from `0` through `1`.
        ///   - scale: The scale used when decoding a reference image.
        static func image(
            precision: Float = 1,
            scale: CGFloat = 1
        ) -> Diffing {
            precondition((0 ... 1).contains(precision), "precision must be between 0 and 1")
            precondition(scale > 0, "scale must be greater than zero")

            return .diff(
                toData: pngData,
                fromData: { data in
                    guard let image = UIImage(data: data, scale: scale) else {
                        preconditionFailure("Could not decode the reference PNG image.")
                    }
                    return image
                },
                diffV2: { reference, current in
                    compare(reference: reference, current: current, precision: precision)
                }
            )
        }
    }

    @available(watchOS 10.0, *)
    private struct WatchSnapshottingView<Content: SwiftUI.View>: SwiftUI.View {
        let layout: SwiftUISnapshotLayout
        let content: Content

        var body: some SwiftUI.View {
            switch layout {
            case let .fixed(width, height):
                content.frame(width: width, height: height)
            case .sizeThatFits:
                content
            }
        }
    }

    @MainActor
    private func pngData(_ image: UIImage) -> Data {
        guard let data = image.pngData() else {
            preconditionFailure("Could not encode the snapshot as PNG data.")
        }
        return data
    }

    @MainActor
    private func compare(
        reference: UIImage,
        current: UIImage,
        precision: Float
    ) -> (String, [DiffAttachment])? {
        guard
            let referencePixels = PixelBuffer(image: reference),
            let currentPixels = PixelBuffer(image: current)
        else {
            return failure(
                "Could not read image pixel data.",
                reference: reference,
                current: current
            )
        }

        guard
            referencePixels.width == currentPixels.width,
            referencePixels.height == currentPixels.height
        else {
            return failure(
                "Snapshot dimensions changed from \(referencePixels.width)×\(referencePixels.height) to \(currentPixels.width)×\(currentPixels.height).",
                reference: reference,
                current: current
            )
        }

        let pixelCount = referencePixels.width * referencePixels.height
        guard pixelCount > 0 else { return nil }

        var differentPixelCount = 0
        for pixelIndex in 0 ..< pixelCount {
            let byteIndex = pixelIndex * PixelBuffer.bytesPerPixel
            let range = byteIndex ..< (byteIndex + PixelBuffer.bytesPerPixel)
            if referencePixels.bytes[range] != currentPixels.bytes[range] {
                differentPixelCount += 1
            }
        }

        let actualPrecision = 1 - Float(differentPixelCount) / Float(pixelCount)
        guard actualPrecision < precision else { return nil }

        return failure(
            "Actual pixel precision \(actualPrecision) is less than required precision \(precision).",
            reference: reference,
            current: current
        )
    }

    @MainActor
    private func failure(
        _ message: String,
        reference: UIImage,
        current: UIImage
    ) -> (String, [DiffAttachment]) {
        (
            message,
            [
                .data(pngData(reference), name: "reference.png"),
                .data(pngData(current), name: "failure.png"),
            ]
        )
    }

    private struct PixelBuffer {
        static let bytesPerPixel = 4

        let width: Int
        let height: Int
        let bytes: [UInt8]

        init?(image: UIImage) {
            guard let source = image.cgImage else { return nil }

            let width = source.width
            let height = source.height
            var bytes = [UInt8](
                repeating: 0,
                count: width * height * Self.bytesPerPixel
            )
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue
                | CGImageAlphaInfo.premultipliedLast.rawValue

            let rendered = bytes.withUnsafeMutableBytes { storage in
                guard let context = CGContext(
                    data: storage.baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width * Self.bytesPerPixel,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo
                ) else {
                    return false
                }

                context.draw(
                    source,
                    in: CGRect(x: 0, y: 0, width: width, height: height)
                )
                return true
            }

            guard rendered else { return nil }
            self.width = width
            self.height = height
            self.bytes = bytes
        }
    }
#endif
