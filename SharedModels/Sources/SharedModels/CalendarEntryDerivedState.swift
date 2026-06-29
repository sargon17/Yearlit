import Foundation

extension CalendarEntry {
    public var hasLoggedCount: Bool {
        count >= 1
    }
}

extension CustomCalendar {
    public func checkInEntry(
        date: Date,
        existingEntry: CalendarEntry?,
        value: Int? = nil
    ) -> CalendarEntry? {
        guard !isArchived && source == .manual else { return nil }

        switch trackingType {
        case .binary:
            guard existingEntry?.completed != true else { return nil }
            return CalendarEntry(date: date, count: max(1, existingEntry?.count ?? 1), completed: true)
        case .counter:
            guard let addValue = resolvedCheckInValue(value) else { return nil }
            let newCount = (existingEntry?.count ?? 0) + addValue
            return CalendarEntry(date: date, count: newCount, completed: newCount > 0)
        case .multipleDaily:
            guard let addValue = resolvedCheckInValue(value) else { return nil }
            let newCount = (existingEntry?.count ?? 0) + addValue
            return CalendarEntry(date: date, count: newCount, completed: newCount >= dailyTarget)
        }
    }

    public func resolvedCheckInValue(_ value: Int?) -> Int? {
        let addValue = value ?? max(1, defaultRecordValue ?? 1)
        return addValue > 0 ? addValue : nil
    }
}
