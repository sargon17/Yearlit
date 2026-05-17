import Foundation
@testable import My_Year
import Testing

struct NotificationIdDerivationTests {
    @Test func prefersUserInfoCalendarId() {
        let uuid = UUID()
        let result = deriveCalendarId(
            notificationIdentifier: "\(UUID().uuidString)-streak-protection",
            userInfoCalendarId: uuid.uuidString
        )
        #expect(result == uuid)
    }

    @Test func parsesPrimaryIdentifierUUID() {
        let uuid = UUID()
        let result = deriveCalendarId(notificationIdentifier: uuid.uuidString, userInfoCalendarId: nil)
        #expect(result == uuid)
    }

    @Test func parsesDerivedIdentifiersViaPrefix() {
        let uuid = UUID()
        let derived = [
            "\(uuid.uuidString)-0",
            "\(uuid.uuidString)-12",
            "\(uuid.uuidString)-streak-protection",
            "\(uuid.uuidString)-snooze",
        ]

        for identifier in derived {
            let result = deriveCalendarId(notificationIdentifier: identifier, userInfoCalendarId: nil)
            #expect(result == uuid)
        }
    }

    @Test func returnsNilForInvalidIdentifier() {
        #expect(deriveCalendarId(notificationIdentifier: "not-a-uuid", userInfoCalendarId: nil) == nil)
        #expect(deriveCalendarId(notificationIdentifier: "short", userInfoCalendarId: nil) == nil)
    }

    @Test func ignoresAppLevelRetentionIdentifiers() {
        for stage in RetentionNotificationStage.allCases {
            #expect(deriveCalendarId(notificationIdentifier: stage.identifier, userInfoCalendarId: nil) == nil)
        }
    }
}
