import SwiftUI

public struct HabitQuickAddAffordance: View {
    public let calendar: CustomCalendar
    public let referenceDate: Date
    public let renderingMode: WidgetStyle.RenderingMode

    public init(
        calendar: CustomCalendar,
        referenceDate: Date = Date(),
        renderingMode: WidgetStyle.RenderingMode = .fullColor
    ) {
        self.calendar = calendar
        self.referenceDate = referenceDate
        self.renderingMode = renderingMode
    }

    public var body: some View {
        let isCompleted = calendar.entry(for: referenceDate)?.completed == true
        let color = renderingMode.isMonochrome ? WidgetStyle.monochromeAccentColor() : Color(calendar.color)

        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(color.opacity(renderingMode.isMonochrome ? 0.18 : 0.1))
                .frame(width: 24, height: 24)

            Image(systemName: calendar.trackingType == .binary && isCompleted ? "minus" : "plus")
                .font(.system(size: 16))
                .foregroundColor(color)
                .widgetAccentable(renderingMode.isMonochrome)
        }
    }
}
