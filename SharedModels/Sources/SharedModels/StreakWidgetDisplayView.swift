import SwiftUI

public struct StreakWidgetDisplayView: View {
    public let calendarName: String
    public let accentColor: Color
    public let streak: Int
    public let isAtRisk: Bool
    public let backgroundColor: Color
    public let textPrimaryColor: Color
    public let secondaryTextColor: Color
    public let renderingMode: WidgetStyle.RenderingMode

    public init(
        calendarName: String,
        accentColor: Color,
        streak: Int,
        isAtRisk: Bool,
        backgroundColor: Color,
        textPrimaryColor: Color,
        secondaryTextColor: Color = Color("text-secondary"),
        renderingMode: WidgetStyle.RenderingMode = .fullColor
    ) {
        self.calendarName = calendarName
        self.accentColor = accentColor
        self.streak = streak
        self.isAtRisk = isAtRisk
        self.backgroundColor = backgroundColor
        self.textPrimaryColor = textPrimaryColor
        self.secondaryTextColor = secondaryTextColor
        self.renderingMode = renderingMode
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack {
                if streak > 0 && !isAtRisk {
                    Text(String(format: String(localized: "your current %@ streak is:"), calendarName.lowercased()))
                } else if streak > 0 && isAtRisk {
                    Text(String(format: String(localized: "your current %@ streak is at risk"), calendarName.lowercased()))
                        .foregroundColor(renderingMode.isMonochrome ? .primary : Color("qs-red"))
                        .widgetAccentable(renderingMode.isMonochrome)
                } else {
                    Text(calendarName.lowercased())
                        .foregroundColor(renderingMode.isMonochrome ? .primary : Color("text-primary"))
                }
            }
            .foregroundColor(secondaryTextColor)
            .font(AppFont.mono(10))

            WidgetSeparator(renderingMode: renderingMode)
                .padding(.horizontal, -16)
                .padding(.bottom, 4)

            Spacer()

            if streak > 0 {
                Text("\(streak)")
                    .font(AppFont.mono(48))
                    .foregroundColor(accentColor)
                    .fontWeight(.heavy)
                    .widgetAccentable(renderingMode.isMonochrome)
            } else {
                Text(String(localized: "It's never late to start a new streak!"))
                    .font(AppFont.mono(12))
                    .foregroundColor(textPrimaryColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .background(backgroundColor)
    }
}
