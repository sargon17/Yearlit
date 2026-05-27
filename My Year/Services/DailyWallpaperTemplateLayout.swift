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
