import Foundation

enum DailyWallpaperTemplate: String, CaseIterable, Equatable, Identifiable {
  case classic
  case largeClock = "large"
  case minimal

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .classic: "Classic"
    case .largeClock: "Large Clock"
    case .minimal: "Minimal"
    }
  }

  var systemImageName: String {
    switch self {
    case .classic: "circle.grid.3x3.fill"
    case .largeClock: "rectangle.grid.1x2.fill"
    case .minimal: "minus"
    }
  }

  var isPremium: Bool {
    switch self {
    case .classic: false
    case .largeClock, .minimal: true
    }
  }

  var supportsMessage: Bool {
    switch self {
    case .classic: false
    case .largeClock, .minimal: true
    }
  }
}

enum DailyWallpaperTheme: String, CaseIterable, Equatable, Identifiable {
  case dark
  case light

  var id: String { rawValue }
}

struct DailyWallpaperSettings: Equatable {
  var template: DailyWallpaperTemplate
  var theme: DailyWallpaperTheme
  var accentColorName: String
  var message: String?
}

enum DailyWallpaperSettingsStore {
  static let defaultAccentColorName = "qs-orange"
  static let maxMessageLength = 40

  private static let templateKey = AppStorageKeys.dailyWallpaperTemplate
  private static let themeKey = AppStorageKeys.dailyWallpaperTheme
  private static let accentColorKey = AppStorageKeys.dailyWallpaperAccentColor
  private static let messageKey = AppStorageKeys.dailyWallpaperMessage
  private static let cachedPremiumKey = AppStorageKeys.cachedPremiumAccess

  static func savedSettings(defaults: UserDefaults = .standard) -> DailyWallpaperSettings {
    DailyWallpaperSettings(
      template: template(from: defaults.string(forKey: templateKey)),
      theme: theme(from: defaults.string(forKey: themeKey)),
      accentColorName: defaults.string(forKey: accentColorKey) ?? defaultAccentColorName,
      message: sanitizedMessage(defaults.string(forKey: messageKey))
    )
  }

  static func effectiveSettings(defaults: UserDefaults = .standard) -> DailyWallpaperSettings {
    let saved = savedSettings(defaults: defaults)
    guard hasCachedPremiumAccess(defaults: defaults) else {
      return DailyWallpaperSettings(
        template: .classic,
        theme: saved.theme,
        accentColorName: defaultAccentColorName,
        message: nil
      )
    }

    return DailyWallpaperSettings(
      template: saved.template,
      theme: saved.theme,
      accentColorName: saved.accentColorName,
      message: saved.template.supportsMessage ? saved.message : nil
    )
  }

  static func setCachedPremiumAccess(_ isPremium: Bool, defaults: UserDefaults = .standard) {
    defaults.set(isPremium, forKey: cachedPremiumKey)
  }

  static func hasCachedPremiumAccess(defaults: UserDefaults = .standard) -> Bool {
    defaults.object(forKey: cachedPremiumKey) as? Bool ?? false
  }

  static func saveTemplate(_ template: DailyWallpaperTemplate, defaults: UserDefaults = .standard) {
    defaults.set(template.rawValue, forKey: templateKey)
  }

  static func saveTheme(_ theme: DailyWallpaperTheme, defaults: UserDefaults = .standard) {
    defaults.set(theme.rawValue, forKey: themeKey)
  }

  static func saveAccentColorName(_ colorName: String, defaults: UserDefaults = .standard) {
    defaults.set(colorName, forKey: accentColorKey)
  }

  static func saveMessage(_ message: String, defaults: UserDefaults = .standard) {
    defaults.set(sanitizedMessage(message) ?? "", forKey: messageKey)
  }

  static func sanitizedMessage(_ message: String?) -> String? {
    guard let message else { return nil }
    let singleLine =
      message
      .components(separatedBy: .newlines)
      .joined(separator: " ")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    guard !singleLine.isEmpty else { return nil }

    return String(singleLine.prefix(maxMessageLength)).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private static func template(from rawValue: String?) -> DailyWallpaperTemplate {
    if rawValue == "poster" {
      return .largeClock
    }

    guard let rawValue, let template = DailyWallpaperTemplate(rawValue: rawValue) else {
      return .classic
    }

    return template
  }

  private static func theme(from rawValue: String?) -> DailyWallpaperTheme {
    guard let rawValue, let theme = DailyWallpaperTheme(rawValue: rawValue) else {
      return .dark
    }

    return theme
  }
}
