import Foundation
import SharedModels

#if DEBUG
  @MainActor
  enum DebugSwipeCalendarSeeder {
    private static let argumentName = "-yearlitSeedSwipeCalendars"
    private static let colorNames = [
      "qs-orange", "qs-amber", "qs-yellow", "qs-lime", "qs-green",
      "qs-teal", "qs-cyan", "qs-blue", "qs-indigo", "qs-purple"
    ]

    static func seedIfRequested(onboarding: OnboardingManager) {
      let arguments = ProcessInfo.processInfo.arguments
      guard let argumentIndex = arguments.firstIndex(of: argumentName) else { return }

      let requestedCount = arguments.dropFirst(argumentIndex + 1).first.flatMap(Int.init) ?? 10
      let calendarCount = max(1, min(requestedCount, 20))
      Task { @MainActor in
        await seed(calendarCount: calendarCount, onboarding: onboarding)
      }
    }

    private static func seed(calendarCount: Int, onboarding: OnboardingManager) async {
      let store = CustomCalendarStore.shared
      await waitUntilLoaded(store)

      for calendar in store.snapshot.calendars {
        store.deleteCalendar(id: calendar.id)
      }
      await waitUntilCalendarCount(store, count: 0)

      let today = LocalDayCalendar.startOfDay(for: Date())
      let startDate = Calendar.current.date(byAdding: .day, value: -364, to: today) ?? today

      for index in 0..<calendarCount {
        store.addCalendar(
          CustomCalendar(
            name: "Swipe \(index + 1)",
            color: colorNames[index % colorNames.count],
            cadence: .daily,
            trackingType: trackingType(for: index),
            trackingStartedAt: startDate,
            dailyTarget: target(for: index),
            entries: entries(index: index, startDate: startDate, today: today),
            isArchived: false,
            recurringReminderEnabled: false,
            reminderTime: nil,
            unit: unit(for: index),
            defaultRecordValue: defaultRecordValue(for: index),
            reminderTimeZone: TimeZone.current.identifier,
            notificationPrivacyMode: .full,
            suppressWhenCompleted: true,
            additionalReminderTimes: [],
            streakProtectionEnabled: true,
            streakProtectionThreshold: 5
          )
        )
      }

      TimelinePreferenceStore.setMode(.your365)
      TimelinePreferenceManager.shared.refresh()
      onboarding.markAsSeen()
      await waitUntilCalendarCount(store, count: calendarCount)
    }

    private static func waitUntilLoaded(_ store: CustomCalendarStore) async {
      for _ in 0..<60 where store.snapshot.isLoading {
        try? await Task.sleep(nanoseconds: 50_000_000)
      }
    }

    private static func waitUntilCalendarCount(_ store: CustomCalendarStore, count: Int) async {
      for _ in 0..<80 where store.snapshot.calendars.count != count {
        try? await Task.sleep(nanoseconds: 50_000_000)
      }
    }

    private static func trackingType(for index: Int) -> TrackingType {
      switch index % 3 {
      case 1:
        return .counter
      case 2:
        return .multipleDaily
      default:
        return .binary
      }
    }

    private static func target(for index: Int) -> Int {
      trackingType(for: index) == .multipleDaily ? 3 : 1
    }

    private static func unit(for index: Int) -> UnitOfMeasure? {
      trackingType(for: index) == .counter ? .minutes : nil
    }

    private static func defaultRecordValue(for index: Int) -> Int? {
      trackingType(for: index) == .binary ? nil : 1
    }

    private static func entries(index: Int, startDate: Date, today: Date) -> [String: CalendarEntry] {
      var entries: [String: CalendarEntry] = [:]
      let calendar = Calendar.current
      let totalDays = max(1, calendar.dateComponents([.day], from: startDate, to: today).day ?? 364)

      for offset in 0...totalDays {
        guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else { continue }
        guard shouldCompleteEntry(calendarIndex: index, dayOffset: offset) else { continue }

        let count = countValue(calendarIndex: index, dayOffset: offset)
        entries[DayKeyFormatter.shared.string(from: date)] = CalendarEntry(
          date: date,
          count: count,
          completed: count > 0
        )
      }

      return entries
    }

    private static func shouldCompleteEntry(calendarIndex: Int, dayOffset: Int) -> Bool {
      ((dayOffset + calendarIndex) % 4) != 0 && ((dayOffset * (calendarIndex + 3)) % 17) != 0
    }

    private static func countValue(calendarIndex: Int, dayOffset: Int) -> Int {
      switch trackingType(for: calendarIndex) {
      case .binary:
        return 1
      case .counter:
        return 1 + ((dayOffset + calendarIndex) % 9)
      case .multipleDaily:
        return 1 + ((dayOffset + calendarIndex) % 3)
      }
    }
  }
#endif
