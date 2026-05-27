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
    case .dark: namedColor("surface-muted", userInterfaceStyle: .dark) ?? rgb(0x18, 0x18, 0x1B)
    case .light: namedColor("surface-muted", userInterfaceStyle: .light) ?? rgb(0xF4, 0xF4, 0xF5)
    }
  }

  private static func primaryText(for theme: DailyWallpaperTheme) -> UIColor {
    switch theme {
    case .dark: namedColor("text-primary", userInterfaceStyle: .dark) ?? rgb(0xFA, 0xFA, 0xFA)
    case .light: namedColor("text-primary", userInterfaceStyle: .light) ?? rgb(0x09, 0x09, 0x0B)
    }
  }

  private static func secondaryText(for theme: DailyWallpaperTheme) -> UIColor {
    switch theme {
    case .dark: namedColor("text-secondary", userInterfaceStyle: .dark) ?? rgb(0x9F, 0x9F, 0xA9)
    case .light: namedColor("text-secondary", userInterfaceStyle: .light) ?? rgb(0x3F, 0x3F, 0x46)
    }
  }

  private static func tertiaryText(for theme: DailyWallpaperTheme) -> UIColor {
    switch theme {
    case .dark: namedColor("text-tertiary", userInterfaceStyle: .dark) ?? rgb(0x52, 0x52, 0x5C)
    case .light: namedColor("text-tertiary", userInterfaceStyle: .light) ?? rgb(0x71, 0x71, 0x7B)
    }
  }

  private static func separatorTop(for theme: DailyWallpaperTheme) -> UIColor {
    switch theme {
    case .dark: namedColor("devider-top", userInterfaceStyle: .dark) ?? rgb(0x0E, 0x0E, 0x11)
    case .light: namedColor("devider-top", userInterfaceStyle: .light) ?? rgb(0xD4, 0xD4, 0xD8)
    }
  }

  private static func separatorBottom(for theme: DailyWallpaperTheme) -> UIColor {
    switch theme {
    case .dark: namedColor("devider-bottom", userInterfaceStyle: .dark) ?? rgb(0x22, 0x22, 0x25)
    case .light: namedColor("devider-bottom", userInterfaceStyle: .light) ?? rgb(0xF4, 0xF4, 0xF5)
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

  private static func namedColor(_ name: String, userInterfaceStyle: UIUserInterfaceStyle) -> UIColor? {
    UIColor(
      named: name,
      in: .main,
      compatibleWith: UITraitCollection(userInterfaceStyle: userInterfaceStyle)
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
