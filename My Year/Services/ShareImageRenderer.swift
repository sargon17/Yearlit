import SwiftUI
import UIKit

enum ShareImageRenderer {
    @MainActor
    static func render<Content: View>(
        view: Content,
        size: CGSize,
        colorScheme: ColorScheme? = nil,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage? {
        let base = view.frame(width: size.width, height: size.height)
        let content: AnyView = {
            guard let colorScheme else { return AnyView(base) }
            return AnyView(base.environment(\.colorScheme, colorScheme))
        }()
        let renderer = ImageRenderer(content: content)
        renderer.scale = scale
        return renderer.uiImage
    }
}
