import SwiftUI
import UIKit

enum ShareImageRenderer {
    @MainActor
    static func render<Content: View>(
        view: Content,
        size: CGSize,
        colorScheme: ColorScheme? = nil,
        scale: CGFloat? = nil
    ) -> UIImage? {
        let base = view.frame(width: size.width, height: size.height)
        let content: AnyView = {
            guard let colorScheme else { return AnyView(base) }
            return AnyView(base.environment(\.colorScheme, colorScheme))
        }()
        let renderer = ImageRenderer(content: content)
        renderer.scale = scale ?? UIScreen.main.scale
        return renderer.uiImage
    }

    static func opaqueJPEGData(from image: UIImage, compressionQuality: CGFloat = 0.95) -> Data? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        let opaqueImage = renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: image.size))
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }

        return opaqueImage.jpegData(compressionQuality: compressionQuality)
    }

    static func writeTemporaryJPEG(from image: UIImage) -> URL? {
        guard let data = opaqueJPEGData(from: image) else { return nil }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")

        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            NSLog("Failed to write share image JPEG: \(error)")
            return nil
        }
    }
}
