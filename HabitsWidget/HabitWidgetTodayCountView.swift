import SharedModels
import SwiftUI

struct TodaysCountView: View {
  let count: Int
  let cadence: CalendarCadence
  let renderingMode: WidgetStyle.RenderingMode
  let label: String

  init(count: Int, cadence: CalendarCadence, renderingMode: WidgetStyle.RenderingMode) {
    self.count = count
    self.cadence = cadence
    self.renderingMode = renderingMode
    label = cadence == .weekly ? String(localized: "this week") : String(localized: "today")
  }

  var body: some View {
    HStack {
      Text("\(count)")
        .fontWeight(.bold)
        .widgetAccentable(renderingMode.isMonochrome && count >= 1)

      Text(" \(label)")
        .foregroundColor(
          renderingMode.isMonochrome ? WidgetStyle.monochromeSecondaryColor() : Color("text-tertiary")
        )
    }
    .lineLimit(1)
    .foregroundColor(
      renderingMode.isMonochrome ? WidgetStyle.monochromePrimaryColor() : Color("text-primary")
    )
    .font(AppFont.mono(9))
    .contentTransition(.numericText())
  }
}
