import Foundation
import SharedModels
import Testing

struct AppleHealthCalendarModelTests {
  @Test func customCalendarDecodesMissingSourceAsManual() throws {
    let json = """
      {
        "id": "00000000-0000-0000-0000-000000000001",
        "name": "Walking",
        "color": "qs-amber",
        "cadence": "daily",
        "trackingType": "multipleDaily",
        "trackingStartedAt": 725846400,
        "dailyTarget": 8000,
        "order": 0,
        "isArchived": false,
        "recurringReminderEnabled": false,
        "notificationPrivacyMode": "full",
        "suppressWhenCompleted": true,
        "additionalReminderTimes": [],
        "streakProtectionEnabled": true,
        "streakProtectionThreshold": 5,
        "entries": {}
      }
      """

    let calendar = try JSONDecoder().decode(CustomCalendar.self, from: #require(json.data(using: .utf8)))

    #expect(calendar.source == .manual)
  }

  @Test func appleHealthMetricMapperCreatesTargetEntries() {
    let belowTarget = makeDate(year: 2026, month: 1, day: 2)
    let aboveTarget = makeDate(year: 2026, month: 1, day: 3)

    let entries = AppleHealthMetricEntryMapper.entries(
      from: [
        belowTarget: 7_999,
        aboveTarget: 8_001,
        makeDate(year: 2026, month: 1, day: 4): 0
      ],
      target: 8_000
    )

    #expect(entries["2026-01-02"]?.count == 7_999)
    #expect(entries["2026-01-02"]?.completed == false)
    #expect(entries["2026-01-03"]?.count == 8_001)
    #expect(entries["2026-01-03"]?.completed == true)
    #expect(entries["2026-01-04"] == nil)
  }

  @Test func targetRecomputeUpdatesCompletionWithoutChangingCounts() {
    let calendar = CustomCalendar(
      name: "Walking",
      color: "qs-amber",
      cadence: .daily,
      trackingType: .binary,
      trackingStartedAt: makeDate(year: 2026, month: 1, day: 1),
      dailyTarget: 8_000,
      entries: [
        "2026-01-02": CalendarEntry(
          date: makeDate(year: 2026, month: 1, day: 2),
          count: 7_000,
          completed: false
        ),
        "2026-01-03": CalendarEntry(
          date: makeDate(year: 2026, month: 1, day: 3),
          count: 9_000,
          completed: true
        )
      ],
      unit: .steps,
      source: .appleHealthSteps
    )

    let updated = calendar.recomputingCompletionForTarget(7_500)

    #expect(updated.dailyTarget == 7_500)
    #expect(updated.entries["2026-01-02"]?.count == 7_000)
    #expect(updated.entries["2026-01-02"]?.completed == false)
    #expect(updated.entries["2026-01-03"]?.count == 9_000)
    #expect(updated.entries["2026-01-03"]?.completed == true)
  }

  private func makeDate(year: Int, month: Int, day: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = .gmt
    return calendar.date(from: DateComponents(year: year, month: month, day: day))!
  }
}
