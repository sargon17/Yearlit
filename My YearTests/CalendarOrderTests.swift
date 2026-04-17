import Foundation
import SharedModels
import Testing

struct CalendarOrderTests {
    @Test func normalizationRepairsDuplicateAndSparseOrders() {
        let calendars = [
            calendar("B", order: 20),
            calendar("A", order: 20),
            calendar("Archived", order: -4, isArchived: true),
            calendar("C", order: 99),
        ]

        let normalized = CustomCalendarStore.normalizedCalendarOrder(calendars)

        #expect(normalized.map(\.name) == ["A", "B", "C", "Archived"])
        #expect(normalized.map(\.order) == [0, 1, 2, 3])
    }

    @Test func movingFourthActiveCalendarToSecondIsStable() {
        let calendars = [
            calendar("A", order: 0),
            calendar("B", order: 1),
            calendar("C", order: 2),
            calendar("D", order: 3),
        ]

        let reordered = CustomCalendarStore.reorderedActiveCalendars(
            calendars,
            fromOffsets: IndexSet(integer: 3),
            toOffset: 1
        )

        #expect(reordered.map(\.name) == ["A", "D", "B", "C"])
        #expect(reordered.map(\.order) == [0, 1, 2, 3])
    }

    @Test func movingSecondActiveCalendarToFourthIsStable() {
        let calendars = [
            calendar("A", order: 0),
            calendar("B", order: 1),
            calendar("C", order: 2),
            calendar("D", order: 3),
        ]

        let reordered = CustomCalendarStore.reorderedActiveCalendars(
            calendars,
            fromOffsets: IndexSet(integer: 1),
            toOffset: 4
        )

        #expect(reordered.map(\.name) == ["A", "C", "D", "B"])
        #expect(reordered.map(\.order) == [0, 1, 2, 3])
    }

    @Test func archivedCalendarsDoNotReserveActivePositions() {
        let calendars = [
            calendar("A", order: 0),
            calendar("Archived", order: 1, isArchived: true),
            calendar("B", order: 2),
            calendar("C", order: 3),
        ]

        let reordered = CustomCalendarStore.reorderedActiveCalendars(
            calendars,
            fromOffsets: IndexSet(integer: 2),
            toOffset: 0
        )

        #expect(reordered.map(\.name) == ["C", "A", "B", "Archived"])
        #expect(reordered.map(\.order) == [0, 1, 2, 3])
        #expect(reordered.last?.isArchived == true)
    }

    private func calendar(_ name: String, order: Int, isArchived: Bool = false) -> CustomCalendar {
        CustomCalendar(
            id: id(for: name),
            name: name,
            color: "qs-amber",
            trackingType: .binary,
            isArchived: isArchived,
            order: order
        )
    }

    private func id(for name: String) -> UUID {
        switch name {
        case "A":
            return UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        case "B":
            return UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        case "C":
            return UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        case "D":
            return UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
        default:
            return UUID(uuidString: "00000000-0000-0000-0000-000000000999")!
        }
    }
}
