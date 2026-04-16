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
            Button(action: toggleArchiveState) {
                Text(calendar.isArchived ? "Unarchive Calendar" : "Archive Calendar")
            }
            Divider()
            Button(action: {
                showDeleteConfirmation = true
            }) {
                Text("Delete Calendar")
            }
        }
    }

    private func toggleArchiveState() {
        Task {
            do {
                _ = try await updateArchiveState(!calendar.isArchived, to: calendar, store: store)
            } catch {
                if let archiveError = error as? ArchiveStateError {
                    switch archiveError {
                    case .persistenceFailed:
                        router.showAlert(
                            .alert,
                            title: calendar.isArchived ? "Unarchive failed" : "Archive failed",
                            subtitle: "The calendar could not be updated."
                        )
                    case let .notificationSyncFailed(syncError):
                        router.showAlert(
                            .alert,
                            title: calendar.isArchived ? "Unarchived, notifications not updated" : "Archived, notifications not updated",
                            subtitle: syncError.localizedDescription
                        )
                    }
                    return
                }

                router.showAlert(
                    .alert,
                    title: calendar.isArchived ? "Unarchive failed" : "Archive failed",
                    subtitle: error.localizedDescription
                )
            }
        }
    }
}
