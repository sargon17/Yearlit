import SwiftUI

struct BlurReplaceModifier: ViewModifier {
    let blur: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .blur(radius: blur)
            .opacity(opacity)
    }
}

extension AnyTransition {
    static var blurReplace: AnyTransition {
        let active = BlurReplaceModifier(blur: 12, opacity: 0)
        let identity = BlurReplaceModifier(blur: 0, opacity: 1)
        return .modifier(active: active, identity: identity)
    }
}
