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
  let onSave: ((CalendarEntry) -> Void)?
  let onDismiss: (() -> Void)?

  @State private var selectedDate: Date
  @State private var presentedDate: Date
  @State private var entryCount: Int
  @State private var entryCompleted: Bool

  init(
    calendar: CustomCalendar,
    date: Date,
    store: CustomCalendarStore,
    onSave: ((CalendarEntry) -> Void)? = nil,
    onDismiss: (() -> Void)? = nil
  ) {
    self.calendar = calendar
    self.date = date
    self.store = store
    self.onSave = onSave
    self.onDismiss = onDismiss
    let bucketedDate = Self.bucketDate(for: date, cadence: calendar.cadence)
    let existingEntry = store.getEntry(calendarId: calendar.id, date: bucketedDate)
    _selectedDate = State(initialValue: bucketedDate)
    _presentedDate = State(initialValue: bucketedDate)
    _entryCount = State(initialValue: existingEntry?.count ?? 0)
    _entryCompleted = State(initialValue: existingEntry?.completed ?? false)
  }

  private func saveEntry() {
    guard !calendar.isAppleHealthConnected else {
      dismiss()
      return
    }
    let originalDate = Self.bucketDate(for: date, cadence: calendar.cadence)
    let targetDate = presentedDate
    let existingEntry = store.getEntry(calendarId: calendar.id, date: targetDate)
    let newEntry = normalizedEntry(date: targetDate)

    let originalEntry = store.getEntry(calendarId: calendar.id, date: originalDate)
    if originalDate != targetDate, let originalEntry {
      CalendarAnalyticsTracker.shared.trackEntryMutation(
        calendar: calendar,
        oldEntry: originalEntry,
        newEntry: nil,
        source: .editSheet
      )
    }

    store.saveEntry(calendarId: calendar.id, replacing: originalDate, with: newEntry)
    CalendarAnalyticsTracker.shared.trackEntryMutation(
      calendar: calendar,
      oldEntry: existingEntry,
      newEntry: newEntry,
      source: .editSheet
    )
    onSave?(newEntry)
    dismiss()
  }

  private func normalizedEntry(date entryDate: Date) -> CalendarEntry {
    let normalizedCount = max(0, entryCount)
    switch calendar.trackingType {
    case .binary:
      return CalendarEntry(date: entryDate, count: entryCompleted ? 1 : 0, completed: entryCompleted)
    case .counter:
      return CalendarEntry(date: entryDate, count: normalizedCount, completed: normalizedCount > 0)
    case .multipleDaily:
      return CalendarEntry(
        date: entryDate,
        count: normalizedCount,
        completed: normalizedCount >= calendar.dailyTarget
      )
    }
  }

  var body: some View {
    CheckInDeviceScreen {
      entryEditor

      Rectangle()
        .fill(Color.textTertiary.opacity(0.35))
        .frame(height: 1)

      HStack(alignment: .top, spacing: 0) {
        VerticalDateWheelModule(
          calendar: calendar,
          selectedDate: $selectedDate,
          accentColor: Color(calendar.color)
        )

        if calendar.trackingType != .binary {
          Rectangle()
            .fill(Color.textTertiary.opacity(0.35))
            .frame(width: 1)
            .padding(.vertical, 12)

          VerticalAmountWheelModule(
            calendar: calendar,
            entryCount: $entryCount,
            accentColor: Color(calendar.color),
            label: compactCountLabel
          )
        }
      }
      .frame(height: 250)
    } actions: {
      HStack(spacing: 10) {
        DeviceActionButton(title: "Cancel", action: { dismiss() })
        DeviceActionButton(
          title: "Save",
          accentColor: Color(calendar.color),
          labelColor: .brandInverted,
          action: saveEntry
        )
      }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .navigationBarTitleDisplayMode(.large)
    .onAppear {
      syncPresentedDate(date)
    }
    .onChange(of: date) { _, newDate in
      syncPresentedDate(newDate)
    }
    .onDisappear {
      onDismiss?()
    }
    .onChange(of: entryCount) { _, newValue in
      if newValue < 0 {
        entryCount = 0
      }
    }
  }

  private func syncPresentedDate(_ date: Date) {
    let bucketedDate = Self.bucketDate(for: date, cadence: calendar.cadence)
    guard bucketedDate != presentedDate else { return }
    presentedDate = bucketedDate
    selectedDate = bucketedDate
    fillExistingProgressIfPresent(for: bucketedDate)
  }

  @ViewBuilder
  private var entryEditor: some View {
    switch calendar.trackingType {
    case .binary:
      VStack(alignment: .leading, spacing: 10) {
        ScreenControlLabel(label: "Entry")
        Toggle(isOn: $entryCompleted) {
          Text("Completed")
            .textDefault()
        }
        .tint(Color(calendar.color))
      }
      .padding(14)
    case .counter, .multipleDaily:
      VStack(alignment: .leading, spacing: 8) {
        ScreenControlLabel(label: LocalizedStringKey(countLabel))
        TextField("", value: $entryCount, formatter: countFormatter)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)
          .font(AppFont.pixelCircle(72))
          .foregroundStyle(Color(calendar.color))
          .textFieldStyle(.plain)
          .keyboardType(.numberPad)
          .contentTransition(.numericText())
      }
      .padding(.horizontal, 14)
      .padding(.top, 12)
      .padding(.bottom, 14)
    }
  }

  private func fillExistingProgressIfPresent(for date: Date) {
    let existingEntry = store.getEntry(
      calendarId: calendar.id,
      date: Self.bucketDate(for: date, cadence: calendar.cadence)
    )

    switch calendar.trackingType {
    case .binary:
      entryCompleted = existingEntry?.completed ?? false
    case .counter, .multipleDaily:
      entryCount = existingEntry?.count ?? 0
    }
  }

  private var countLabel: String {
    if let unit = calendar.unit, unit != .none {
      if unit == .currency {
        return calendar.currencySymbol ?? "$"
      }
      return unit.displayName
    }
    return String(localized: "Count")
  }

  private var compactCountLabel: String {
    guard let unit = calendar.unit, unit != .none else {
      return String(localized: "Count")
    }
    return unit == .currency ? (calendar.currencySymbol ?? "$") : unit.rawValue
  }

  private static func bucketDate(for date: Date, cadence: CalendarCadence) -> Date {
    switch cadence {
    case .daily:
      return LocalDayCalendar.startOfDay(for: date)
    case .weekly:
      return LocalDayCalendar.startOfWeek(for: date)
    }
  }
}

private var countFormatter: NumberFormatter {
  let formatter = NumberFormatter()
  formatter.numberStyle = .none
  return formatter
}
