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

  @State private var entryCount: Int
  @State private var entryCompleted: Bool

  init(calendar: CustomCalendar, date: Date, store: CustomCalendarStore) {
    self.calendar = calendar
    self.date = date
    self.store = store
    // Initialize state based on existing entry or defaults
    let existingEntry = store.getEntry(calendarId: calendar.id, date: date)
    _entryCount = State(initialValue: existingEntry?.count ?? 0)
    _entryCompleted = State(initialValue: existingEntry?.completed ?? false)
  }

  private func saveEntry() {
    let newEntry = CalendarEntry(date: date, count: entryCount, completed: entryCompleted)
    store.addEntry(calendarId: calendar.id, entry: newEntry)
    WidgetCenter.shared.reloadAllTimelines()
    dismiss()
  }

  var body: some View {
    NavigationView {  // Wrap in NavigationView for title and buttons
      Form {
        Section {
          if calendar.trackingType == .binary {
            Toggle("Completed", isOn: $entryCompleted)
          } else {
            HStack {
              Text(
                "Count"
                  + (calendar.unit != nil
                    ? " (\(calendar.unit == .currency ? (calendar.currencySymbol ?? "$") : calendar.unit!.rawValue))"
                    : ""))
              Spacer()
              TextField("Value", value: $entryCount, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
                .onChange(of: entryCount) { newValue in
                  // Automatically mark as completed if count > 0 for counter/multiple
                  if calendar.trackingType == .counter || calendar.trackingType == .multipleDaily {
                    entryCompleted = newValue > 0
                  }
                }
            }
          }
        }
      }
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
      .background(Color("surface-muted").ignoresSafeArea())
      .scrollContentBackground(.hidden)
    }
  }
}
