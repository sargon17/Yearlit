import UIKit

enum DailyWallpaperMinimalTemplate {
  static func draw(_ input: DailyWallpaperTemplateRenderInput) {
    let unit = max(1, input.screenScale)
    let metrics = DailyWallpaperTemplateMetrics(size: input.size, unit: unit)
    let progressBarY = metrics.minimalProgressBarY()
    let layout = metrics.minimalLayout(progressBarY: progressBarY)

    drawLabels(layout: layout, progress: input.progress, palette: input.palette)

    DailyWallpaperDrawing.drawProgressBar(
      in: DailyWallpaperDrawing.aligned(
        CGRect(
          x: layout.contentX,
          y: progressBarY,
          width: layout.contentWidth,
          height: metrics.progressBarHeight
        )
      ),
      progress: input.progress.percentComplete,
      palette: input.palette,
      cornerRadius: metrics.progressBarHeight / 2
    )

    DailyWallpaperDrawing.drawDivider(
      y: metrics.bottomDividerY,
      size: input.size,
      unit: unit,
      palette: input.palette,
      context: input.context
    )

    DailyWallpaperDrawing.drawMessageIfNeeded(
      input.message,
      in: input.size,
      unit: unit,
      palette: input.palette,
      yRatio: metrics.messageYRatio
    )
  }

  private static func drawLabels(
    layout: DailyWallpaperTemplateLayout,
    progress: DailyWallpaperProgressData,
    palette: DailyWallpaperPalette
  ) {
    DailyWallpaperDrawing.drawText(
      "\(progress.year)",
      in: layout.rect(yOffset: 0, height: 32),
      attributes: DailyWallpaperDrawing.textAttributes(
        size: 18 * layout.unit,
        weight: .heavy,
        color: palette.primaryText
      ),
      alignment: .left
    )

    DailyWallpaperDrawing.drawText(
      "\(progress.daysLeft) left",
      in: layout.rect(yOffset: 0, height: 32),
      attributes: DailyWallpaperDrawing.textAttributes(
        size: 18 * layout.unit,
        weight: .heavy,
        color: palette.accent
      ),
      alignment: .right
    )
  }
}
