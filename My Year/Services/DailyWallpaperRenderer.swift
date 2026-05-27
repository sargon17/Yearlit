import UIKit

enum DailyWallpaperRenderer {
  @MainActor
  static func render(
    settings: DailyWallpaperSettings = DailyWallpaperSettingsStore.effectiveSettings()
  ) -> UIImage? {
    let screen = UIScreen.main
    let pointSize = screen.bounds.size == .zero ? CGSize(width: 430, height: 932) : screen.bounds.size
    let screenScale = screen.nativeScale == 0 ? (screen.scale == 0 ? 3 : screen.scale) : screen.nativeScale
    let pixelSize =
      screen.nativeBounds.size == .zero
      ? CGSize(width: pointSize.width * screenScale, height: pointSize.height * screenScale)
      : screen.nativeBounds.size

    return render(pixelSize: pixelSize, screenScale: screenScale, settings: settings)
  }

  @MainActor
  static func renderPreview(settings: DailyWallpaperSettings) -> UIImage? {
    render(pixelSize: CGSize(width: 430, height: 932), screenScale: 1, settings: settings)
  }

  private static func render(
    pixelSize: CGSize,
    screenScale: CGFloat,
    settings: DailyWallpaperSettings
  ) -> UIImage? {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true

    return UIGraphicsImageRenderer(size: pixelSize, format: format).image { context in
      drawWallpaper(
        in: context.cgContext,
        size: pixelSize,
        screenScale: screenScale,
        settings: settings
      )
    }
  }

  private static func drawWallpaper(
    in context: CGContext,
    size: CGSize,
    screenScale: CGFloat,
    settings: DailyWallpaperSettings
  ) {
    let palette = DailyWallpaperPalette(theme: settings.theme, accentColorName: settings.accentColorName)
    let progress = DailyWallpaperProgressData(referenceDate: Date())

    palette.background.setFill()
    context.fill(CGRect(origin: .zero, size: size))

    switch settings.template {
    case .classic:
      DailyWallpaperClassicTemplate.draw(
        in: context,
        size: size,
        screenScale: screenScale,
        progress: progress,
        palette: palette
      )
    case .poster:
      DailyWallpaperPosterTemplate.draw(
        size: size, screenScale: screenScale, progress: progress, palette: palette,
        message: settings.message)
    case .minimal:
      DailyWallpaperMinimalTemplate.draw(
        size: size, screenScale: screenScale, progress: progress, palette: palette,
        message: settings.message)
    }
  }
}
