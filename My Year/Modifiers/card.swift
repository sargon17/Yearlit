import SwiftUI

struct CardModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding()
      .background(Color.surfaceSecondary)
      .cornerRadius(22)
      .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
      .overlay(
        RoundedRectangle(cornerRadius: 22)
          .stroke(Color.surfacePrimary, lineWidth: 1)
      )
  }
}

extension View {
  func cardStyle() -> some View {
    self.modifier(CardModifier())
  }
}
