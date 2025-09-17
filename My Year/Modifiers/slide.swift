import SwiftUI

struct SlideModifier: ViewModifier {
  @Environment(\.colorScheme) var colorScheme

  func body(content: Content) -> some View {

    content
      .overlay {
        HStack {
          Rectangle()
            .fill(Color("devider-bottom"))
            .frame(maxHeight: .infinity, alignment: .trailing)
            .frame(maxWidth: 1)
            .ignoresSafeArea(.all, edges: .vertical)

          Spacer()

          Rectangle()
            .fill(Color("devider-top"))
            .frame(maxHeight: .infinity, alignment: .trailing)
            .frame(maxWidth: 1)
            .ignoresSafeArea(.all, edges: .vertical)
        }
      }

  }
}

extension View {
  func slide() -> some View {
    self.modifier(SlideModifier())
  }
}
