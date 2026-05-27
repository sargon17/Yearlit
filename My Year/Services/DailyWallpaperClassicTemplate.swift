import UIKit

enum DailyWallpaperClassicTemplate {
  static func draw(
    in context: CGContext,
    size: CGSize,
    screenScale: CGFloat,
    progress: DailyWallpaperProgressData,
    palette: DailyWallpaperPalette
  ) {
    let unit = max(1, screenScale)
    let contentWidth = min(size.width * 0.84, 370 * unit)
    let contentX = (size.width - contentWidth) / 2
    let headerHeight: CGFloat = 24 * unit
    let separatorTop = headerHeight + (16 * unit)
    let gridTop = separatorTop + (22 * unit)
    let gridHeight = min(max(size.height * 0.24, 215 * unit), 280 * unit)
    let blockHeight = gridTop + gridHeight
    let contentY = min(size.height * 0.4, size.height - blockHeight - (150 * unit))

    DailyWallpaperDrawing.drawHeader(
      in: DailyWallpaperDrawing.aligned(
        CGRect(x: contentX, y: contentY, width: contentWidth, height: headerHeight)
      ),
      unit: unit,
      progress: progress,
      palette: palette
    )

    palette.separatorTop.setFill()
    context.fill(
      DailyWallpaperDrawing.aligned(CGRect(x: 0, y: contentY + separatorTop, width: size.width, height: unit))
    )
    palette.separatorBottom.setFill()
    context.fill(
      DailyWallpaperDrawing.aligned(
        CGRect(x: 0, y: contentY + separatorTop + unit, width: size.width, height: unit)
      )
    )

    DailyWallpaperDrawing.drawGrid(
      in: DailyWallpaperDrawing.aligned(
        CGRect(x: contentX, y: contentY + gridTop, width: contentWidth, height: gridHeight)
      ),
      unit: unit,
      progress: progress,
      palette: palette
    )
  }
}
