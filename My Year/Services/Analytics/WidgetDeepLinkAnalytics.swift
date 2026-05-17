import Foundation
import SharedModels

struct WidgetDeepLinkAnalyticsContext: Equatable {
  let widgetKind: String
  let widgetAction: String
  let destination: String
}

enum WidgetDeepLinkAnalytics {
  static func context(from url: URL) -> WidgetDeepLinkAnalyticsContext? {
    guard url.scheme == "my-year" else { return nil }

    let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    guard queryItems.first(where: { $0.name == "source" })?.value == "widget" else {
      return nil
    }

    let widgetKind = sanitizeWidgetKind(
      queryItems.first(where: { $0.name == "widget_kind" })?.value
    )
    let widgetAction = sanitizeWidgetAction(
      queryItems.first(where: { $0.name == "widget_action" })?.value,
      defaultValue: defaultAction(for: url.host)
    )
    let destination = destination(for: url.host, widgetAction: widgetAction)

    return .init(widgetKind: widgetKind, widgetAction: widgetAction, destination: destination)
  }

  private static func sanitizeWidgetKind(_ value: String?) -> String {
    switch value {
    case WidgetAnalyticsKind.year.rawValue,
      WidgetAnalyticsKind.habits.rawValue,
      WidgetAnalyticsKind.streak.rawValue:
      return value ?? "unknown"
    default:
      return "unknown"
    }
  }

  private static func sanitizeWidgetAction(_ value: String?, defaultValue: String) -> String {
    switch value {
    case "open_app", "open_calendar", "quick_add":
      return value ?? defaultValue
    default:
      return defaultValue
    }
  }

  private static func defaultAction(for host: String?) -> String {
    switch host {
    case "calendar":
      return "open_calendar"
    case "quick-add":
      return "quick_add"
    default:
      return "open_app"
    }
  }

  private static func destination(for host: String?, widgetAction: String) -> String {
    switch host {
    case "calendar":
      return "calendar"
    case "quick-add":
      return "quick_add"
    default:
      return widgetAction == "open_calendar" ? "calendar" : "home"
    }
  }
}
