import Foundation
import SharedModels

enum ShowedUpMilestoneKind: String {
    case allTime
    case currentMonth
    case currentYear
}

enum ShowedUpMilestones {
    private static let allTimeMilestones: [Int] = [5, 10, 20, 30, 40, 50, 75, 100, 150]
    private static let currentMonthMilestones: [Int] = [3, 5, 7, 10, 14, 21, 28]
    private static let currentYearMilestones: [Int] = [7, 14, 30, 60, 90, 120, 180, 240, 300]

    static func milestone(for showedUpCount: Int, kind: ShowedUpMilestoneKind = .allTime) -> Int? {
        guard showedUpCount > 0 else { return nil }

        switch kind {
        case .allTime:
            if allTimeMilestones.contains(showedUpCount) {
                return showedUpCount
            }
            if showedUpCount > 150, showedUpCount % 50 == 0 {
                return showedUpCount
            }
            return nil
        case .currentMonth, .currentYear:
            return milestones(for: kind).contains(showedUpCount) ? showedUpCount : nil
        }
    }

    static func latestMilestone(for showedUpCount: Int, kind: ShowedUpMilestoneKind = .allTime) -> Int? {
        guard showedUpCount > 0 else { return nil }

        switch kind {
        case .allTime:
            if showedUpCount > 150 {
                return showedUpCount - (showedUpCount % 50)
            }
            return allTimeMilestones.filter { $0 <= showedUpCount }.max()
        case .currentMonth, .currentYear:
            return milestones(for: kind)
                .filter { $0 <= showedUpCount }
                .max()
        }
    }

    static func nextMilestone(after showedUpCount: Int, kind: ShowedUpMilestoneKind = .allTime) -> Int? {
        switch kind {
        case .allTime:
            if let nextBaseMilestone = allTimeMilestones.first(where: { $0 > showedUpCount }) {
                return nextBaseMilestone
            }
            return max(200, ((showedUpCount / 50) + 1) * 50)
        case .currentMonth, .currentYear:
            return milestones(for: kind).first(where: { $0 > showedUpCount })
        }
    }

    static func showedUpCount(
        for calendar: CustomCalendar,
        kind: ShowedUpMilestoneKind,
        today: Date = Date(),
        calendarSystem: Calendar = LocalDayCalendar.calendar
    ) -> Int {
        let todayBucket = calendar.bucketDate(for: today)

        let entriesByBucket = Dictionary(grouping: calendar.entries.values) { entry in
            calendar.bucketDate(for: entry.date)
        }

        return entriesByBucket.reduce(into: 0) { partial, item in
            let (bucketDate, entries) = item
            guard bucketDate <= todayBucket else { return }
            guard entries.contains(where: { didShowUp($0, calendar: calendar) }) else { return }

            switch kind {
            case .allTime:
                partial += 1
            case .currentMonth:
                if calendarSystem.isDate(bucketDate, equalTo: todayBucket, toGranularity: .month) {
                    partial += 1
                }
            case .currentYear:
                if calendarSystem.isDate(bucketDate, equalTo: todayBucket, toGranularity: .year) {
                    partial += 1
                }
            }
        }
    }

    private static func didShowUp(_ entry: CalendarEntry, calendar: CustomCalendar) -> Bool {
        switch calendar.trackingType {
        case .binary:
            return entry.completed
        case .counter, .multipleDaily:
            return entry.count > 0
        }
    }

    static func periodKey(
        for kind: ShowedUpMilestoneKind,
        today: Date = Date(),
        calendarSystem: Calendar = LocalDayCalendar.calendar
    ) -> String {
        let components: DateComponents

        switch kind {
        case .allTime:
            return "all"
        case .currentMonth:
            components = calendarSystem.dateComponents([.year, .month], from: today)
            let year = components.year ?? 0
            let month = components.month ?? 0
            return String(format: "%04d-%02d", year, month)
        case .currentYear:
            components = calendarSystem.dateComponents([.year], from: today)
            let year = components.year ?? 0
            return String(format: "%04d", year)
        }
    }

    private static func milestones(for kind: ShowedUpMilestoneKind) -> [Int] {
        switch kind {
        case .allTime:
            allTimeMilestones
        case .currentMonth:
            currentMonthMilestones
        case .currentYear:
            currentYearMilestones
        }
    }
}
