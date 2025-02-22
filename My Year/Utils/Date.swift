import Foundation

/// Checks if a given date is the same as today.
///
/// - Parameter date: The date to check.
/// - Returns: `true` if the given date is today, `false` otherwise.
public func isToday(date: Date) -> Bool {
  let calendar = Calendar.current
  let today = calendar.startOfDay(for: Date())
  let inputDate = calendar.startOfDay(for: date)
  return inputDate == today
}

/// Formats a given date into a string.
///
/// - Parameter date: The date to format.
/// - Returns: A string representation of the date.
///
/// Example:
/// ```
/// Input: Date object representing January 15, 2024
/// Output: "2024-01-15"
/// ```
public func customDateFormatter(date: Date) -> String {
  let dateFormatter = DateFormatter()
  dateFormatter.dateFormat = "yyyy-MM-dd"
  return dateFormatter.string(from: date)
}
