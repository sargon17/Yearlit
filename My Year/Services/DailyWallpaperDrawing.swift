import SharedModels
import SwiftUI
import UIKit

typealias DailyWallpaperTextAttributes = [NSAttributedString.Key: Any]

enum DailyWallpaperDrawing {
  static func drawHeader(
    in rect: CGRect,
    unit: CGFloat,
    progress: DailyWallpaperProgressData,
    localizedText: DailyWallpaperLocalizedText,
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
        string: localizedText.percentComplete,
        attributes: percentAttributes
      ))

    let rightText = attributedText(
      localizedText.daysLeftHeader,
      valueAttributes: daysNumberAttributes,
      defaultAttributes: daysTextAttributes
    )

    leftText.draw(at: CGPoint(x: rect.minX, y: rect.minY))

    let rightSize = rightText.size()
    rightText.draw(at: CGPoint(x: rect.maxX - rightSize.width, y: rect.minY))
  }

  private static func attributedText(
    _ text: DailyWallpaperLocalizedTextParts,
    valueAttributes: DailyWallpaperTextAttributes,
    defaultAttributes: DailyWallpaperTextAttributes
  ) -> NSMutableAttributedString {
    let attributedText = NSMutableAttributedString(string: text.prefix, attributes: defaultAttributes)
    attributedText.append(NSAttributedString(string: text.value, attributes: valueAttributes))
    attributedText.append(NSAttributedString(string: text.suffix, attributes: defaultAttributes))
    return attributedText
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

  static func drawDivider(
    y: CGFloat,
    size: CGSize,
    unit: CGFloat,
    palette: DailyWallpaperPalette,
    context: CGContext
  ) {
    palette.separatorTop.setFill()
    context.fill(
      aligned(
        CGRect(x: 0, y: y, width: size.width, height: unit)
      )
    )
    palette.separatorBottom.setFill()
    context.fill(
      aligned(
        CGRect(x: 0, y: y + unit, width: size.width, height: unit)
      )
    )
  }

  static func drawMessageIfNeeded(
    _ message: String?,
    in size: CGSize,
    unit: CGFloat,
    palette: DailyWallpaperPalette,
    yRatio: CGFloat = 0.78
  ) {
    guard let message = DailyWallpaperSettingsStore.sanitizedMessage(message) else { return }

    let font = AppFont.uiFont(.mono, size: 12 * unit, weight: .regular)
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    paragraphStyle.lineBreakMode = .byWordWrapping
    let attributes: DailyWallpaperTextAttributes = [
      .font: font,
      .foregroundColor: palette.secondaryText,
      .paragraphStyle: paragraphStyle
    ]
    let width = size.width * 0.46
    let maximumHeight = font.lineHeight * 2
    let measuredHeight = (message as NSString)
      .boundingRect(
        with: CGSize(width: width, height: maximumHeight),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: attributes,
        context: nil
      )
      .height
    let textHeight = min(max(font.lineHeight, ceil(measuredHeight)), maximumHeight)
    let centeredY = (size.height * yRatio) - (textHeight / 2)
    (message as NSString).draw(
      with: aligned(
        CGRect(
          x: (size.width - width) / 2,
          y: centeredY,
          width: width,
          height: textHeight
        )
      ),
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: attributes,
      context: nil
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
    weight: Font.Weight,
    color: UIColor
  ) -> DailyWallpaperTextAttributes {
    [
      .font: AppFont.uiFont(.mono, size: size, weight: weight),
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
