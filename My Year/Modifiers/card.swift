import SwiftUI

struct CardModifier: ViewModifier {
  @Environment(\.colorScheme) var colorScheme

  func body(content: Content) -> some View {
    VStack {

      content
        .padding()
        .sameLevelBorder(radius: 10)
    }
    .padding(.all, 2)
    .background(getVoidColor(colorScheme: colorScheme))
    .cornerRadius(12)
    .outerSameLevelShadow(radius: 12)
  }
}

extension View {
  func cardStyle() -> some View {
    self.modifier(CardModifier())
  }
}
