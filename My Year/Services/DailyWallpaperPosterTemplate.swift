import UIKit

enum DailyWallpaperPosterTemplate {
  static func draw(
    size: CGSize,
    screenScale: CGFloat,
    progress: DailyWallpaperProgressData,
    palette: DailyWallpaperPalette,
    message: String?
  ) {
    let unit = max(1, screenScale)
    let contentWidth = min(size.width * 0.82, 350 * unit)
    let contentX = (size.width - contentWidth) / 2
    let contentY = size.height * 0.24
    let layout = DailyWallpaperTemplateLayout(
      contentX: contentX,
      contentY: contentY,
      contentWidth: contentWidth,
      unit: unit
    )

    drawLabels(layout: layout, progress: progress, palette: palette)

    DailyWallpaperDrawing.drawProgressBar(
      in: DailyWallpaperDrawing.aligned(
        layout.rect(yOffset: 202, height: 8)
      ),
      progress: progress.percentComplete,
      palette: palette,
      cornerRadius: 4 * unit
    )

    DailyWallpaperDrawing.drawGrid(
      in: DailyWallpaperDrawing.aligned(
        layout.rect(yOffset: 246, height: 164)
      ),
      unit: unit,
      progress: progress,
      palette: palette
    )

    DailyWallpaperDrawing.drawMessageIfNeeded(message, in: size, unit: unit, palette: palette)
  }

  private static func drawLabels(
    layout: DailyWallpaperTemplateLayout,
    progress: DailyWallpaperProgressData,
    palette: DailyWallpaperPalette
  ) {
    DailyWallpaperDrawing.drawText(
      "\(progress.year)",
      in: layout.rect(yOffset: 0, height: 28),
      attributes: DailyWallpaperDrawing.textAttributes(
        size: 18 * layout.unit,
        weight: .heavy,
        color: palette.secondaryText
      ),
      alignment: .center
    )

    DailyWallpaperDrawing.drawText(
      String(format: "%.1f%%", progress.percentComplete * 100),
      in: layout.rect(yOffset: 42, height: 96),
      attributes: DailyWallpaperDrawing.textAttributes(
        size: 72 * layout.unit,
        weight: .black,
        color: palette.primaryText
      ),
      alignment: .center
    )

    DailyWallpaperDrawing.drawText(
      "\(progress.daysLeft) days left",
      in: layout.rect(yOffset: 142, height: 28),
      attributes: DailyWallpaperDrawing.textAttributes(
        size: 18 * layout.unit,
        weight: .heavy,
        color: palette.accent
      ),
      alignment: .center
    )
  }
}
