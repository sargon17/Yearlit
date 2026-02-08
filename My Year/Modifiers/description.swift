import SwiftUI

struct DescriptionModifier: ViewModifier {

  func body(content: Content) -> some View {
    content
      .font(
        .system(size: 11, design: .monospaced)
          .weight(.regular)
      )
      .foregroundStyle(.textTertiary)
  }
}

extension View {
  func descriptionStyle() -> some View {
    self.modifier(DescriptionModifier())
  }
}
