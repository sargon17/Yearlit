@testable import My_Year
import Foundation
import SharedModels
import SwiftData
import Testing

@MainActor
struct WidgetDeepLinkHandlingTests {
  @Test func quickAddCalendarsPreferLoadedStoreSnapshot() async throws {
    let calendar = CustomCalendar(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000111")!,
      name: "Loaded",
      color: "qs-blue",
      trackingType: .binary,
      trackingStartedAt: Date(),
      dailyTarget: 1
    )
    let store = try makeStore(shellCalendars: [calendar], fullCalendars: [])

    let calendars = currentWidgetQuickAddCalendars(store: store)

    #expect(calendars.map(\.id) == [calendar.id])
  }

  private func makeStore(
    shellCalendars: [CustomCalendar],
    fullCalendars: [CustomCalendar]
  ) throws -> CustomCalendarStore {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: HabitCalendarEntity.self,
      CalendarEntryEntity.self,
      DayValuationEntity.self,
      HabitStackEntity.self,
      HabitStackStepEntity.self,
      configurations: configuration
    )

    return CustomCalendarStore(
      container: container,
      dependencies: CustomCalendarStoreDependencies(
        fetchCalendars: { _ in fullCalendars },
        runMigration: { _ in },
        fetchCalendarShells: { _ in shellCalendars }
      )
    )
  }
}
