import SharedModels
import SwiftUI

struct MilestoneDivider: View {
    let lightColor: Color
    let darkColor: Color

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(lightColor)
                .frame(height: 1)
            Rectangle()
                .fill(darkColor)
                .frame(height: 1)
                .offset(y: -0.5)
        }
    }
}

struct MilestoneGridView: View {
    let calendar: CustomCalendar
    let dates: [Date]
    let foregroundColor: Color

    var body: some View {
        GeometryReader { geometry in
            let dotSize: CGFloat = 10
            let availableWidth = max(0, geometry.size.width)
            let availableHeight = max(1, geometry.size.height)
            let layout = WidgetStyle.gridLayout(
                count: dates.count,
                dotSize: dotSize,
                availableWidth: availableWidth,
                availableHeight: availableHeight
            )

            VStack(spacing: layout.verticalSpacing) {
                ForEach(0 ..< layout.rows, id: \.self) { row in
                    HStack(spacing: layout.horizontalSpacing) {
                        ForEach(0 ..< layout.columns, id: \.self) { col in
                            let dayIndex = row * layout.columns + col
                            if dayIndex < dates.count {
                                GridDot(color: dotColor(for: dates[dayIndex]), dotSize: dotSize)
                            } else {
                                Color.clear.frame(width: dotSize, height: dotSize)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func dotColor(for date: Date) -> Color {
        let bucketDate = calendar.bucketDate(for: date)
        let todayBucket = calendar.bucketDate(for: Date())
        if bucketDate > todayBucket {
            return foregroundColor.opacity(0.12)
        }

        let emptyOpacity = bucketDate == todayBucket ? 0.25 : 0.12
        let entry = entry(for: calendar, date: date)
        switch calendar.trackingType {
        case .binary:
            return entry?.completed == true ? foregroundColor : foregroundColor.opacity(emptyOpacity)
        case .counter:
            guard let entry, entry.hasLoggedCount else { return foregroundColor.opacity(emptyOpacity) }
            let ratio = counterDotFillRatio(count: entry.count, counts: calendar.entries.values.map(\.count))
            return foregroundColor.opacity(ratio)
        case .multipleDaily:
            guard let entry, entry.hasLoggedCount else { return foregroundColor.opacity(emptyOpacity) }
            let ratio = multipleDailyDotFillRatio(count: entry.count, dailyTarget: calendar.dailyTarget)
            return foregroundColor.opacity(ratio)
        }
    }
}
