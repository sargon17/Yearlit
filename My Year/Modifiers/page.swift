import SwiftUI

struct PageModifier: ViewModifier {
  @Environment(\.colorScheme) var colorScheme

  func body(content: Content) -> some View {
    // VStack {
    content
      .background(Color("surface-muted"))
    // .padding()
    // }
    // .sameLevelBorder(radius: 10)
    // .padding(.all, 2)
    // .background(getVoidColor(colorScheme: colorScheme))
    // .cornerRadius(12)
    // .outerSameLevelShadow(radius: 12)
  }
}

extension View {
  func page() -> some View {
    modifier(PageModifier())
  }
}
