import Foundation
@testable import My_Year
import Testing

struct RetentionNotificationTests {
    @Test func stageIdentifiersAreStable() {
        #expect(RetentionNotificationStage.day3.identifier == "app.retention.day3")
        #expect(RetentionNotificationStage.day7.identifier == "app.retention.day7")
        #expect(RetentionNotificationStage.day21.identifier == "app.retention.day21")
    }

    @Test func stageCopyMatchesSpec() {
        #expect(RetentionNotificationStage.day3.title == "Still building your year?")
        #expect(RetentionNotificationStage.day3.body == "A quick check-in can help you keep momentum.")

        #expect(RetentionNotificationStage.day7.title == "Pick up where you left off")
        #expect(RetentionNotificationStage.day7.body == "One small step is enough to restart.")

        #expect(RetentionNotificationStage.day21.title == "Your year isn’t over")
        #expect(RetentionNotificationStage.day21.body == "Come back when you’re ready. Today works.")
    }

    @Test func stageMetadataMatchesSpec() {
        #expect(RetentionNotificationStage.day3.userInfo["notificationScope"] == "app")
        #expect(RetentionNotificationStage.day3.userInfo["notificationKind"] == "retention")
        #expect(RetentionNotificationStage.day3.userInfo["retentionStage"] == "day3")
    }

    @Test func fireDatesUseOffsetDaysAtSixPM() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let base = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 17, hour: 22, minute: 30)))

        let day3 = try #require(retentionFireDate(for: .day3, baseDate: base, calendar: calendar))
        let day7 = try #require(retentionFireDate(for: .day7, baseDate: base, calendar: calendar))
        let day21 = try #require(retentionFireDate(for: .day21, baseDate: base, calendar: calendar))

        #expect(calendar.dateComponents([.year, .month, .day, .hour, .minute], from: day3) == DateComponents(year: 2026, month: 5, day: 20, hour: 18, minute: 0))
        #expect(calendar.dateComponents([.year, .month, .day, .hour, .minute], from: day7) == DateComponents(year: 2026, month: 5, day: 24, hour: 18, minute: 0))
        #expect(calendar.dateComponents([.year, .month, .day, .hour, .minute], from: day21) == DateComponents(year: 2026, month: 6, day: 7, hour: 18, minute: 0))
    }

    @Test func localDayKeyUsesLocalDateComponents() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 7, hour: 23, minute: 59)))

        #expect(retentionLocalDayKey(for: date, calendar: calendar) == "2026-5-7")
    }
}
