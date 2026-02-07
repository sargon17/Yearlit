import Foundation
import Testing

@testable import My_Year

struct NotificationIdDerivationTests {
  @Test func prefersUserInfoCalendarId() async throws {
    let uuid = UUID()
    let result = deriveCalendarId(
      notificationIdentifier: "\(UUID().uuidString)-streak-protection",
      userInfoCalendarId: uuid.uuidString
    )
    #expect(result == uuid)
  }

  @Test func parsesPrimaryIdentifierUUID() async throws {
    let uuid = UUID()
    let result = deriveCalendarId(notificationIdentifier: uuid.uuidString, userInfoCalendarId: nil)
    #expect(result == uuid)
  }

  @Test func parsesDerivedIdentifiersViaPrefix() async throws {
    let uuid = UUID()
    let derived = [
      "\(uuid.uuidString)-0",
      "\(uuid.uuidString)-12",
      "\(uuid.uuidString)-streak-protection",
      "\(uuid.uuidString)-snooze"
    ]

    for identifier in derived {
      let result = deriveCalendarId(notificationIdentifier: identifier, userInfoCalendarId: nil)
      #expect(result == uuid)
    }
  }

  @Test func returnsNilForInvalidIdentifier() async throws {
    #expect(deriveCalendarId(notificationIdentifier: "not-a-uuid", userInfoCalendarId: nil) == nil)
    #expect(deriveCalendarId(notificationIdentifier: "short", userInfoCalendarId: nil) == nil)
  }
}
