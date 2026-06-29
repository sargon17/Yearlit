import SharedModels
import SwiftUI

struct NumberOfDaysView: View {
  let numberOfDays: Int
  let cadence: CalendarCadence
  let renderingMode: WidgetStyle.RenderingMode
  private let textParts: LocalizedStreakTextParts

  init(numberOfDays: Int, cadence: CalendarCadence, renderingMode: WidgetStyle.RenderingMode) {
    self.numberOfDays = numberOfDays
    self.cadence = cadence
    self.renderingMode = renderingMode
    if cadence == .weekly {
      let format =
        numberOfDays == 1
        ? String(localized: "habitWidget.weekStreak")
        : String(localized: "habitWidget.weeksStreak")
      textParts = LocalizedStreakTextParts(format: format, value: numberOfDays)
    } else {
      let format =
        numberOfDays == 1
        ? String(localized: "habitWidget.dayStreak")
        : String(localized: "habitWidget.daysStreak")
      textParts = LocalizedStreakTextParts(format: format, value: numberOfDays)
    }
  }

  var body: some View {
    HStack(spacing: 0) {
      Text(textParts.prefix)
        .foregroundColor(
          renderingMode.isMonochrome ? WidgetStyle.monochromeSecondaryColor() : Color("text-tertiary")
        )
        .widgetAccentable(false)

      Text(textParts.value)
        .fontWeight(.bold)
        .foregroundColor(
          renderingMode.isMonochrome ? WidgetStyle.monochromePrimaryColor() : Color("text-primary")
        )
        .widgetAccentable(renderingMode.isMonochrome)

      Text(textParts.suffix)
        .foregroundColor(
          renderingMode.isMonochrome ? WidgetStyle.monochromeSecondaryColor() : Color("text-tertiary")
        )
        .widgetAccentable(false)
    }
    .lineLimit(1)
    .font(AppFont.mono(9))
    .contentTransition(.numericText())
  }
}

private struct LocalizedStreakTextParts {
  let prefix: String
  let value: String
  let suffix: String

  init(format: String, value: Int) {
    let components = format.components(separatedBy: "%lld")
    guard components.count == 2 else {
      assertionFailure("Streak localization must contain exactly one %lld placeholder.")
      prefix = ""
      self.value = value.formatted(.number.locale(.current))
      suffix = ""
      return
    }

    prefix = components[0]
    self.value = value.formatted(.number.locale(.current))
    suffix = components[1]
  }
}
