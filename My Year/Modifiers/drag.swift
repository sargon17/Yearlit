import SharedModels
import SwiftUI

struct ContextOrDragModifier: ViewModifier {
  let isReorderActive: Bool
  let calendar: CustomCalendar
  @ObservedObject var store: CustomCalendarStore
  @Binding var showDeleteConfirmation: Bool
  @Environment(\.router) private var router

  func body(content: Content) -> some View {
    if isReorderActive {
      content
        .onDrag {
          NSItemProvider(object: calendar.id.uuidString as NSString)

          let vibration = UIImpactFeedbackGenerator(style: .light)
          vibration.impactOccurred()

          return NSItemProvider(object: calendar.id.uuidString as NSString)
        }
        .onDrop(of: [.text], delegate: CalendarDropDelegate(item: calendar, store: store))
    } else {
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
            .background(Color("surface-muted"))

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
}
