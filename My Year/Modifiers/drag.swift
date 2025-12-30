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
      Button(action: {
        showDeleteConfirmation = true
      }) {
        Text("Delete Calendar")
      }
    }
  }
}
