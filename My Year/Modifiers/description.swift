import SwiftUI

struct DescriptionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(
                AppFont.mono(11)
                    .weight(.regular)
            )
            .foregroundStyle(.textTertiary)
    }
}

extension View {
    func descriptionStyle() -> some View {
        modifier(DescriptionModifier())
    }
}
