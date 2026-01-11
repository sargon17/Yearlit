import SharedModels
import SwiftUI
import SwiftfulRouting
import UserNotifications
import WidgetKit

struct DayEntryEditSheet: View {
  @Environment(\.dismiss) private var dismiss
  let calendar: CustomCalendar
  let date: Date
  let store: CustomCalendarStore  // Receive the store
  let onSave: (() -> Void)?

  @State private var entryCount: Int
  @State private var entryCompleted: Bool

  init(calendar: CustomCalendar, date: Date, store: CustomCalendarStore, onSave: (() -> Void)? = nil) {
    self.calendar = calendar
    self.date = date
    self.store = store
    self.onSave = onSave
    // Initialize state based on existing entry or defaults
    let existingEntry = store.getEntry(calendarId: calendar.id, date: date)
    _entryCount = State(initialValue: existingEntry?.count ?? 0)
    _entryCompleted = State(initialValue: existingEntry?.completed ?? false)
  }

  private func saveEntry() {
    let newEntry = CalendarEntry(date: date, count: entryCount, completed: entryCompleted)
    store.addEntry(calendarId: calendar.id, entry: newEntry)
    WidgetReload.scheduleAllTimelinesReload()
    onSave?()
    dismiss()
  }

  var body: some View {

    VStack {
      switch calendar.trackingType {
      case .binary:
        Toggle("Completed", isOn: $entryCompleted)
      case .counter:
        HorizontalWheelEntryModule(calendar: calendar, entryCount: $entryCount)
      case .multipleDaily:
        HorizontalWheelEntryModule(calendar: calendar, entryCount: $entryCount)

      // MultipleDailyEntryModule(calendar: calendar, entryCount: $entryCount)
      }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .navigationTitle(dateFormatterLong.string(from: date))
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") { saveEntry() }
      }
    }
  }
}
