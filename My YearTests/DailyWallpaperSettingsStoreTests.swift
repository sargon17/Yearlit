import Foundation
import Testing

@testable import My_Year

struct DailyWallpaperSettingsStoreTests {
  @Test func effectiveSettingsFallBackToFreeDefaultsWhenPremiumIsMissing() {
    let defaults = isolatedDefaults()
    DailyWallpaperSettingsStore.saveTemplate(.largeClock, defaults: defaults)
    DailyWallpaperSettingsStore.saveTheme(.light, defaults: defaults)
    DailyWallpaperSettingsStore.saveAccentColorName("qs-emerald", defaults: defaults)
    DailyWallpaperSettingsStore.saveMessage("One honest day at a time", defaults: defaults)

    let settings = DailyWallpaperSettingsStore.effectiveSettings(defaults: defaults)

    #expect(settings.template == .classic)
    #expect(settings.theme == .light)
    #expect(settings.accentColorName == DailyWallpaperSettingsStore.defaultAccentColorName)
    #expect(settings.message == nil)
  }

  @Test func effectiveSettingsPreservePremiumChoicesWhenPremiumIsCached() {
    let defaults = isolatedDefaults()
    DailyWallpaperSettingsStore.saveTemplate(.minimal, defaults: defaults)
    DailyWallpaperSettingsStore.saveTheme(.light, defaults: defaults)
    DailyWallpaperSettingsStore.saveAccentColorName("qs-emerald", defaults: defaults)
    DailyWallpaperSettingsStore.saveMessage("One honest day at a time", defaults: defaults)
    DailyWallpaperSettingsStore.setCachedPremiumAccess(true, defaults: defaults)

    let settings = DailyWallpaperSettingsStore.effectiveSettings(defaults: defaults)

    #expect(settings.template == .minimal)
    #expect(settings.theme == .light)
    #expect(settings.accentColorName == "qs-emerald")
    #expect(settings.message == "One honest day at a time")
  }

  @Test func sanitizedMessageIsSingleLineTrimmedAndCapped() {
    let message = DailyWallpaperSettingsStore.sanitizedMessage(
      "  first line\nsecond line that is too long for a wallpaper message  ")

    #expect(message == "first line second line that is too long")
    #expect((message?.count ?? 0) <= DailyWallpaperSettingsStore.maxMessageLength)
  }

  private func isolatedDefaults() -> UserDefaults {
    let suiteName = "daily-wallpaper-tests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
  }
}
