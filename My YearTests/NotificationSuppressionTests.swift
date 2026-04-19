import Foundation
@testable import My_Year
import SharedModels
import Testing

struct NotificationSuppressionTests {
    @Test func binaryFulfilledOnlyWhenCompleted() {
        let calendar = makeCalendar(trackingType: .binary, dailyTarget: 1)
        let completed = CalendarEntry(date: Date(), count: 1, completed: true)
        let notCompleted = CalendarEntry(date: Date(), count: 1, completed: false)

        #expect(isEntryFulfilledForNotification(completed, calendar: calendar))
        #expect(!isEntryFulfilledForNotification(notCompleted, calendar: calendar))
    }

    @Test func counterFulfillmentRequiresPositiveValue() {
        let calendar = makeCalendar(trackingType: .counter, dailyTarget: 1)
        let positive = CalendarEntry(date: Date(), count: 2, completed: false)
        let zero = CalendarEntry(date: Date(), count: 0, completed: false)
        let negative = CalendarEntry(date: Date(), count: -1, completed: false)

        #expect(isEntryFulfilledForNotification(positive, calendar: calendar))
        #expect(!isEntryFulfilledForNotification(zero, calendar: calendar))
        #expect(!isEntryFulfilledForNotification(negative, calendar: calendar))
    }

    @Test func multipleDailyFulfillmentMatchesTargetThreshold() {
        let calendar = makeCalendar(trackingType: .multipleDaily, dailyTarget: 3)
        let belowTarget = CalendarEntry(date: Date(), count: 2, completed: false)
        let atTarget = CalendarEntry(date: Date(), count: 3, completed: true)
        let aboveTarget = CalendarEntry(date: Date(), count: 5, completed: true)

        #expect(!isEntryFulfilledForNotification(belowTarget, calendar: calendar))
        #expect(isEntryFulfilledForNotification(atTarget, calendar: calendar))
        #expect(isEntryFulfilledForNotification(aboveTarget, calendar: calendar))
    }

    @MainActor @Test func missingEntryDoesNotSuppress() {
        let store = CustomCalendarStore.shared
        let calendar = makeCalendar(name: "Suppression Missing Entry", trackingType: .binary, dailyTarget: 1)

        store.addCalendar(calendar)
        defer { store.deleteCalendar(id: calendar.id) }

        #expect(!shouldSuppressNotification(for: calendar, store: store))
    }
}

private func makeCalendar(
    name: String = "Notification Suppression Test Calendar",
    trackingType: TrackingType,
    dailyTarget: Int
) -> CustomCalendar {
    CustomCalendar(
        name: name,
        color: "#000000",
        trackingType: trackingType,
        dailyTarget: dailyTarget
    )
}
