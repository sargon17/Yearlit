import RevenueCat
import SharedModels
import SwiftUI
import SwiftfulRouting

struct EditCalendarView: View {
  @Environment(\.dismiss) var dismiss: DismissAction
  let calendar: CustomCalendar
  let onSave: (CustomCalendar) -> Void
  let onDelete: (CustomCalendar) -> Void

  @State var customerInfo: CustomerInfo?
  @State var name: String
  @State var selectedColor: String
  @State var cadence: CalendarCadence
  @State var trackingType: TrackingType
  @State var dailyTarget: Int
  @State var selectedUnit: UnitOfMeasure?
  @State var defaultRecordValue: Int
  @State var isArchived: Bool
  @State var calendarError: CalendarError?
  @State var showingDeleteConfirmation = false
  @State var currencySymbol: String
  @State var entries: [String: CalendarEntry]
  @State var trackingStartedAt: Date
  @State var historyMessage: String?
  @State var notificationSettings: NotificationSettingsDraft
  @State var showingNotificationSettings: Bool = false

  @FocusState var isNameFocused: Bool
  @Environment(\.router) var router

  var isAppleHealthCalendar: Bool {
    calendar.isAppleHealthConnected
  }

  var appleHealthMetric: AppleHealthMetric? {
    calendar.appleHealthMetric
  }

  var usesManualValueSettings: Bool {
    !isAppleHealthCalendar && (trackingType == .counter || trackingType == .multipleDaily)
  }

  var settingsSectionLabel: LocalizedStringKey {
    isAppleHealthCalendar
      ? "Settings for Apple Health"
      : LocalizedStringKey("Settings for \(trackingType.displayName)")
  }

  var targetFieldLabel: String {
    if let metric = appleHealthMetric {
      return metric.targetLabel
    }
    return cadence.targetTitle
  }

  init(
    calendar: CustomCalendar, onSave: @escaping (CustomCalendar) -> Void,
    onDelete: @escaping (CustomCalendar) -> Void
  ) {
    self.calendar = calendar
    self.onSave = onSave
    self.onDelete = onDelete
    _name = State(initialValue: calendar.name)
    _selectedColor = State(initialValue: calendar.color)
    _cadence = State(initialValue: calendar.cadence)
    _trackingType = State(initialValue: calendar.trackingType)
    _dailyTarget = State(initialValue: calendar.dailyTarget)
    _selectedUnit = State(initialValue: calendar.unit)
    _defaultRecordValue = State(initialValue: calendar.defaultRecordValue ?? 1)
    _currencySymbol = State(initialValue: calendar.currencySymbol ?? "$")
    _isArchived = State(initialValue: calendar.isArchived)
    _entries = State(initialValue: calendar.entries)
    _trackingStartedAt = State(initialValue: calendar.trackingStartedAt)
    _historyMessage = State(initialValue: nil)

    // Default reminder time set to 9:00 AM as it's a common time for daily reminders
    let defaultTime =
      Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    let fallbackWeekday = Calendar.current.component(.weekday, from: Date())
    _notificationSettings = State(
      initialValue: NotificationSettingsDraft(
        calendar: calendar,
        fallbackReminderTime: defaultTime,
        fallbackReminderWeekday: fallbackWeekday
      )
    )
  }

  var body: some View {
    ScrollView {
      editFormContent
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    }
    .accentColor(Color(selectedColor))
    .scrollClipDisabled(true)
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .onAppear(perform: loadCustomerInfo)
    .navigationTitle("Edit Calendar")
    .navigationBarTitleDisplayMode(.large)
    .toolbar { editToolbar }
    .alert(item: $calendarError) { error in
      Alert(title: Text(error.title), message: Text(error.message), dismissButton: .default(Text("OK")))
    }
    .sheet(isPresented: $showingNotificationSettings) { notificationSettingsSheet }
    .onChange(of: trackingType) { _, newValue in
      if newValue != .multipleDaily {
        notificationSettings.additionalReminderTimes = []
      }
    }
  }

  var earliestExistingEntryDate: Date? {
    HabitHistoryDateResolver.earliestEntryDate(from: entries, cadence: cadence)
  }

  var normalizedTrackingStartedAt: Date {
    HabitHistoryDateResolver.normalized(trackingStartedAt, cadence: cadence)
  }

  var normalizedDailyTarget: Int {
    max(1, dailyTarget)
  }

  func resolvedTrackingStartedAt() -> Date {
    HabitHistoryDateResolver.resolvedStartDate(
      selectedDate: trackingStartedAt,
      earliestEntryDate: earliestExistingEntryDate,
      cadence: cadence
    )
  }

  func applyExistingStreakEntries(_ newEntries: [String: CalendarEntry]) {
    for (key, entry) in newEntries {
      entries[key] = entry
    }
    guard
      let earliestDate = earliestExistingEntryDate,
      earliestDate < normalizedTrackingStartedAt
    else { return }
    trackingStartedAt = earliestDate
    historyMessage = HabitHistoryDateResolver.startMovedMessage(for: earliestDate)
  }

  func makeUpdatedCalendar(isArchived overrideArchived: Bool? = nil) -> CustomCalendar {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let schedulesWeeklyReminder =
      !isAppleHealthCalendar
      && notificationSettings.recurringReminderEnabled
      && cadence == .weekly
    let updatedCalendar = CustomCalendar(
      id: calendar.id,
      name: trimmedName,
      color: selectedColor,
      cadence: isAppleHealthCalendar ? .daily : cadence,
      trackingType: isAppleHealthCalendar ? .binary : trackingType,
      trackingStartedAt: isAppleHealthCalendar ? calendar.trackingStartedAt : resolvedTrackingStartedAt(),
      dailyTarget: normalizedDailyTarget,
      entries: entries,
      isArchived: overrideArchived ?? isArchived,
      recurringReminderEnabled: isAppleHealthCalendar ? false : notificationSettings.recurringReminderEnabled,
      reminderTime: !isAppleHealthCalendar && notificationSettings.recurringReminderEnabled
        ? notificationSettings.reminderTime : nil,
      order: calendar.order,
      reminderWeekday: schedulesWeeklyReminder ? notificationSettings.reminderWeekday : nil,
      unit: isAppleHealthCalendar ? appleHealthMetric?.unit : usesManualValueSettings ? selectedUnit : nil,
      defaultRecordValue: usesManualValueSettings ? defaultRecordValue : nil,
      currencySymbol: usesManualValueSettings && selectedUnit == .currency ? currencySymbol : nil,
      reminderTimeZone: calendar.reminderTimeZone,
      notificationPrivacyMode: notificationSettings.notificationPrivacyMode,
      suppressWhenCompleted: isAppleHealthCalendar ? false : notificationSettings.suppressWhenCompleted,
      additionalReminderTimes: isAppleHealthCalendar ? [] : notificationSettings.additionalReminderTimes,
      streakProtectionEnabled: isAppleHealthCalendar ? false : notificationSettings.streakProtectionEnabled,
      streakProtectionThreshold: notificationSettings.streakProtectionThreshold,
      source: calendar.source
    )
    return isAppleHealthCalendar
      ? updatedCalendar.recomputingCompletionForTarget(normalizedDailyTarget)
      : updatedCalendar
  }

  var lockedAppleHealthMetricSection: some View {
    CustomSection(label: "Tracking Type") {
      PickerOptionTile(isSelected: true, isEnabled: false) {
        PickerOptionContent(
          icon: TrackingType.binary.icon,
          title: LocalizedStringKey(appleHealthMetric?.title ?? String(localized: "Apple Health")),
          accentColor: Color(selectedColor),
          isSelected: true
        )
      }
      .padding(.all, 2)
      .sameLevelGroupBackground()
    }
  }
}
