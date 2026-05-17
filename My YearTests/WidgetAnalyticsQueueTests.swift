import Foundation
import SharedModels
import Testing

struct WidgetAnalyticsQueueTests {
    @Test func enqueueAndDrainPreservesPayload() {
        let defaults = makeDefaults()
        let queue = WidgetAnalyticsQueue(defaults: defaults)

        queue.enqueueTimelineLoaded(properties: [
            "widget_kind": .string("habits"),
            "widget_family": .string("systemSmall"),
            "has_calendar": .bool(true)
        ])

        let events = queue.drain()

        #expect(events.count == 1)
        #expect(events.first?.name == "widget_timeline_loaded")
        #expect(events.first?.properties["widget_kind"] == .string("habits"))
        #expect(events.first?.properties["has_calendar"] == .bool(true))
    }

    @Test func doesNotDedupeUsageEventsOnSameDay() {
        let defaults = makeDefaults()
        let queue = WidgetAnalyticsQueue(defaults: defaults)

        queue.enqueueOpenedApp(properties: [
            "widget_kind": .string("year"),
            "widget_action": .string("open_app"),
            "destination": .string("home")
        ])
        queue.enqueueOpenedApp(properties: [
            "widget_kind": .string("year"),
            "widget_action": .string("open_app"),
            "destination": .string("home")
        ])

        #expect(queue.drain().count == 2)
    }

    @Test func deduplicatesTimelineLoadsOnSameDay() {
        let defaults = makeDefaults()
        let queue = WidgetAnalyticsQueue(defaults: defaults)

        queue.enqueueTimelineLoaded(properties: [
            "widget_kind": .string("habits"),
            "widget_family": .string("systemSmall"),
            "has_calendar": .bool(true)
        ])
        queue.enqueueTimelineLoaded(properties: [
            "widget_kind": .string("habits"),
            "widget_family": .string("systemSmall"),
            "has_calendar": .bool(true)
        ])

        #expect(queue.drain().count == 1)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "WidgetAnalyticsQueueTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
