import Foundation

enum CalendarNameValidator {
  static let maxLength = 50

  static func normalized(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  static func isValid(_ value: String) -> Bool {
    let value = normalized(value)
    return !value.isEmpty && value.count <= maxLength
  }
}
