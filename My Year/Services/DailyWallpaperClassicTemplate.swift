import UIKit

enum DailyWallpaperClassicTemplate {
  static func draw(_ input: DailyWallpaperTemplateRenderInput) {
    let unit = max(1, input.screenScale)
    let contentWidth = min(input.size.width * 0.84, 370 * unit)
    let contentX = (input.size.width - contentWidth) / 2
    let headerHeight: CGFloat = 24 * unit
    let separatorTop = headerHeight + (16 * unit)
    let gridTop = separatorTop + (22 * unit)
    let contentY = input.size.height * 0.28
    let gridY = contentY + gridTop
    let maxGridBottom = input.size.height * 0.81
    let maxGridHeight = max(215 * unit, maxGridBottom - gridY)
    let gridHeight = min(max(input.size.height * 0.49, 410 * unit), maxGridHeight)

    DailyWallpaperDrawing.drawHeader(
      in: DailyWallpaperDrawing.aligned(
        CGRect(x: contentX, y: contentY, width: contentWidth, height: headerHeight)
      ),
      unit: unit,
      progress: input.progress,
      localizedText: input.localizedText,
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

    let bottomSeparatorY = min(gridY + gridHeight + (16 * unit), input.size.height * 0.83)
    DailyWallpaperDrawing.drawDivider(
      y: bottomSeparatorY,
      size: input.size,
      unit: unit,
      palette: input.palette,
      context: input.context
    )
  }
}
