import UIKit

struct DailyWallpaperTemplateLayout {
  let contentX: CGFloat
  let contentY: CGFloat
  let contentWidth: CGFloat
  let unit: CGFloat

  func rect(yOffset: CGFloat, height: CGFloat) -> CGRect {
    CGRect(
      x: contentX,
      y: contentY + (yOffset * unit),
      width: contentWidth,
      height: height * unit
    )
  }
}

struct DailyWallpaperTemplateRenderInput {
  let context: CGContext
  let size: CGSize
  let screenScale: CGFloat
  let progress: DailyWallpaperProgressData
  let palette: DailyWallpaperPalette
  let localizedText: DailyWallpaperLocalizedText
  let message: String?
}
