@testable import My_Year
import Foundation
import SharedModels
import Testing

@MainActor
struct AnalyticsCalendarTrackerTests {
  @Test func calendarCreationTracksCommonAndCreationProperties() {
    let state = AnalyticsState(defaults: makeDefaults())
    let analytics = Analytics(state: state)
    let client = FakeAnalyticsClient()
    analytics.replaceClient(client)
    let tracker = CalendarAnalyticsTracker(analytics: analytics, state: state)
    let calendar = makeCalendar(trackingType: .binary)

    tracker.trackCalendarCreated(calendar: calendar, isFirstCalendar: true)

    #expect(client.events.count == 1)
    #expect(client.events.first?.name == AnalyticsEvent.calendarCreated.rawValue)
    #expect(client.events.first?.bool("has_reminder_enabled") == false)
    #expect(client.events.first?.bool("has_backfilled_history") == false)
    #expect(client.events.first?.bool("is_first_calendar") == true)
    #expect(client.events.first?.string("cadence") == CalendarCadence.daily.rawValue)
    #expect(client.events.first?.string("tracking_type") == TrackingType.binary.rawValue)
  }

  @Test func firstCheckinAndPeriodFlagsFireOnce() {
    let defaults = makeDefaults()
    let state = AnalyticsState(defaults: defaults)
    let analytics = Analytics(state: state)
    let client = FakeAnalyticsClient()
    analytics.replaceClient(client)
    let tracker = CalendarAnalyticsTracker(analytics: analytics, state: state)
    let calendar = makeCalendar(trackingType: .binary)
    let entry = CalendarEntry(date: Date(), count: 1, completed: true)

    tracker.trackEntryMutation(
      calendar: calendar,
      oldEntry: nil,
      newEntry: entry,
      source: .calendar
    )
    tracker.trackEntryMutation(
      calendar: calendar,
      oldEntry: nil,
      newEntry: entry,
      source: .calendar
    )

    #expect(client.eventNames.filter { $0 == AnalyticsEvent.checkinCompleted.rawValue }.count == 2)
    #expect(client.eventNames.filter { $0 == AnalyticsEvent.firstCheckinCompleted.rawValue }.count == 1)
    #expect(client.eventNames.filter { $0 == AnalyticsEvent.periodCompleted.rawValue }.count == 2)
    #expect(state.hasCompletedFirstCheckin)
    #expect(state.hasCompletedFirstPeriod)
  }

  @Test func counterCalendarsDoNotEmitPeriodCompleted() {
    let state = AnalyticsState(defaults: makeDefaults())
    let analytics = Analytics(state: state)
    let client = FakeAnalyticsClient()
    analytics.replaceClient(client)
    let tracker = CalendarAnalyticsTracker(analytics: analytics, state: state)
    let calendar = makeCalendar(trackingType: .counter)

    tracker.trackEntryMutation(
      calendar: calendar,
      oldEntry: nil,
      newEntry: CalendarEntry(date: Date(), count: 1, completed: true),
      source: .notification
    )

    #expect(client.eventNames.contains(AnalyticsEvent.checkinCompleted.rawValue))
    #expect(!client.eventNames.contains(AnalyticsEvent.periodCompleted.rawValue))
    #expect(client.eventNames.contains(AnalyticsEvent.firstCheckinCompleted.rawValue))
  }

  @Test func analyticsGuardsFirstFlags() {
    let defaults = makeDefaults()
    let state = AnalyticsState(defaults: defaults)
    let analytics = Analytics(state: state)
    let client = FakeAnalyticsClient()
    analytics.replaceClient(client)

    analytics.markFirstCheckinCompleted()
    analytics.markFirstCheckinCompleted()
    analytics.markFirstPeriodCompleted()
    analytics.markFirstPeriodCompleted()

    #expect(client.eventNames.filter { $0 == AnalyticsEvent.firstCheckinCompleted.rawValue }.count == 1)
    #expect(client.personPropertySets.count == 2)
    #expect(state.hasCompletedFirstCheckin)
    #expect(state.hasCompletedFirstPeriod)
  }

  private func makeDefaults() -> UserDefaults {
    let suiteName = "analytics.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
  }

  private func makeCalendar(trackingType: TrackingType) -> CustomCalendar {
    CustomCalendar(
      name: "Run",
      color: "qs-emerald",
      cadence: .daily,
      trackingType: trackingType,
      trackingStartedAt: Date(),
      dailyTarget: 1
    )
  }
}

private final class FakeAnalyticsClient: AnalyticsClient {
  struct RecordedEvent {
    let name: String
    let properties: [String: AnalyticsPropertyValue]

    func bool(_ key: String) -> Bool? {
      guard case let .bool(value)? = properties[key] else { return nil }
      return value
    }

    func string(_ key: String) -> String? {
      guard case let .string(value)? = properties[key] else { return nil }
      return value
    }
  }

  private(set) var events: [RecordedEvent] = []
  private(set) var personPropertySets: [[String: AnalyticsPropertyValue]] = []

  var eventNames: [String] {
    events.map(\.name)
  }

  func track(_ event: AnalyticsEvent, properties: [String: AnalyticsPropertyValue]) {
    events.append(.init(name: event.rawValue, properties: properties))
  }

  func identify(distinctId _: String, properties _: [String: AnalyticsPropertyValue]) {}

  func setPersonProperties(_ properties: [String: AnalyticsPropertyValue]) {
    personPropertySets.append(properties)
  }
}
