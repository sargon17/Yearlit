import UIKit

enum DailyWallpaperMinimalTemplate {
  static func draw(_ input: DailyWallpaperTemplateRenderInput) {
    let unit = max(1, input.screenScale)
    let contentWidth = min(input.size.width * 0.84, 370 * unit)
    let contentX = (input.size.width - contentWidth) / 2
    let contentY = input.size.height * 0.3
    let gridHeight = min(max(input.size.height * 0.24, 215 * unit), 280 * unit)
    let layout = DailyWallpaperTemplateLayout(
      contentX: contentX,
      contentY: contentY,
      contentWidth: contentWidth,
      unit: unit
    )

    drawLabels(
      layout: layout,
      progress: input.progress,
      localizedText: input.localizedText,
      palette: input.palette
    )

    DailyWallpaperDrawing.drawGrid(
      in: DailyWallpaperDrawing.aligned(
        CGRect(x: contentX, y: contentY + (132 * unit), width: contentWidth, height: gridHeight)
      ),
      unit: unit,
      progress: input.progress,
      palette: input.palette
    )

    DailyWallpaperDrawing.drawMessageIfNeeded(
      input.message,
      in: input.size,
      unit: unit,
      palette: input.palette
    )
  }

  private static func drawLabels(
    layout: DailyWallpaperTemplateLayout,
    progress: DailyWallpaperProgressData,
    localizedText: DailyWallpaperLocalizedText,
    palette: DailyWallpaperPalette
  ) {
    drawTopLabels(layout: layout, progress: progress, localizedText: localizedText, palette: palette)
    drawBottomLabels(layout: layout, progress: progress, localizedText: localizedText, palette: palette)
  }

  private static func drawTopLabels(
    layout: DailyWallpaperTemplateLayout,
    progress: DailyWallpaperProgressData,
    localizedText: DailyWallpaperLocalizedText,
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
      localizedText.percentComplete,
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
    localizedText: DailyWallpaperLocalizedText,
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
      localizedText.compactDaysLeft,
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
