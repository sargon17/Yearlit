import SwiftUI

struct SameLevelBorder: ViewModifier {
  let radius: CGFloat
  let withOuterShadow: Bool

  init(radius: CGFloat = 4, withOuterShadow: Bool = true) {
    self.radius = radius
    self.withOuterShadow = withOuterShadow
  }

  func body(content: Content) -> some View {
    content
      .background(
        RoundedRectangle(cornerRadius: radius)
          .foregroundStyle(
            .surfaceMuted
              .shadow(.inner(color: .white.opacity(0.1), radius: 1, x: -1, y: 2))  // inner light shadow
              .shadow(.inner(color: .black.opacity(0.1), radius: 1, x: 1, y: -2))  // inner dark shadow
          )
      )
      .background(
        RoundedRectangle(cornerRadius: radius)
          .stroke(getVoidColor(), lineWidth: 1)
      )
  }

}

func getVoidColor() -> Color {
  @Environment(\.colorScheme) var colorScheme
  return colorScheme == .dark ? .black.opacity(0.5) : .black.opacity(0.4)
}

extension View {
  func sameLevelBorder(radius: CGFloat = 4) -> some View {
    self.modifier(SameLevelBorder(radius: radius))
  }
}

struct OuterSameLevelShadow: ViewModifier {
  let radius: CGFloat

  init(radius: CGFloat = 4) {
    self.radius = radius
  }

  func body(content: Content) -> some View {
    content
      .background(
        RoundedRectangle(cornerRadius: radius)
          .foregroundStyle(
            .surfaceMuted
              .shadow(.drop(color: .white.opacity(0.1), radius: 1, x: -1, y: 2))
              .shadow(.drop(color: .black.opacity(0.1), radius: 1, x: 1, y: -2))
          )
      )
  }
}

extension View {
  func outerSameLevelShadow(radius: CGFloat = 4) -> some View {
    self.modifier(OuterSameLevelShadow())
  }
}
