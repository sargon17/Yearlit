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
            Button(action: archiveCalendar) {
                Text("Archive Calendar")
            }
            Divider()
            Button(action: {
                showDeleteConfirmation = true
            }) {
                Text("Delete Calendar")
            }
        }
    }

    private func archiveCalendar() {
        guard !calendar.isArchived else { return }

        Task {
            do {
                _ = try await updateArchiveState(true, to: calendar, store: store)
            } catch {
                if let archiveError = error as? ArchiveStateError {
                    switch archiveError {
                    case .persistenceFailed:
                        router.showAlert(
                            .alert,
                            title: "Archive failed",
                            subtitle: "The calendar could not be archived."
                        )
                    case let .notificationSyncFailed(syncError):
                        router.showAlert(
                            .alert,
                            title: "Archive saved, notifications not updated",
                            subtitle: syncError.localizedDescription
                        )
                    }
                    return
                }

                router.showAlert(
                    .alert,
                    title: "Archive failed",
                    subtitle: error.localizedDescription
                )
            }
        }
    }
}
