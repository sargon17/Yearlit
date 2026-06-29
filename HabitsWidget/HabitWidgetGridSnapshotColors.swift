import SharedModels
import SwiftUI

extension HabitWidgetGridSnapshotBuilder {
  func colorForDay(
    _ normalized: Date,
    today: Date,
    your365CellsByDate: [Date: Your365Cell],
    counterDotScale: Double
  ) -> Color {
    if let cell = your365CellsByDate[normalized], cell.usesYour365OnlyColor {
      return colorForYour365Cell(cell)
    }

    return colorForCalendarDay(
      normalized,
      today: today,
      your365CellsByDate: your365CellsByDate,
      counterDotScale: counterDotScale
    )
  }

  func colorForCalendarDay(
    _ normalized: Date,
    today: Date,
    your365CellsByDate: [Date: Your365Cell],
    counterDotScale: Double
  ) -> Color {
    let normalizedToday = normalizedBucketDate(for: today)

    if renderingMode.isMonochrome {
      return monochromeColorForCalendarDay(
        normalized,
        today: normalizedToday,
        counterDotScale: counterDotScale
      )
    }

    if normalized > normalizedToday {
      return futureDayColor(base: backgroundColor, overlay: textPrimaryColor, ratio: inactiveRatio)
    }

    guard let calendar, let entry = calendar.entry(for: normalized) else {
      return emptyDotColor(for: normalized, today: today, your365CellsByDate: your365CellsByDate)
    }

    switch calendar.trackingType {
    case .binary:
      return entry.completed
        ? Color(calendar.color)
        : emptyDotColor(for: normalized, today: today, your365CellsByDate: your365CellsByDate)
    case .counter:
      guard entry.hasLoggedValue else {
        return emptyDotColor(for: normalized, today: today, your365CellsByDate: your365CellsByDate)
      }
      let ratio = counterDotFillRatio(count: entry.count, precomputedScale: counterDotScale)
      return WidgetStyle.blendedColor(base: backgroundColor, overlay: Color(calendar.color), ratio: ratio)
    case .multipleDaily:
      guard entry.hasLoggedValue else {
        return emptyDotColor(for: normalized, today: today, your365CellsByDate: your365CellsByDate)
      }
      let opacity = multipleDailyDotFillRatio(count: entry.count, dailyTarget: calendar.dailyTarget)
      return Color(calendar.color).opacity(opacity)
    }
  }

  func monochromeColorForCalendarDay(
    _ normalized: Date,
    today normalizedToday: Date,
    counterDotScale: Double
  ) -> Color {
    if normalized > normalizedToday {
      return WidgetStyle.monochromeFutureDotColor()
    }

    guard let calendar, let entry = calendar.entry(for: normalized) else {
      return WidgetStyle.monochromePastDotColor()
    }

    switch calendar.trackingType {
    case .binary:
      if normalized == normalizedToday, entry.completed {
        return WidgetStyle.monochromeAccentColor()
      }
      return entry.completed
        ? WidgetStyle.monochromePrimaryColor().opacity(0.85) : WidgetStyle.monochromePastDotColor()
    case .counter:
      guard entry.hasLoggedValue else {
        return WidgetStyle.monochromePastDotColor()
      }
      let ratio = max(0.35, counterDotFillRatio(count: entry.count, precomputedScale: counterDotScale))
      return normalized == normalizedToday
        ? WidgetStyle.monochromeAccentColor().opacity(ratio)
        : WidgetStyle.monochromePrimaryColor().opacity(ratio)
    case .multipleDaily:
      guard entry.hasLoggedValue else {
        return WidgetStyle.monochromePastDotColor()
      }
      let opacity = max(
        0.35,
        multipleDailyDotFillRatio(count: entry.count, dailyTarget: calendar.dailyTarget)
      )
      return normalized == normalizedToday
        ? WidgetStyle.monochromeAccentColor().opacity(opacity)
        : WidgetStyle.monochromePrimaryColor().opacity(opacity)
    }
  }

  func isAccentedDay(_ date: Date, today: Date) -> Bool {
    guard renderingMode.isMonochrome else { return false }

    let normalized = normalizedBucketDate(for: date)
    let normalizedToday = normalizedBucketDate(for: today)

    guard normalized <= normalizedToday, let calendar, let entry = calendar.entry(for: normalized) else {
      return false
    }

    switch calendar.trackingType {
    case .binary:
      return normalized == normalizedToday && entry.completed
    case .counter, .multipleDaily:
      return normalized == normalizedToday && entry.hasLoggedValue
    }
  }

  func emptyDotColor(
    for normalized: Date,
    today: Date,
    your365CellsByDate: [Date: Your365Cell]
  ) -> Color {
    if let cell = your365CellsByDate[normalized], cell.usesYour365OnlyColor {
      return colorForYour365Cell(cell)
    }

    return normalized == normalizedBucketDate(for: today)
      ? activeDayColor(base: backgroundColor, overlay: textPrimaryColor)
      : missedDayColor(base: backgroundColor, overlay: textPrimaryColor)
  }

  func colorForYour365Cell(_ cell: Your365Cell) -> Color {
    if renderingMode.isMonochrome {
      return monochromeColorForYour365Cell(cell)
    }

    guard let calendar else {
      return missedDayColor(base: backgroundColor, overlay: textPrimaryColor)
    }

    return fullColorForYour365Cell(cell, calendar: calendar)
  }

  func monochromeColorForYour365Cell(_ cell: Your365Cell) -> Color {
    switch cell.state {
    case .completed:
      return WidgetStyle.monochromePrimaryColor()
    case .todayPending:
      return WidgetStyle.monochromeAccentColor()
    case .missed:
      return WidgetStyle.monochromePastDotColor()
    case .future:
      return WidgetStyle.monochromeFutureDotColor()
    case .notTracked:
      return WidgetStyle.monochromePastDotColor().opacity(0.65)
    }
  }

  func fullColorForYour365Cell(_ cell: Your365Cell, calendar: CustomCalendar) -> Color {
    switch cell.state {
    case .completed:
      return Color(calendar.color)
    case .todayPending:
      return activeDayColor(base: backgroundColor, overlay: textPrimaryColor)
    case .missed:
      return missedDayColor(base: backgroundColor, overlay: textPrimaryColor)
    case .future:
      return futureDayColor(base: backgroundColor, overlay: textPrimaryColor, ratio: inactiveRatio)
    case .notTracked:
      return inactiveDayColor(base: backgroundColor, overlay: textPrimaryColor, ratio: inactiveRatio)
    }
  }
}

private extension Your365Cell {
  var usesYour365OnlyColor: Bool {
    state == .future || state == .notTracked
  }
}

private extension CalendarEntry {
  var hasLoggedValue: Bool {
    count >= 1
  }
}

private func futureDayColor(base: Color, overlay: Color, ratio: Double) -> Color {
  WidgetStyle.futureDotColor(surface: base, text: overlay, ratio: ratio)
}

private func missedDayColor(base: Color, overlay: Color) -> Color {
  WidgetStyle.missedDotColor(surface: base, text: overlay)
}

private func inactiveDayColor(base: Color, overlay: Color, ratio: Double) -> Color {
  WidgetStyle.inactiveDotColor(surface: base, text: overlay, ratio: ratio)
}

private func activeDayColor(base: Color, overlay: Color) -> Color {
  WidgetStyle.activeDotColor(surface: base, text: overlay, ratio: 0.12)
}
