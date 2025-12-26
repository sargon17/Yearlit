import SwiftUI

struct SameLevelBorder: ViewModifier {
  let radius: CGFloat
  let color: Color

  init(radius: CGFloat = 4, color: Color = .surfaceMuted) {
    self.radius = radius
    self.color = color
  }

  @Environment(\.colorScheme) var colorScheme
  private let lightOffset: CGFloat = 2.6
  private let darkOffset: CGFloat = -2.6

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
                color: .white.opacity(colorScheme == .dark ? 0.05 : 0.3),
                radius: 1,
                x: lightOffset,
                y: lightOffset
              )
            )  // inner light shadow
            .shadow(
              .inner(
                color: .white.opacity(colorScheme == .dark ? 0.05 : 0.6),
                radius: 8,
                x: lightOffset * 2,
                y: lightOffset * 2
              )
            )

            .shadow(
              .inner(
                color: .black.opacity(colorScheme == .dark ? 0.5 : 0.4),
                radius: 0.5,
                x: darkOffset,
                y: darkOffset
              )
            )  // inner dark shadow
            .shadow(
              .inner(
                color: .black.opacity(colorScheme == .dark ? 0.4 : 0.1),
                radius: 4,
                x: darkOffset * 2,
                y: darkOffset * 2
              )
            )  // inner dark shadow
        )
      .overlay(
        NoiseLayer(opacity: 0.35, blendMode: nil)
          .mask(RoundedRectangle(cornerRadius: radius))
      )
      .shadow(
        color: .black.opacity(colorScheme == .dark ? 0.4 : 0.4),
        radius: 2,
        x: 4,
        y: 6,
      )
    )
  }
}

func getVoidColor(colorScheme: ColorScheme) -> Color {
  return colorScheme == .dark ? .black.opacity(1) : .black.opacity(0.9)
}

extension View {
  func sameLevelBorder(radius: CGFloat = 4, color: Color = .surfaceMuted) -> some View {
    modifier(SameLevelBorder(radius: radius, color: color))
  }
}

struct OuterSameLevelShadow: ViewModifier {
  let radius: CGFloat
  private let lightOffset: CGFloat = 0.6
  private let darkOffset: CGFloat = -0.6

  @Environment(\.colorScheme) var colorScheme

  init(radius: CGFloat = 0.5) {
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
                  x: lightOffset,
                  y: lightOffset
                )
              )

              .shadow(
                .drop(
                  color: .black.opacity(colorScheme == .dark ? 1 : 0.4),
                  radius: 0.2,
                  x: darkOffset,
                  y: darkOffset
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
