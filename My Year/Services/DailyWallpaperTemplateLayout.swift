import UIKit

struct DailyWallpaperTemplateMetrics {
  let size: CGSize
  let unit: CGFloat

  private let contentWidthRatio: CGFloat = 0.84
  private let maximumContentWidth: CGFloat = 370
  private let bottomDividerRatio: CGFloat = 0.83
  private let headerHeightValue: CGFloat = 24
  private let headerDividerGap: CGFloat = 16
  private let dividerGridGap: CGFloat = 22
  private let messageAnchorRatio: CGFloat = 0.902

  private let classicContentYRatio: CGFloat = 0.28
  private let classicMaxGridBottomRatio: CGFloat = 0.81
  private let classicPreferredGridHeightRatio: CGFloat = 0.49
  private let classicPreferredGridHeight: CGFloat = 410
  private let classicMinimumGridHeight: CGFloat = 215

  private let largeClockContentYRatio: CGFloat = 0.52
  private let largeClockContentYOffset: CGFloat = 72
  private let largeClockMinimumGridHeight: CGFloat = 144

  private let minimalLabelToProgressGap: CGFloat = 54
  private let minimalProgressBarHeight: CGFloat = 8

  var contentWidth: CGFloat {
    min(size.width * contentWidthRatio, maximumContentWidth * unit)
  }

  var contentX: CGFloat {
    (size.width - contentWidth) / 2
  }

  var headerHeight: CGFloat {
    headerHeightValue * unit
  }

  var headerDividerYOffset: CGFloat {
    headerHeight + (headerDividerGap * unit)
  }

  var gridYOffset: CGFloat {
    headerDividerYOffset + (dividerGridGap * unit)
  }

  var bottomDividerY: CGFloat {
    size.height * bottomDividerRatio
  }

  var bottomDividerGap: CGFloat {
    headerDividerGap * unit
  }

  var messageYRatio: CGFloat {
    messageAnchorRatio
  }

  var progressBarHeight: CGFloat {
    minimalProgressBarHeight * unit
  }

  func layout(contentY: CGFloat) -> DailyWallpaperTemplateLayout {
    DailyWallpaperTemplateLayout(
      contentX: contentX,
      contentY: contentY,
      contentWidth: contentWidth,
      unit: unit
    )
  }

  func classicLayout() -> DailyWallpaperTemplateLayout {
    layout(contentY: size.height * classicContentYRatio)
  }

  func classicGridHeight(gridY: CGFloat) -> CGFloat {
    let maxGridBottom = size.height * classicMaxGridBottomRatio
    let maxGridHeight = max(classicMinimumGridHeight * unit, maxGridBottom - gridY)
    let preferredGridHeight = max(
      size.height * classicPreferredGridHeightRatio,
      classicPreferredGridHeight * unit
    )

    return min(preferredGridHeight, maxGridHeight)
  }

  func largeClockLayout() -> DailyWallpaperTemplateLayout {
    let contentY = min(
      size.height * largeClockContentYRatio + (largeClockContentYOffset * unit),
      bottomDividerY - gridYOffset - (largeClockMinimumGridHeight * unit) - bottomDividerGap
    )

    return layout(contentY: contentY)
  }

  func largeClockGridHeight(gridY: CGFloat) -> CGFloat {
    max(largeClockMinimumGridHeight * unit, bottomDividerY - gridY - bottomDividerGap)
  }

  func minimalLayout(progressBarY: CGFloat) -> DailyWallpaperTemplateLayout {
    layout(contentY: progressBarY - (minimalLabelToProgressGap * unit))
  }

  func minimalProgressBarY() -> CGFloat {
    bottomDividerY - bottomDividerGap - progressBarHeight
  }
}

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
