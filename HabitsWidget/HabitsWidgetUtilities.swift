import Foundation
import SharedModels
import WidgetKit

func widgetFamilyName(_ family: WidgetFamily) -> String {
  switch family {
  case .systemSmall: return WidgetAnalyticsFamily.systemSmall.rawValue
  case .systemMedium: return WidgetAnalyticsFamily.systemMedium.rawValue
  case .systemLarge: return WidgetAnalyticsFamily.systemLarge.rawValue
  default: return WidgetAnalyticsFamily.other.rawValue
  }
}

func widgetDeepLink(
  host: String,
  calendarId: String?,
  widgetKind: String,
  widgetAction: String
) -> URL? {
  var components = URLComponents()
  components.scheme = "my-year"
  components.host = host
  components.queryItems = [
    URLQueryItem(name: "source", value: "widget"),
    URLQueryItem(name: "widget_kind", value: widgetKind),
    URLQueryItem(name: "widget_action", value: widgetAction)
  ]

  if let calendarId {
    components.path = "/\(calendarId)"
  }

  return components.url
}
