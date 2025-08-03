import SwiftUI

struct SameLevelBorder: ViewModifier {
  // @StateObject private var motionManager = MotionManager()
  let radius: CGFloat
  let color: Color

  init(radius: CGFloat = 4, color: Color = .surfaceMuted) {
    self.radius = radius
    self.color = color
  }

  @Environment(\.colorScheme) var colorScheme
  @StateObject private var motionManager = MotionManager.shared

  func body(content: Content) -> some View {
    ZStack {
      content
    }
    .background(
      RoundedRectangle(cornerRadius: radius)
        .foregroundStyle(
          color
            .shadow(
              .inner(
                color: .white.opacity(colorScheme == .dark ? 0.2 : 0.6), radius: 0.5, x: motionManager.x,
                y: motionManager.y
              )
            )  // inner light shadow

            .shadow(
              .inner(
                color: .black.opacity(colorScheme == .dark ? 0.6 : 0.4), radius: 0.5, x: -motionManager.x,
                y: -motionManager.y))  // inner dark shadow
        )
    )
  }

}

func getVoidColor(colorScheme: ColorScheme) -> Color {
  return colorScheme == .dark ? .black.opacity(1) : .black.opacity(0.05)
}

extension View {
  func sameLevelBorder(radius: CGFloat = 4, color: Color = .surfaceMuted) -> some View {
    self.modifier(SameLevelBorder(radius: radius, color: color))
  }
}

struct OuterSameLevelShadow: ViewModifier {
  // @StateObject private var motionManager = MotionManager()
  let radius: CGFloat
  @StateObject private var motionManager = MotionManager.shared

  @Environment(\.colorScheme) var colorScheme

  init(radius: CGFloat = 4) {
    self.radius = radius
  }

  func body(content: Content) -> some View {
    content
      .background(
        RoundedRectangle(cornerRadius: radius)
          .foregroundStyle(
            .surfaceMuted
              .shadow(
                .drop(
                  color: .white.opacity(colorScheme == .dark ? 0.1 : 0.3), radius: 0.2, x: motionManager.x,
                  y: motionManager.y
                )
              )
              .shadow(
                .drop(
                  color: .black.opacity(colorScheme == .dark ? 1 : 0.7), radius: 0.2, x: -motionManager.x,
                  y: -motionManager.y
                )
              )
          )
      )
  }
}

extension View {
  func outerSameLevelShadow(radius: CGFloat = 6) -> some View {
    self.modifier(OuterSameLevelShadow(radius: radius))
  }
}
