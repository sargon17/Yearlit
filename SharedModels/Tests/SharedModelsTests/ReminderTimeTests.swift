import Foundation
import Testing

@testable import SharedModels

struct ReminderTimeTests {
  @Test func toDateUsesReferenceDateAndStoredTime() throws {
    let referenceDate = try #require(makeDate(year: 2026, month: 2, day: 3, hour: 12, minute: 30))
    let date = ReminderTime(hour: 8, minute: 15).toDate(referenceDate: referenceDate)
    let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)

    #expect(components.year == 2026)
    #expect(components.month == 2)
    #expect(components.day == 3)
    #expect(components.hour == 8)
    #expect(components.minute == 15)
  }

  @Test func toDateClampsInvalidPersistedValues() throws {
    let referenceDate = try #require(makeDate(year: 2026, month: 2, day: 3, hour: 12, minute: 30))
    let date = ReminderTime(hour: 99, minute: -4).toDate(referenceDate: referenceDate)
    let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)

    #expect(components.year == 2026)
    #expect(components.month == 2)
    #expect(components.day == 3)
    #expect(components.hour == 23)
    #expect(components.minute == 0)
  }

  private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date? {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = .current
    return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))
  }
}
