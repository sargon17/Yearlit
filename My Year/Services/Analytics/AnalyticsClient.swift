import Foundation

protocol AnalyticsClient {
  func track(_ event: AnalyticsEvent, properties: [String: AnalyticsPropertyValue])
  func identify(distinctId: String, properties: [String: AnalyticsPropertyValue])
  func setPersonProperties(_ properties: [String: AnalyticsPropertyValue])
}

enum AnalyticsPropertyValue: Equatable {
  case string(String)
  case int(Int)
  case double(Double)
  case bool(Bool)

  var rawValue: Any {
    switch self {
    case let .string(value):
      value
    case let .int(value):
      value
    case let .double(value):
      value
    case let .bool(value):
      value
    }
  }
}

extension Dictionary where Key == String, Value == AnalyticsPropertyValue {
  var rawAnalyticsProperties: [String: Any] {
    mapValues(\.rawValue)
  }
}

struct NoopAnalyticsClient: AnalyticsClient {
  func track(_: AnalyticsEvent, properties _: [String: AnalyticsPropertyValue]) {}
  func identify(distinctId _: String, properties _: [String: AnalyticsPropertyValue]) {}
  func setPersonProperties(_: [String: AnalyticsPropertyValue]) {}
}
