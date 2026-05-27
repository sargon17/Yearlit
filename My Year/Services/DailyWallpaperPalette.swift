import SharedModels
import UIKit

struct DailyWallpaperPalette {
  let background: UIColor
  let primaryText: UIColor
  let secondaryText: UIColor
  let tertiaryText: UIColor
  let accent: UIColor
  let separatorTop: UIColor
  let separatorBottom: UIColor
  let pastDot: UIColor
  let futureDot: UIColor

  init(theme: DailyWallpaperTheme, accentColorName: String) {
    background = Self.background(for: theme)
    primaryText = Self.primaryText(for: theme)
    secondaryText = Self.secondaryText(for: theme)
    tertiaryText = Self.tertiaryText(for: theme)
    accent =
      UIColor(named: accentColorName) ?? UIColor(named: DailyWallpaperSettingsStore.defaultAccentColorName)
      ?? Self.rgb(0xF9, 0x73, 0x16)
    separatorTop = Self.separatorTop(for: theme)
    separatorBottom = Self.separatorBottom(for: theme)
    futureDot = Self.blendedColor(
      base: background,
      overlay: primaryText,
      ratio: CGFloat(WidgetStyle.futureDotFillRatio)
    )
    pastDot = Self.blendedColor(
      base: background,
      overlay: primaryText,
      ratio: CGFloat(WidgetStyle.todayEmptyDotFillRatio)
    )
  }

  private static func background(for theme: DailyWallpaperTheme) -> UIColor {
    switch theme {
    case .dark: rgb(0x12, 0x12, 0x14)
    case .light: rgb(0xF7, 0xF2, 0xEA)
    }
  }

  private static func primaryText(for theme: DailyWallpaperTheme) -> UIColor {
    switch theme {
    case .dark: rgb(0xFA, 0xFA, 0xFA)
    case .light: rgb(0x18, 0x18, 0x1B)
    }
  }

  private static func secondaryText(for theme: DailyWallpaperTheme) -> UIColor {
    switch theme {
    case .dark: rgb(0xC2, 0xC2, 0xCA)
    case .light: rgb(0x46, 0x43, 0x3D)
    }
  }

  private static func tertiaryText(for theme: DailyWallpaperTheme) -> UIColor {
    switch theme {
    case .dark: rgb(0x87, 0x87, 0x94)
    case .light: rgb(0x82, 0x7B, 0x70)
    }
  }

  private static func separatorTop(for theme: DailyWallpaperTheme) -> UIColor {
    switch theme {
    case .dark: rgb(0x2A, 0x2A, 0x2E)
    case .light: rgb(0xDE, 0xD7, 0xCB)
    }
  }

  private static func separatorBottom(for theme: DailyWallpaperTheme) -> UIColor {
    switch theme {
    case .dark: rgb(0x10, 0x10, 0x12)
    case .light: rgb(0xFF, 0xFB, 0xF3)
    }
  }

  private static func rgb(_ red: Int, _ green: Int, _ blue: Int) -> UIColor {
    UIColor(
      red: CGFloat(red) / 255,
      green: CGFloat(green) / 255,
      blue: CGFloat(blue) / 255,
      alpha: 1
    )
  }

  private static func blendedColor(base: UIColor, overlay: UIColor, ratio: CGFloat) -> UIColor {
    let clampedRatio = max(0, min(1, ratio))
    var baseRed: CGFloat = 0
    var baseGreen: CGFloat = 0
    var baseBlue: CGFloat = 0
    var baseAlpha: CGFloat = 0
    var overlayRed: CGFloat = 0
    var overlayGreen: CGFloat = 0
    var overlayBlue: CGFloat = 0
    var overlayAlpha: CGFloat = 0

    base.getRed(&baseRed, green: &baseGreen, blue: &baseBlue, alpha: &baseAlpha)
    overlay.getRed(&overlayRed, green: &overlayGreen, blue: &overlayBlue, alpha: &overlayAlpha)

    return UIColor(
      red: baseRed + (overlayRed - baseRed) * clampedRatio,
      green: baseGreen + (overlayGreen - baseGreen) * clampedRatio,
      blue: baseBlue + (overlayBlue - baseBlue) * clampedRatio,
      alpha: baseAlpha + (overlayAlpha - baseAlpha) * clampedRatio
    )
  }
}
