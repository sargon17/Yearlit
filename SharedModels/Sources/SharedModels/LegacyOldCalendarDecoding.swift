import Foundation

@available(iOS 17.0, macOS 14.0, *)
extension LegacyDataMigrator {
  private struct OldCalendar: Codable {
    let id: UUID
    var name: String
    var color: String
    var trackingType: TrackingType
    var entries: [String: CalendarEntry]
  }

  static func decodeOldCalendars(from data: Data) -> [CustomCalendar]? {
    guard let oldCalendars = try? JSONDecoder().decode([OldCalendar].self, from: data) else {
      return nil
    }

    return oldCalendars.enumerated().map { index, old in
      CustomCalendar(
        id: old.id,
        name: old.name,
        color: old.color,
        trackingType: old.trackingType,
        trackingStartedAt: legacyTrackingStart(for: old.entries),
        dailyTarget: old.trackingType == .multipleDaily ? 2 : 1,
        entries: old.entries,
        isArchived: false,
        recurringReminderEnabled: false,
        reminderTime: nil,
        order: index,
        unit: nil,
        defaultRecordValue: nil,
        currencySymbol: nil
      )
    }
  }

  private static func legacyTrackingStart(for entries: [String: CalendarEntry]) -> Date {
    let bucketDates = entries.map { legacyDayKey, entry in
      legacyDate(from: legacyDayKey) ?? LocalDayCalendar.startOfDay(for: entry.date)
    }

    return bucketDates.min() ?? LocalDayCalendar.startOfDay(for: Date())
  }

  private static func legacyDate(from dayKey: String) -> Date? {
    guard let date = DayKeyFormatter.shared.date(from: dayKey) else { return nil }
    return LocalDayCalendar.startOfDay(for: date)
  }
}
