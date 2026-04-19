import Foundation
import SharedModels
import Testing

struct CustomCalendarStoreSnapshotHelperTests {
    @Test func snapshotHelpersReturnExpectedCalendars() {
        let active = makeCalendar(name: "Active", isArchived: false)
        let archived = makeCalendar(name: "Archived", isArchived: true)
        let snapshot = CustomCalendarStoreSnapshot(
            calendars: [active, archived],
            isLoading: false,
            dataVersion: 1
        )

        #expect(snapshot.activeCalendars.map(\.id) == [active.id])
        #expect(snapshot.archivedCalendars.map(\.id) == [archived.id])
        #expect(snapshot.calendar(id: archived.id)?.id == archived.id)
    }

    private func makeCalendar(name: String, isArchived: Bool) -> CustomCalendar {
        CustomCalendar(
            name: name,
            color: "qs-emerald",
            trackingType: .binary,
            isArchived: isArchived
        )
    }
}
