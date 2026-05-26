import SharedModels
import UIKit

enum DailyWallpaperRenderer {
  @MainActor
  static func render() -> UIImage? {
    let screen = UIScreen.main
    let pointSize = screen.bounds.size == .zero ? CGSize(width: 430, height: 932) : screen.bounds.size
    let screenScale = screen.nativeScale == 0 ? (screen.scale == 0 ? 3 : screen.scale) : screen.nativeScale
    let pixelSize = screen.nativeBounds.size == .zero
      ? CGSize(width: pointSize.width * screenScale, height: pointSize.height * screenScale)
      : screen.nativeBounds.size

    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true

    return UIGraphicsImageRenderer(size: pixelSize, format: format).image { context in
      drawWallpaper(in: context.cgContext, size: pixelSize, screenScale: screenScale)
    }
  }

  private static func drawWallpaper(in context: CGContext, size: CGSize, screenScale: CGFloat) {
    let backgroundColor = rgb(0x12, 0x12, 0x14)
    let primaryTextColor = rgb(0xFA, 0xFA, 0xFA)
    let secondaryTextColor = rgb(0xC2, 0xC2, 0xCA)
    let tertiaryTextColor = rgb(0x87, 0x87, 0x94)
    let orangeColor = UIColor(named: "qs-orange") ?? rgb(0xF9, 0x73, 0x16)
    let separatorTopColor = rgb(0x2A, 0x2A, 0x2E)
    let separatorBottomColor = rgb(0x10, 0x10, 0x12)
    let futureDotColor = blendedColor(
      base: backgroundColor,
      overlay: primaryTextColor,
      ratio: CGFloat(WidgetStyle.futureDotFillRatio)
    )
    let pastDotColor = blendedColor(
      base: backgroundColor,
      overlay: primaryTextColor,
      ratio: CGFloat(WidgetStyle.todayEmptyDotFillRatio)
    )

    backgroundColor.setFill()
    context.fill(CGRect(origin: .zero, size: size))

    let referenceDate = Date()
    let calendar = LocalDayCalendar.calendar
    let year = calendar.component(.year, from: referenceDate)
    let currentDayNumber = currentDayNumber(year: year, referenceDate: referenceDate, calendar: calendar)
    let numberOfDaysInYear = numberOfDaysInYear(year: year, calendar: calendar)
    let daysLeft = numberOfDaysInYear - currentDayNumber
    let percentComplete = Double(currentDayNumber) / Double(numberOfDaysInYear)

    let unit = max(1, screenScale)
    let contentWidth = min(size.width * 0.84, 370 * unit)
    let contentX = (size.width - contentWidth) / 2
    let headerHeight: CGFloat = 24 * unit
    let separatorTop = headerHeight + (16 * unit)
    let gridTop = separatorTop + (22 * unit)
    let gridHeight = min(max(size.height * 0.24, 215 * unit), 280 * unit)
    let blockHeight = gridTop + gridHeight
    let contentY = min(size.height * 0.4, size.height - blockHeight - (150 * unit))

    drawHeader(
      in: aligned(CGRect(x: contentX, y: contentY, width: contentWidth, height: headerHeight)),
      unit: unit,
      year: year,
      percentComplete: percentComplete,
      daysLeft: daysLeft,
      primaryTextColor: primaryTextColor,
      secondaryTextColor: secondaryTextColor,
      tertiaryTextColor: tertiaryTextColor,
      orangeColor: orangeColor
    )

    separatorTopColor.setFill()
    context.fill(aligned(CGRect(x: 0, y: contentY + separatorTop, width: size.width, height: unit)))
    separatorBottomColor.setFill()
    context.fill(aligned(CGRect(x: 0, y: contentY + separatorTop + unit, width: size.width, height: unit)))

    drawGrid(
      in: aligned(CGRect(x: contentX, y: contentY + gridTop, width: contentWidth, height: gridHeight)),
      unit: unit,
      numberOfDaysInYear: numberOfDaysInYear,
      currentDayNumber: currentDayNumber,
      pastDotColor: pastDotColor,
      todayDotColor: orangeColor,
      futureDotColor: futureDotColor
    )
  }

  private static func drawHeader(
    in rect: CGRect,
    unit: CGFloat,
    year: Int,
    percentComplete: Double,
    daysLeft: Int,
    primaryTextColor: UIColor,
    secondaryTextColor: UIColor,
    tertiaryTextColor: UIColor,
    orangeColor: UIColor
  ) {
    let yearAttributes = textAttributes(size: 18 * unit, weight: .heavy, color: primaryTextColor)
    let slashAttributes = textAttributes(size: 18 * unit, weight: .regular, color: tertiaryTextColor)
    let percentAttributes = textAttributes(size: 15 * unit, weight: .black, color: secondaryTextColor)
    let daysNumberAttributes = textAttributes(size: 15 * unit, weight: .heavy, color: orangeColor)
    let daysTextAttributes = textAttributes(size: 15 * unit, weight: .regular, color: tertiaryTextColor)

    let leftText = NSMutableAttributedString(string: "\(year)", attributes: yearAttributes)
    leftText.append(NSAttributedString(string: " / ", attributes: slashAttributes))
    leftText.append(NSAttributedString(string: String(format: "%.1f%%", percentComplete * 100), attributes: percentAttributes))

    let rightText = NSMutableAttributedString(string: "\(daysLeft)", attributes: daysNumberAttributes)
    rightText.append(NSAttributedString(string: " days left", attributes: daysTextAttributes))

    leftText.draw(at: CGPoint(x: rect.minX, y: rect.minY))

    let rightSize = rightText.size()
    rightText.draw(at: CGPoint(x: rect.maxX - rightSize.width, y: rect.minY))
  }

  private static func drawGrid(
    in rect: CGRect,
    unit: CGFloat,
    numberOfDaysInYear: Int,
    currentDayNumber: Int,
    pastDotColor: UIColor,
    todayDotColor: UIColor,
    futureDotColor: UIColor
  ) {
    let dotSize = alignedLength(max(5.5 * unit, min(7 * unit, rect.width / 46)))
    let layout = WidgetStyle.gridLayout(
      count: numberOfDaysInYear,
      dotSize: dotSize,
      availableWidth: rect.width,
      availableHeight: rect.height
    )

    for row in 0 ..< layout.rows {
      for column in 0 ..< layout.columns {
        let day = row * layout.columns + column
        guard day < numberOfDaysInYear else { continue }

        let color: UIColor
        if day >= currentDayNumber {
          color = futureDotColor
        } else if day == currentDayNumber - 1 {
          color = todayDotColor
        } else {
          color = pastDotColor
        }

        color.setFill()
        let dotRect = aligned(CGRect(
          x: rect.minX + CGFloat(column) * (dotSize + layout.horizontalSpacing),
          y: rect.minY + CGFloat(row) * (dotSize + layout.verticalSpacing),
          width: dotSize,
          height: dotSize
        ))
        UIBezierPath(roundedRect: dotRect, cornerRadius: alignedLength(2 * unit)).fill()
      }
    }
  }

  private static func textAttributes(size: CGFloat, weight: UIFont.Weight, color: UIColor) -> [NSAttributedString.Key: Any] {
    [
      .font: UIFont.monospacedSystemFont(ofSize: size, weight: weight),
      .foregroundColor: color
    ]
  }

  private static func currentDayNumber(year: Int, referenceDate: Date, calendar: Calendar) -> Int {
    let today = calendar.startOfDay(for: referenceDate)
    guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) else { return 0 }
    return (calendar.dateComponents([.day], from: startOfYear, to: today).day ?? 0) + 1
  }

  private static func numberOfDaysInYear(year: Int, calendar: Calendar) -> Int {
    let startOfYear = DateComponents(year: year, month: 1, day: 1)
    let endOfYear = DateComponents(year: year, month: 12, day: 31)
    guard let startDate = calendar.date(from: startOfYear),
          let endDate = calendar.date(from: endOfYear)
    else {
      return 365
    }

    return (calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 364) + 1
  }

  private static func blendedColor(base: UIColor, overlay: UIColor, ratio: CGFloat) -> UIColor {
    let clampedRatio = max(0, min(1, ratio))
    var baseRed: CGFloat = 0
    var baseGreen: CGFloat = 0
    var baseBlue: CGFloat = 0
    var baseAlpha: CGFloat = 0
    var overlayRed: CGFloat = 0
    var overlayGreen: CGFloat = 0
    var overlayBlue: CGFloat = 0
    var overlayAlpha: CGFloat = 0

    base.getRed(&baseRed, green: &baseGreen, blue: &baseBlue, alpha: &baseAlpha)
    overlay.getRed(&overlayRed, green: &overlayGreen, blue: &overlayBlue, alpha: &overlayAlpha)

    return UIColor(
      red: baseRed + (overlayRed - baseRed) * clampedRatio,
      green: baseGreen + (overlayGreen - baseGreen) * clampedRatio,
      blue: baseBlue + (overlayBlue - baseBlue) * clampedRatio,
      alpha: baseAlpha + (overlayAlpha - baseAlpha) * clampedRatio
    )
  }

  private static func aligned(_ rect: CGRect) -> CGRect {
    CGRect(
      x: alignedLength(rect.origin.x),
      y: alignedLength(rect.origin.y),
      width: alignedLength(rect.width),
      height: alignedLength(rect.height)
    )
  }

  private static func alignedLength(_ value: CGFloat) -> CGFloat {
    value.rounded()
  }

  private static func rgb(_ red: Int, _ green: Int, _ blue: Int) -> UIColor {
    UIColor(
      red: CGFloat(red) / 255,
      green: CGFloat(green) / 255,
      blue: CGFloat(blue) / 255,
      alpha: 1
    )
  }
}
