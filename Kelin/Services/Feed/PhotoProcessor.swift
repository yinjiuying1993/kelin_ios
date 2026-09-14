import CryptoKit
import Foundation
import UIKit

actor PhotoProcessor {
    static let maxLongEdge: CGFloat = 1_280
    static let jpegQuality: CGFloat = 0.75

    func process(_ data: Data) throws -> ProcessedSightPhoto {
        guard let image = UIImage(data: data) else {
            throw AppError.invalidInput
        }

        let normalized = redraw(image)
        let scaled = scale(normalized)
        guard let jpeg = scaled.jpegData(compressionQuality: Self.jpegQuality), !jpeg.isEmpty else {
            throw AppError.invalidInput
        }
        guard jpeg.count <= 5_242_880 else {
            throw AppError.invalidInput
        }

        let digest = SHA256.hash(data: jpeg)
        let sha256 = digest.map { String(format: "%02x", $0) }.joined()
        return ProcessedSightPhoto(
            jpeg: jpeg,
            sha256: sha256,
            pixelWidth: Int(scaled.size.width.rounded()),
            pixelHeight: Int(scaled.size.height.rounded())
        )
    }

    private func redraw(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    private func scale(_ image: UIImage) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > Self.maxLongEdge else {
            return image
        }

        let scale = Self.maxLongEdge / longest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
