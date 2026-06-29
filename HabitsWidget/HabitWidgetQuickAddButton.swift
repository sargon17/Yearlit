import SharedModels
import SwiftUI

struct QuickAddButtonContent: View {
  let calendar: CustomCalendar
  let renderingMode: WidgetStyle.RenderingMode

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 3)
        .fill(
          renderingMode.isMonochrome
            ? WidgetStyle.monochromeSecondaryColor().opacity(0.16) : Color(calendar.color).opacity(0.1)
        )
        .frame(width: 24, height: 24)

      Image(
        systemName: "plus"
      )
      .font(.system(size: 16))
      .foregroundColor(
        renderingMode.isMonochrome ? WidgetStyle.monochromeAccentColor() : Color(calendar.color)
      )
      .widgetAccentable(renderingMode.isMonochrome)
    }
    .widgetAccentable(false)
  }
}
