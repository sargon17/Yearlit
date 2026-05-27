import UIKit

enum DailyWallpaperLargeTemplate {
  static func draw(_ input: DailyWallpaperTemplateRenderInput) {
    let unit = max(1, input.screenScale)
    let contentWidth = min(input.size.width * 0.84, 370 * unit)
    let contentX = (input.size.width - contentWidth) / 2
    let separatorTop = (24 * unit) + (16 * unit)
    let gridTop = separatorTop + (22 * unit)
    let bottomSeparatorY = input.size.height * 0.83
    let minimumGridHeight = 144 * unit
    let contentY = min(
      input.size.height * 0.52 + (72 * unit),
      bottomSeparatorY - gridTop - minimumGridHeight - (16 * unit)
    )
    let gridY = contentY + gridTop
    let gridHeight = max(minimumGridHeight, bottomSeparatorY - gridY - (16 * unit))

    DailyWallpaperDrawing.drawHeader(
      in: DailyWallpaperDrawing.aligned(
        CGRect(x: contentX, y: contentY, width: contentWidth, height: 24 * unit)
      ),
      unit: unit,
      progress: input.progress,
      palette: input.palette
    )

    DailyWallpaperDrawing.drawDivider(
      y: contentY + separatorTop,
      size: input.size,
      unit: unit,
      palette: input.palette,
      context: input.context
    )

    DailyWallpaperDrawing.drawGrid(
      in: DailyWallpaperDrawing.aligned(
        CGRect(x: contentX, y: gridY, width: contentWidth, height: gridHeight)
      ),
      unit: unit,
      progress: input.progress,
      palette: input.palette
    )

    DailyWallpaperDrawing.drawDivider(
      y: bottomSeparatorY,
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
      yRatio: 0.902
    )
  }
}
