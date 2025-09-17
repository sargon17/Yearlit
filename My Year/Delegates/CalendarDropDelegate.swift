import SharedModels
import SwiftUI

struct CalendarDropDelegate: DropDelegate {
  let item: CustomCalendar
  @ObservedObject var store: CustomCalendarStore

  func performDrop(info: DropInfo) -> Bool {
    let providers = info.itemProviders(for: [.text])
    if let provider = providers.first {
      provider.loadObject(ofClass: NSString.self) { object, _ in
        if let idString = object as? String, let draggedUUID = UUID(uuidString: idString) {
          DispatchQueue.main.async {
            if let sourceIndex = store.calendars.firstIndex(where: { $0.id == draggedUUID }),
              let targetIndex = store.calendars.firstIndex(where: { $0.id == item.id }),
              sourceIndex != targetIndex
            {
              let destination = targetIndex > sourceIndex ? targetIndex + 1 : targetIndex
              withAnimation {
                store.moveCalendar(
                  fromOffsets: IndexSet(integer: sourceIndex), toOffset: destination
                )
              }
            }
          }
        }
      }
    }
    Task {
      await hapticFeedback()
    }
    return true
  }
}
