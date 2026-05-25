import SharedModels
import SwiftUI

struct ContextOrDragModifier: ViewModifier {
    let calendar: CustomCalendar
    @ObservedObject var store: CustomCalendarStore
    @Binding var showDeleteConfirmation: Bool
    @Environment(\.router) private var router

    func body(content: Content) -> some View {
        content.contextMenu {
            Button(action: {
                router.showScreen(.sheet) { _ in
                    EditCalendarView(
                        calendar: calendar,
                        onSave: { updatedCalendar in
                            store.updateCalendar(updatedCalendar)
                        },
                        onDelete: { _ in
                            store.deleteCalendar(id: calendar.id)
                        }
                    )
                    .surfaceBackground(Color("surface-muted"))
                }

            }) {
                Text("Edit Calendar")
            }
            Divider()
            Button(action: toggleArchiveStatus) {
                Text(String(localized: calendar.isArchived ? "Unarchive Calendar" : "Archive Calendar"))
            }
            Divider()
            Button(action: {
                showDeleteConfirmation = true
            }) {
                Text("Delete Calendar")
            }
        }
    }

    private func toggleArchiveStatus() {
        var updatedCalendar = calendar
        updatedCalendar.isArchived.toggle()
        scheduleNotifications(for: updatedCalendar, store: store)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            store.updateCalendar(updatedCalendar)
            CalendarAnalyticsTracker.shared.trackArchiveStateChange(
                calendar: updatedCalendar,
                source: .dragAction,
                isArchived: updatedCalendar.isArchived
            )
        }
    }
}
