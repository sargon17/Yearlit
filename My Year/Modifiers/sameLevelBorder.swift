import Garnish
import SwiftUI
import UIKit

struct SameLevelBorder: ViewModifier {
  let radius: CGFloat
  let color: Color
  let isFlat: Bool

  init(radius: CGFloat = 4, color: Color = .surfaceMuted, isFlat: Bool = false) {
    self.radius = radius
    self.color = color
    self.isFlat = isFlat
  }

  @Environment(\.colorScheme) var colorScheme
  private let bevelOffset: CGFloat = 1.6

  func body(content: Content) -> some View {
    let lightColor = color.mix(with: .white, by: 0.1)
    let hardLightColor = color.mix(with: .white, by: 0.3)
    let lightReflect = color.opacity(0.6)

    let hardShadowColor = color.mix(with: .black, by: 0.3)
    let darkReflect = color.opacity(0.6)

    ZStack {
      content
    }
    .background(
      RoundedRectangle(cornerRadius: radius)
        .foregroundStyle(
          color
            .shadow(
              .inner(
                color: hardShadowColor,
                radius: 10,
                x: bevelOffset * 2,
                y: bevelOffset * 2
              )
            )
            .shadow(
              .inner(
                color: hardLightColor,
                radius: 0.5,
                x: -bevelOffset,
                y: -bevelOffset
              )
            )

            .shadow(
              .inner(
                color: lightColor,
                radius: 10,
                x: -bevelOffset * 2,
                y: -bevelOffset * 2
              )
            )
            .shadow(
              .inner(
                color: hardShadowColor,
                radius: 0.5,
                x: bevelOffset,
                y: bevelOffset
              )
            )  // inner dark shadow

            .shadow(.drop(color: lightReflect, radius: 2, x: -bevelOffset, y: -bevelOffset))

            .shadow(.drop(color: darkReflect, radius: 2, x: bevelOffset, y: bevelOffset))

            .shadow(.drop(color: .black, radius: 0, x: -bevelOffset, y: -bevelOffset))
            .shadow(.drop(color: .black, radius: 0, x: -bevelOffset, y: bevelOffset))
            .shadow(.drop(color: .black, radius: 0, x: bevelOffset, y: -bevelOffset))
            .shadow(.drop(color: .black, radius: 0, x: bevelOffset, y: bevelOffset))
        )
        .overlay(
          NoiseLayer(opacity: 0.35, blendMode: .colorBurn)
            .mask(RoundedRectangle(cornerRadius: radius))
        )
        .shadow(
          color: color.mix(with: .black, by: 0.7).opacity(0.5),
          radius: isFlat ? 1 : 2,
          x: isFlat ? 1 : 4,
          y: isFlat ? 1 : 6
        )
    )
  }

  private func shadowScale(for color: Color) -> Double {
    let luminance = relativeLuminance(for: color)
    return 0.6 + (0.8 * luminance)
  }

  private func relativeLuminance(for color: Color) -> Double {
    let uiColor = UIColor(color)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
      return 0.5
    }
    return Double(0.2126 * red + 0.7152 * green + 0.0722 * blue)
  }

  private func clampedOpacity(_ value: Double) -> Double {
    min(1, max(0, value))
  }
}

func getVoidColor(colorScheme: ColorScheme) -> Color {
  return colorScheme == .dark ? .black.opacity(1) : .black.opacity(0.9)
}

extension View {
  func sameLevelBorder(radius: CGFloat = 4, color: Color = .surfaceMuted, isFlat: Bool = false)
    -> some View
  {
    modifier(SameLevelBorder(radius: radius, color: color, isFlat: isFlat))
  }
}

struct SameLevelGroupBackground: ViewModifier {
  let radius: CGFloat

  @Environment(\.colorScheme) var colorScheme

  init(radius: CGFloat = 6) {
    self.radius = radius
  }

  func body(content: Content) -> some View {
    content
      .background(
        RoundedRectangle(cornerRadius: radius)
          .foregroundStyle(getVoidColor(colorScheme: colorScheme))
      )
      .clipped()
  }
}

extension View {
  func sameLevelGroupBackground(radius: CGFloat = 6) -> some View {
    modifier(SameLevelGroupBackground(radius: radius))
  }
}

struct OuterSameLevelShadow: ViewModifier {
  let radius: CGFloat
  private let lightOffset: CGFloat = -0.6
  private let darkOffset: CGFloat = 0.6

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
