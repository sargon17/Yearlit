import SharedModels
import SwiftfulRouting
import SwiftUI
import UserNotifications
import WidgetKit

struct DayEntryEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let calendar: CustomCalendar
    let date: Date
    let store: CustomCalendarStore // Receive the store
    let onSave: (() -> Void)?
    let onDismiss: (() -> Void)?

    @State private var entryCount: Int
    @State private var entryCompleted: Bool

    init(
        calendar: CustomCalendar,
        date: Date,
        store: CustomCalendarStore,
        onSave: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.calendar = calendar
        self.date = date
        self.store = store
        self.onSave = onSave
        self.onDismiss = onDismiss
        // Initialize state based on existing entry or defaults
        let existingEntry = store.getEntry(calendarId: calendar.id, date: date)
        _entryCount = State(initialValue: existingEntry?.count ?? 0)
        _entryCompleted = State(initialValue: existingEntry?.completed ?? false)
    }

    private func saveEntry() {
        guard !calendar.isAppleHealthConnected else {
            dismiss()
            return
        }
        let existingEntry = store.getEntry(calendarId: calendar.id, date: date)
        let newEntry = CalendarEntry(date: date, count: entryCount, completed: entryCompleted)
        store.addEntry(calendarId: calendar.id, entry: newEntry)
        CalendarAnalyticsTracker.shared.trackEntryMutation(
            calendar: calendar,
            oldEntry: existingEntry,
            newEntry: newEntry,
            source: .editSheet
        )
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
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .onDisappear {
            onDismiss?()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveEntry() }
            }
        }
    }

    private var navigationTitle: String {
        if calendar.cadence == .weekly {
            let weekStart = LocalDayCalendar.startOfWeek(for: date)
            let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            return "\(dateFormatterLong.string(from: weekStart)) – \(dateFormatterLong.string(from: weekEnd))"
        }

        return dateFormatterLong.string(from: date)
    }
}
