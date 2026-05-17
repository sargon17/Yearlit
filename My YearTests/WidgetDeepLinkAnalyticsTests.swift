import Foundation
import Testing
@testable import My_Year

struct WidgetDeepLinkAnalyticsTests {
  @Test func sanitizesUnknownWidgetValues() {
    let url = URL(string: "my-year://calendar/123?source=widget&widget_kind=hacked&widget_action=drop_db")!

    let context = WidgetDeepLinkAnalytics.context(from: url)

    #expect(context?.widgetKind == "unknown")
    #expect(context?.widgetAction == "open_calendar")
    #expect(context?.destination == "calendar")
  }

  @Test func preservesAllowedWidgetValues() {
    let url = URL(string: "my-year://quick-add/123?source=widget&widget_kind=habits&widget_action=quick_add")!

    let context = WidgetDeepLinkAnalytics.context(from: url)

    #expect(context?.widgetKind == "habits")
    #expect(context?.widgetAction == "quick_add")
    #expect(context?.destination == "quick_add")
  }

  @Test func ignoresNonWidgetSources() {
    let url = URL(string: "my-year://calendar/123?source=share&widget_kind=habits&widget_action=open_calendar")!

    #expect(WidgetDeepLinkAnalytics.context(from: url) == nil)
  }

  @Test func quickAddFallbackTracksBeforeCalendarValidation() {
    let client = RecordingAnalyticsClient()
    Analytics.shared.replaceClient(client)

    defer { Analytics.shared.replaceClient(NoopAnalyticsClient()) }

    let url = URL(string: "my-year://quick-add/not-a-uuid?source=widget&widget_kind=habits&widget_action=quick_add")!

    handleWidgetQuickAddURL(url)

    #expect(client.trackedEvents.map { $0.0 } == [.widgetQuickAddOpened, .widgetOpenedApp])
  }
}

private final class RecordingAnalyticsClient: AnalyticsClient {
  private(set) var trackedEvents: [(AnalyticsEvent, [String: AnalyticsPropertyValue])] = []

  func track(_ event: AnalyticsEvent, properties: [String: AnalyticsPropertyValue]) {
    trackedEvents.append((event, properties))
  }

  func identify(distinctId _: String, properties _: [String: AnalyticsPropertyValue]) {}
  func setPersonProperties(_ properties: [String: AnalyticsPropertyValue]) {}
}
