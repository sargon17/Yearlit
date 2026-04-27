import SharedModels
import SwiftDate
import SwiftUI

struct GridView: View {
    let calendar: CustomCalendar
    let store: CustomCalendarStore
    let handleDayTap: (Date) -> Void
    let dates: [Date]
    let year: Int

    private let dotSize: CGFloat = 10
    private let padding: CGFloat = 20

    var body: some View {
        let maxCount = getMaxCount(calendar: calendar)
        let mappedDays = dates.map {
            GridDay(date: $0, color: colorForDay($0, calendar: calendar, today: today, maxCount: maxCount))
        }

        DotGrid(
            items: mappedDays,
            dotSize: dotSize,
            padding: padding,
            dot: { day in
                GridDot(color: day.color, dotSize: dotSize)
            },
            onTap: { day in
                handleDayTap(day.date)
            }
        )
    }

    private var today: Date {
        Date().date
    }
}

private struct GridDay {
    let date: Date
    let color: Color
}
