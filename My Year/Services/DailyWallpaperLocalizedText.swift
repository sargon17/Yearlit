import Foundation

struct DailyWallpaperLocalizedText {
  let percentComplete: String
  let daysLeftHeader: DailyWallpaperLocalizedTextParts
  let compactDaysLeft: String

  init(progress: DailyWallpaperProgressData, locale: Locale = .current) {
    let daysLeft = progress.daysLeft.formatted(.number.locale(locale))
    let headerFormat = String(
      localized: "wallpaper.daysLeft.header",
      defaultValue: "%@ days left",
      comment: "Daily Wallpaper header label. The placeholder is the number of days remaining in the year."
    )
    let compactFormat = String(
      localized: "wallpaper.daysLeft.compact",
      defaultValue: "%@ left",
      comment: "Compact Daily Wallpaper label. The placeholder is the number of days remaining in the year."
    )

    percentComplete = progress.percentComplete.formatted(
      .percent.precision(.fractionLength(1)).locale(locale)
    )
    daysLeftHeader = DailyWallpaperLocalizedTextParts(
      format: headerFormat,
      value: daysLeft,
      fallbackFormat: "%@ days left",
      source: "wallpaper.daysLeft.header"
    )
    compactDaysLeft =
      DailyWallpaperLocalizedTextParts(
        format: compactFormat,
        value: daysLeft,
        fallbackFormat: "%@ left",
        source: "wallpaper.daysLeft.compact"
      )
      .string
  }
}

struct DailyWallpaperLocalizedTextParts {
  let prefix: String
  let value: String
  let suffix: String

  var string: String {
    prefix + value + suffix
  }

  private init(prefix: String, value: String, suffix: String) {
    self.prefix = prefix
    self.value = value
    self.suffix = suffix
  }

  init(format: String, value: String, fallbackFormat: String, source: StaticString) {
    switch Self.parts(format: format, value: value) {
    case .some(let parts):
      prefix = parts.prefix
      self.value = parts.value
      suffix = parts.suffix
    case .none:
      assertionFailure("Invalid localized format for \(source). Expected exactly one %@ placeholder.")
      let fallbackParts = Self.parts(format: fallbackFormat, value: value)
      prefix = fallbackParts?.prefix ?? ""
      self.value = fallbackParts?.value ?? value
      suffix = fallbackParts?.suffix ?? ""
    }
  }

  private static func parts(format: String, value: String) -> DailyWallpaperLocalizedTextParts? {
    let components = format.components(separatedBy: "%@")
    guard components.count == 2 else { return nil }

    return DailyWallpaperLocalizedTextParts(
      prefix: components[0],
      value: value,
      suffix: components[1]
    )
  }
}
