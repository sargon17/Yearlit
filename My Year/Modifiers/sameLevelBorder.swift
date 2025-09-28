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
                color: .white.opacity(colorScheme == .dark ? 0.1 : 0.6), radius: 0.5, x: motionManager.x,
                y: motionManager.y
              )
            )  // inner light shadow
            .shadow(
              .inner(
                color: .white.opacity(colorScheme == .dark ? 0.05 : 0.35),
                radius: 4,
                x: motionManager.x * 2,
                y: motionManager.y * 2
              )
            )

            .shadow(
              .inner(
                color: .black.opacity(colorScheme == .dark ? 0.8 : 0.4),
                radius: 0.5,
                x: -motionManager.x,
                y: -motionManager.y
              )
            )  // inner dark shadow
            .shadow(
              .inner(
                color: .black.opacity(colorScheme == .dark ? 0.4 : 0.1),
                radius: 4,
                x: -motionManager.x * 2,
                y: -motionManager.y * 2
              )
            )  // inner dark shadow
        )
    )
  }
}

func getVoidColor(colorScheme: ColorScheme) -> Color {
  return colorScheme == .dark ? .black.opacity(1) : .black.opacity(0.10)
}

extension View {
  func sameLevelBorder(radius: CGFloat = 4, color: Color = .surfaceMuted) -> some View {
    modifier(SameLevelBorder(radius: radius, color: color))
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
                  color: .white.opacity(colorScheme == .dark ? 0.05 : 0.3),
                  radius: 0.2,
                  x: motionManager.x,
                  y: motionManager.y
                )
              )
              // .shadow(
              //   .drop(
              //     color: .white.opacity(colorScheme == .dark ? 0.05 : 0.35),
              //     radius: 1,
              //     x: motionManager.x * 2,
              //     y: motionManager.y * 2
              //   )
              // )

              .shadow(
                .drop(
                  color: .black.opacity(colorScheme == .dark ? 1 : 0.4),
                  radius: 0.2,
                  x: -motionManager.x,
                  y: -motionManager.y
                )
              )
          )
      )
  }
}

extension View {
  func outerSameLevelShadow(radius: CGFloat = 6) -> some View {
    modifier(OuterSameLevelShadow(radius: radius))
  }
}
