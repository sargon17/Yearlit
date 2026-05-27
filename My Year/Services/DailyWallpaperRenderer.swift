import UIKit

enum DailyWallpaperRenderer {
  @MainActor
  static func render(
    settings: DailyWallpaperSettings = DailyWallpaperSettingsStore.effectiveSettings(),
    referenceDate: Date = Date()
  ) -> UIImage? {
    let screen = UIScreen.main
    let pointSize = screen.bounds.size == .zero ? CGSize(width: 430, height: 932) : screen.bounds.size
    let screenScale = screen.nativeScale == 0 ? (screen.scale == 0 ? 3 : screen.scale) : screen.nativeScale
    let pixelSize =
      screen.nativeBounds.size == .zero
      ? CGSize(width: pointSize.width * screenScale, height: pointSize.height * screenScale)
      : screen.nativeBounds.size

    return render(pixelSize: pixelSize, screenScale: screenScale, settings: settings, referenceDate: referenceDate)
  }

  @MainActor
  static func renderPreview(settings: DailyWallpaperSettings, referenceDate: Date = Date()) -> UIImage? {
    render(pixelSize: CGSize(width: 430, height: 932), screenScale: 1, settings: settings, referenceDate: referenceDate)
  }

  static func render(
    pixelSize: CGSize,
    screenScale: CGFloat,
    settings: DailyWallpaperSettings,
    referenceDate: Date = Date()
  ) -> UIImage? {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true

    return UIGraphicsImageRenderer(size: pixelSize, format: format).image { context in
      drawWallpaper(
        in: context.cgContext,
        size: pixelSize,
        screenScale: screenScale,
        settings: settings,
        referenceDate: referenceDate
      )
    }
  }

  private static func drawWallpaper(
    in context: CGContext,
    size: CGSize,
    screenScale: CGFloat,
    settings: DailyWallpaperSettings,
    referenceDate: Date
  ) {
    let palette = DailyWallpaperPalette(theme: settings.theme, accentColorName: settings.accentColorName)
    let progress = DailyWallpaperProgressData(referenceDate: referenceDate)

    palette.background.setFill()
    context.fill(CGRect(origin: .zero, size: size))
    let input = DailyWallpaperTemplateRenderInput(
      context: context,
      size: size,
      screenScale: screenScale,
      progress: progress,
      palette: palette,
      localizedText: DailyWallpaperLocalizedText(progress: progress),
      message: settings.message
    )

    settings.template.draw(input)
  }
}
