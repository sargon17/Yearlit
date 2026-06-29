import Foundation
import SharedModels

@MainActor
func handleWidgetOpenURL(_ url: URL) {
  guard let widgetContext = WidgetDeepLinkAnalytics.context(from: url) else { return }

  trackWidgetOpen(context: widgetContext)
  Analytics.shared.flushQueuedWidgetEvents()
}

@MainActor
func handleWidgetQuickAddURL(_ url: URL) {
  if let widgetContext = WidgetDeepLinkAnalytics.context(from: url) {
    Analytics.shared.track(
      .widgetQuickAddOpened,
      properties: widgetAnalyticsProperties(context: widgetContext)
    )
    trackWidgetOpen(context: widgetContext)
    Analytics.shared.flushQueuedWidgetEvents()
  }

  let idString = url.pathComponents.dropFirst().first
  guard let idString, let calendarId = UUID(uuidString: idString) else { return }

  let store = CustomCalendarStore.shared
  let calendars = currentWidgetQuickAddCalendars(store: store)
  guard let calendar = calendars.first(where: { $0.id == calendarId }) else { return }

  _ = try? CalendarShortcutService.checkIn(
    calendar: calendar,
    date: Date(),
    value: nil,
    store: store,
    source: .quickAddDeeplink
  )
}

@MainActor
func currentWidgetQuickAddCalendars(store: CustomCalendarStore) -> [CustomCalendar] {
  if !store.snapshot.calendars.isEmpty {
    return store.snapshot.calendars
  }
  return CustomCalendarStore.fetchCalendarsSnapshot()
}

@MainActor
private func trackWidgetOpen(context: WidgetDeepLinkAnalyticsContext) {
  Analytics.shared.track(
    .widgetOpenedApp,
    properties: widgetAnalyticsProperties(context: context)
  )
}

private func widgetAnalyticsProperties(
  context: WidgetDeepLinkAnalyticsContext
) -> [String: AnalyticsPropertyValue] {
  [
    "widget_kind": .string(context.widgetKind),
    "widget_action": .string(context.widgetAction),
    "destination": .string(context.destination)
  ]
}
