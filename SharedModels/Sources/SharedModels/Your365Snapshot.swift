import Foundation

public enum Your365CellState: String, Codable, CaseIterable {
    case completed
    case missed
    case todayPending
    case future
    case notTracked
}

public struct Your365Cell: Codable, Hashable, Identifiable {
    public let id: String
    public let date: Date
    public let dayNumber: Int
    public let state: Your365CellState

    public init(date: Date, dayNumber: Int, state: Your365CellState) {
        let canonicalDate = LocalDayCalendar.startOfDay(for: date)
        id = DayKeyFormatter.shared.string(from: canonicalDate)
        self.date = canonicalDate
        self.dayNumber = dayNumber
        self.state = state
    }
}

public struct Your365Snapshot: Codable, Hashable {
    public let cells: [Your365Cell]
    public let trackingStartedAt: Date
    /// The cell whose date matches today, precomputed during buildCells. nil if today is not in the window.
    public let todayCell: Your365Cell?

    public init(cells: [Your365Cell], trackingStartedAt: Date, todayCell: Your365Cell? = nil) {
        self.cells = cells
        self.trackingStartedAt = LocalDayCalendar.startOfDay(for: trackingStartedAt)
        self.todayCell = todayCell
    }

    public static func makeFirstYear(
        trackingStartedAt: Date,
        completedDates: Set<Date>,
        today: Date
    ) -> Your365Snapshot {
        let start = LocalDayCalendar.startOfDay(for: trackingStartedAt)
        let (cells, todayCell) = buildCells(
            anchor: start,
            trackingStart: start,
            completedDates: completedDates,
            today: today
        )
        return Your365Snapshot(cells: cells, trackingStartedAt: start, todayCell: todayCell)
    }

    public static func makeLatest365Days(
        trackingStartedAt: Date,
        completedDates: Set<Date>,
        today: Date
    ) -> Your365Snapshot {
        let start = LocalDayCalendar.startOfDay(for: trackingStartedAt)
        let todayStart = LocalDayCalendar.startOfDay(for: today)
        guard let rangeStart = LocalDayCalendar.calendar.date(byAdding: .day, value: -364, to: todayStart) else {
            return Your365Snapshot(cells: [], trackingStartedAt: start, todayCell: nil)
        }
        let (cells, todayCell) = buildCells(
            anchor: rangeStart,
            trackingStart: start,
            completedDates: completedDates,
            today: today
        )
        return Your365Snapshot(cells: cells, trackingStartedAt: start, todayCell: todayCell)
    }

    /// Builds 365 cells starting from `anchor`.
    /// Days before `trackingStart` are marked `.notTracked` (used by the rolling-365 view).
    /// Returns the cell array and the cell matching today (if any) for O(1) lookup at call sites.
    private static func buildCells(
        anchor: Date,
        trackingStart: Date,
        completedDates: Set<Date>,
        today: Date
    ) -> (cells: [Your365Cell], todayCell: Your365Cell?) {
        let calendar = LocalDayCalendar.calendar
        let todayStart = LocalDayCalendar.startOfDay(for: today)
        let completed = normalizeDates(completedDates)

        var cells: [Your365Cell] = []
        var todayCell: Your365Cell? = nil
        cells.reserveCapacity(365)
        for offset in 0 ..< 365 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: anchor) else { continue }
            let canonicalDate = date
            let state: Your365CellState
            if canonicalDate < trackingStart {
                state = .notTracked
            } else if canonicalDate > todayStart {
                state = .future
            } else if completed.contains(canonicalDate) {
                state = .completed
            } else if canonicalDate == todayStart {
                state = .todayPending
            } else {
                state = .missed
            }
            let cell = Your365Cell(date: canonicalDate, dayNumber: offset + 1, state: state)
            cells.append(cell)
            if canonicalDate == todayStart {
                todayCell = cell
            }
        }
        return (cells, todayCell)
    }

    private static func normalizeDates(_ dates: Set<Date>) -> Set<Date> {
        Set(dates.map { LocalDayCalendar.startOfDay(for: $0) })
    }
}

public extension CustomCalendar {
    func your365CompletedDates() -> Set<Date> {
        Set(
            entries.values.compactMap { entry in
                // Counter calendars persist `completed == false` even when `count > 0`.
                switch trackingType {
                case .binary:
                    return entry.completed ? entry.date : nil
                case .counter:
                    return entry.hasLoggedCount ? entry.date : nil
                case .multipleDaily:
                    return entry.completed ? entry.date : nil
                }
            }
        )
    }

    /// Returns true while today is still within the first 365 days of tracking.
    func isWithinFirstYear(today: Date) -> Bool {
        let trackingStart = LocalDayCalendar.startOfDay(for: trackingStartedAt)
        let todayStart = LocalDayCalendar.startOfDay(for: today)
        guard let maturityBoundary = LocalDayCalendar.calendar.date(byAdding: .day, value: 364, to: trackingStart) else {
            return false
        }
        return todayStart <= maturityBoundary
    }

    func makeYour365Snapshot(completedDates: Set<Date>, today: Date = Date()) -> Your365Snapshot? {
        guard cadence == .daily else { return nil }
        guard !isArchived else { return nil }

        let trackingStart = LocalDayCalendar.startOfDay(for: trackingStartedAt)

        if isWithinFirstYear(today: today) {
            return Your365Snapshot.makeFirstYear(
                trackingStartedAt: trackingStart,
                completedDates: completedDates,
                today: today
            )
        }

        return Your365Snapshot.makeLatest365Days(
            trackingStartedAt: trackingStart,
            completedDates: completedDates,
            today: today
        )
    }

    func makeFirstYearYour365Snapshot(completedDates: Set<Date>, today: Date = Date()) -> Your365Snapshot? {
        guard cadence == .daily else { return nil }
        return isArchived ? nil : Your365Snapshot.makeFirstYear(
            trackingStartedAt: trackingStartedAt,
            completedDates: completedDates,
            today: today
        )
    }
}
