import UIKit

enum DailyWallpaperMinimalTemplate {
  static func draw(
    size: CGSize,
    screenScale: CGFloat,
    progress: DailyWallpaperProgressData,
    palette: DailyWallpaperPalette,
    message: String?
  ) {
    let unit = max(1, screenScale)
    let contentWidth = min(size.width * 0.72, 300 * unit)
    let contentX = (size.width - contentWidth) / 2
    let contentY = size.height * 0.38
    let layout = DailyWallpaperTemplateLayout(
      contentX: contentX,
      contentY: contentY,
      contentWidth: contentWidth,
      unit: unit
    )

    drawLabels(layout: layout, progress: progress, palette: palette)

    DailyWallpaperDrawing.drawProgressBar(
      in: DailyWallpaperDrawing.aligned(
        layout.rect(yOffset: 124, height: 5)
      ),
      progress: progress.percentComplete,
      palette: palette,
      cornerRadius: 2.5 * unit
    )

    DailyWallpaperDrawing.drawMessageIfNeeded(message, in: size, unit: unit, palette: palette)
  }

  private static func drawLabels(
    layout: DailyWallpaperTemplateLayout,
    progress: DailyWallpaperProgressData,
    palette: DailyWallpaperPalette
  ) {
    drawTopLabels(layout: layout, progress: progress, palette: palette)
    drawBottomLabels(layout: layout, progress: progress, palette: palette)
  }

  private static func drawTopLabels(
    layout: DailyWallpaperTemplateLayout,
    progress: DailyWallpaperProgressData,
    palette: DailyWallpaperPalette
  ) {
    DailyWallpaperDrawing.drawText(
      "\(progress.year)",
      in: layout.rect(yOffset: 0, height: 28),
      attributes: DailyWallpaperDrawing.textAttributes(
        size: 17 * layout.unit,
        weight: .heavy,
        color: palette.secondaryText
      ),
      alignment: .left
    )

    DailyWallpaperDrawing.drawText(
      String(format: "%.1f%%", progress.percentComplete * 100),
      in: layout.rect(yOffset: 34, height: 44),
      attributes: DailyWallpaperDrawing.textAttributes(
        size: 34 * layout.unit,
        weight: .black,
        color: palette.primaryText
      ),
      alignment: .left
    )
  }

  private static func drawBottomLabels(
    layout: DailyWallpaperTemplateLayout,
    progress: DailyWallpaperProgressData,
    palette: DailyWallpaperPalette
  ) {
    DailyWallpaperDrawing.drawText(
      "\(progress.currentDayNumber)/\(progress.numberOfDaysInYear)",
      in: layout.rect(yOffset: 86, height: 24),
      attributes: DailyWallpaperDrawing.textAttributes(
        size: 14 * layout.unit,
        weight: .regular,
        color: palette.tertiaryText
      ),
      alignment: .left
    )

    DailyWallpaperDrawing.drawText(
      "\(progress.daysLeft) left",
      in: layout.rect(yOffset: 86, height: 24),
      attributes: DailyWallpaperDrawing.textAttributes(
        size: 14 * layout.unit,
        weight: .heavy,
        color: palette.accent
      ),
      alignment: .right
    )
  }
}
