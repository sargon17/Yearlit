import UIKit

enum DailyWallpaperLargeTemplate {
  static func draw(_ input: DailyWallpaperTemplateRenderInput) {
    let unit = max(1, input.screenScale)
    let metrics = DailyWallpaperTemplateMetrics(size: input.size, unit: unit)
    let layout = metrics.largeClockLayout()
    let gridY = layout.contentY + metrics.gridYOffset
    let gridHeight = metrics.largeClockGridHeight(gridY: gridY)

    DailyWallpaperDrawing.drawHeader(
      in: DailyWallpaperDrawing.aligned(
        CGRect(
          x: layout.contentX,
          y: layout.contentY,
          width: layout.contentWidth,
          height: metrics.headerHeight
        )
      ),
      unit: unit,
      progress: input.progress,
      localizedText: input.localizedText,
      palette: input.palette
    )

    DailyWallpaperDrawing.drawDivider(
      y: layout.contentY + metrics.headerDividerYOffset,
      size: input.size,
      unit: unit,
      palette: input.palette,
      context: input.context
    )

    DailyWallpaperDrawing.drawGrid(
      in: DailyWallpaperDrawing.aligned(
        CGRect(x: layout.contentX, y: gridY, width: layout.contentWidth, height: gridHeight)
      ),
      unit: unit,
      progress: input.progress,
      palette: input.palette
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
}
