import SharedModels
import UIKit

typealias DailyWallpaperTextAttributes = [NSAttributedString.Key: Any]

enum DailyWallpaperDrawing {
  static func drawHeader(
    in rect: CGRect,
    unit: CGFloat,
    progress: DailyWallpaperProgressData,
    palette: DailyWallpaperPalette
  ) {
    let yearAttributes = textAttributes(size: 18 * unit, weight: .heavy, color: palette.primaryText)
    let slashAttributes = textAttributes(size: 18 * unit, weight: .regular, color: palette.tertiaryText)
    let percentAttributes = textAttributes(size: 15 * unit, weight: .black, color: palette.secondaryText)
    let daysNumberAttributes = textAttributes(size: 15 * unit, weight: .heavy, color: palette.accent)
    let daysTextAttributes = textAttributes(size: 15 * unit, weight: .regular, color: palette.tertiaryText)

    let leftText = NSMutableAttributedString(string: "\(progress.year)", attributes: yearAttributes)
    leftText.append(NSAttributedString(string: " / ", attributes: slashAttributes))
    leftText.append(
      NSAttributedString(
        string: String(format: "%.1f%%", progress.percentComplete * 100),
        attributes: percentAttributes
      ))

    let rightText = NSMutableAttributedString(
      string: "\(progress.daysLeft)",
      attributes: daysNumberAttributes
    )
    rightText.append(NSAttributedString(string: " days left", attributes: daysTextAttributes))

    leftText.draw(at: CGPoint(x: rect.minX, y: rect.minY))

    let rightSize = rightText.size()
    rightText.draw(at: CGPoint(x: rect.maxX - rightSize.width, y: rect.minY))
  }

  static func drawGrid(
    in rect: CGRect,
    unit: CGFloat,
    progress: DailyWallpaperProgressData,
    palette: DailyWallpaperPalette
  ) {
    let dotSize = alignedLength(max(5.5 * unit, min(7 * unit, rect.width / 46)))
    let layout = WidgetStyle.gridLayout(
      count: progress.numberOfDaysInYear,
      dotSize: dotSize,
      availableWidth: rect.width,
      availableHeight: rect.height
    )

    for row in 0..<layout.rows {
      for column in 0..<layout.columns {
        let day = row * layout.columns + column
        guard day < progress.numberOfDaysInYear else { continue }

        let color: UIColor
        if day >= progress.currentDayNumber {
          color = palette.futureDot
        } else if day == progress.currentDayNumber - 1 {
          color = palette.accent
        } else {
          color = palette.pastDot
        }

        color.setFill()
        let dotRect = aligned(
          CGRect(
            x: rect.minX + CGFloat(column) * (dotSize + layout.horizontalSpacing),
            y: rect.minY + CGFloat(row) * (dotSize + layout.verticalSpacing),
            width: dotSize,
            height: dotSize
          ))
        UIBezierPath(roundedRect: dotRect, cornerRadius: alignedLength(2 * unit)).fill()
      }
    }
  }

  static func drawProgressBar(
    in rect: CGRect,
    progress: Double,
    palette: DailyWallpaperPalette,
    cornerRadius: CGFloat
  ) {
    palette.futureDot.setFill()
    UIBezierPath(roundedRect: rect, cornerRadius: alignedLength(cornerRadius)).fill()

    let progressWidth = max(rect.height, rect.width * CGFloat(max(0, min(1, progress))))
    palette.accent.setFill()
    UIBezierPath(
      roundedRect: CGRect(x: rect.minX, y: rect.minY, width: progressWidth, height: rect.height),
      cornerRadius: alignedLength(cornerRadius)
    ).fill()
  }

  static func drawMessageIfNeeded(
    _ message: String?,
    in size: CGSize,
    unit: CGFloat,
    palette: DailyWallpaperPalette
  ) {
    guard let message = DailyWallpaperSettingsStore.sanitizedMessage(message) else { return }

    let rect = CGRect(
      x: size.width * 0.14,
      y: size.height * 0.78,
      width: size.width * 0.72,
      height: 28 * unit
    )
    drawText(
      message,
      in: rect,
      attributes: textAttributes(size: 15 * unit, weight: .semibold, color: palette.secondaryText),
      alignment: .center
    )
  }

  static func drawText(
    _ text: String,
    in rect: CGRect,
    attributes: DailyWallpaperTextAttributes,
    alignment: NSTextAlignment
  ) {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = alignment
    paragraphStyle.lineBreakMode = .byTruncatingTail

    var attributes = attributes
    attributes[.paragraphStyle] = paragraphStyle
    (text as NSString).draw(in: aligned(rect), withAttributes: attributes)
  }

  static func textAttributes(
    size: CGFloat,
    weight: UIFont.Weight,
    color: UIColor
  ) -> DailyWallpaperTextAttributes {
    [
      .font: UIFont.monospacedSystemFont(ofSize: size, weight: weight),
      .foregroundColor: color
    ]
  }

  static func aligned(_ rect: CGRect) -> CGRect {
    CGRect(
      x: alignedLength(rect.origin.x),
      y: alignedLength(rect.origin.y),
      width: alignedLength(rect.width),
      height: alignedLength(rect.height)
    )
  }

  static func alignedLength(_ value: CGFloat) -> CGFloat {
    value.rounded()
  }
}
