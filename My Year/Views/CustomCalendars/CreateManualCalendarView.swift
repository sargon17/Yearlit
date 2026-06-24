import RevenueCat
import SharedModels
import SwiftUI
import SwiftfulRouting

struct CreateManualCalendarView: View {
  @Environment(\.locale) private var locale
  let onCreate: (CustomCalendar) -> Void

  @State private var customerInfo: CustomerInfo?
  @ObservedObject private var store = CustomCalendarStore.shared
  @State private var name = ""
  @State private var selectedColor = "qs-amber"
  @State private var cadence: CalendarCadence = .daily
  @State private var trackingType: TrackingType = .binary
  @State private var dailyTarget = 2
  @State private var recurringReminderEnabled: Bool = false
  @State private var reminderTime: Date = .init()
  @State private var reminderWeekday: Int = Calendar.current.component(.weekday, from: Date())
  @State private var selectedUnit: UnitOfMeasure = .none
  @State private var defaultRecordValue: Int = 1
  @State private var currencySymbol: String = "$"
  @State private var existingStreakEntries: [String: CalendarEntry] = [:]
  @State private var trackingStartedAt: Date = LocalDayCalendar.startOfDay(for: Date())
  @State private var historyMessage: String?
  @State private var notificationPrivacyMode: NotificationPrivacyMode = .full
  @State private var suppressWhenCompleted: Bool = true
  @State private var additionalReminderTimes: [ReminderTime] = []
  @State private var streakProtectionEnabled: Bool = true
  @State private var streakProtectionThreshold: Int = 5
  @State private var showingNotificationSettings: Bool = false

  @FocusState private var isNameFocused: Bool
  @Environment(\.router) private var router

  private var isPremiumUser: Bool {
    isPremium(customerInfo: customerInfo)
  }

  private var trimmedName: String {
    name.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var trackingTypeLabel: String {
    switch trackingType {
    case .binary:
      return String(localized: "Binary")
    case .counter:
      return String(localized: "Counter")
    case .multipleDaily:
      return String(localized: "Target")
    }
  }

  private var trackingTypeDescription: LocalizedStringKey {
    switch trackingType {
    case .binary:
      return cadence == .daily
        ? "Track a simple yes/no each day. Great for habits you either complete or skip."
        : "Track a simple yes/no each week. Great for goals you either hit or miss across the week."
    case .counter:
      return cadence == .daily
        ? "Log a numeric value per day, like pages read or minutes practiced."
        : "Log a numeric value per week, like workouts done or kilometers covered."
    case .multipleDaily:
      return cadence == .daily
        ? "Check in multiple times per day toward a daily target."
        : "Check in multiple times across the week toward a weekly target."
    }
  }

  func userCanCreateCalendar() -> Bool {
    return isPremiumUser || store.snapshot.calendars.count < 3
  }

  func createCalendar() {
    let calendar = CustomCalendar(
      name: trimmedName,
      color: selectedColor,
      cadence: cadence,
      trackingType: trackingType,
      trackingStartedAt: resolvedTrackingStartedAt(),
      dailyTarget: dailyTarget,
      entries: existingStreakEntries,
      isArchived: false,
      recurringReminderEnabled: recurringReminderEnabled,
      reminderTime: recurringReminderEnabled ? reminderTime : nil,
      reminderWeekday: recurringReminderEnabled && cadence == .weekly ? reminderWeekday : nil,
      unit: (trackingType == .counter || trackingType == .multipleDaily) ? selectedUnit : nil,
      defaultRecordValue: (trackingType == .counter || trackingType == .multipleDaily) ? defaultRecordValue : nil,
      currencySymbol: (trackingType == .counter || trackingType == .multipleDaily) && selectedUnit == .currency
        ? currencySymbol : nil,
      reminderTimeZone: TimeZone.current.identifier,
      notificationPrivacyMode: notificationPrivacyMode,
      suppressWhenCompleted: suppressWhenCompleted,
      additionalReminderTimes: trackingType == .multipleDaily && isPremiumUser ? additionalReminderTimes : [],
      streakProtectionEnabled: streakProtectionEnabled,
      streakProtectionThreshold: streakProtectionThreshold,
      source: .manual
    )
    scheduleNotifications(for: calendar, store: CustomCalendarStore.shared)
    onCreate(calendar)
  }

  private var earliestExistingEntryDate: Date? {
    HabitHistoryDateResolver.earliestEntryDate(from: existingStreakEntries, cadence: cadence)
  }

  private func resolvedTrackingStartedAt() -> Date {
    HabitHistoryDateResolver.resolvedStartDate(
      selectedDate: trackingStartedAt,
      earliestEntryDate: earliestExistingEntryDate,
      cadence: cadence
    )
  }

  private var normalizedTrackingStartedAt: Date {
    HabitHistoryDateResolver.normalized(trackingStartedAt, cadence: cadence)
  }

  private func applyExistingStreakEntries(_ entries: [String: CalendarEntry]) {
    for (key, entry) in entries {
      existingStreakEntries[key] = entry
    }
    guard let earliestDate = earliestExistingEntryDate, earliestDate < normalizedTrackingStartedAt else { return }
    trackingStartedAt = earliestDate
    historyMessage = HabitHistoryDateResolver.startMovedMessage(for: earliestDate)
  }

  private func clearExistingStreakHistory() {
    existingStreakEntries = [:]
    historyMessage = nil
  }

  @MainActor
  func handleCreateCalendar() async -> Bool {
    if !userCanCreateCalendar() {
      router.showScreen(.sheet) { _ in
        PremiumPaywallSheet(displayCloseButton: true, trigger: .calendarLimit)
      }
      return false
    }

    createCalendar()
    return true
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        CustomSeparator()
          .padding(.horizontal, -16)
        CustomSection(label: "Calendar Name") {
          TextField(
            "",
            text: $name,
            prompt: Text("Daily Training").foregroundColor(.white.opacity(0.2))
          )
          .inputStyle(color: Color(selectedColor))
          .focused($isNameFocused)
        }

        CalendarColorPickerSection(selectedColor: $selectedColor)

        CalendarCadencePicker(cadence: cadence, color: Color(selectedColor), isEditable: true) {
          selectedCadence in
          if selectedCadence != cadence {
            clearExistingStreakHistory()
          }
          cadence = selectedCadence
        }

        ZStack(alignment: .leading) {
          Text(cadence.detailDescription)
            .font(.footnote)
            .foregroundStyle(.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .id(cadence)
            .transition(.blurReplace.combined(with: .scale(scale: 0.98)))
        }
        .animation(.snappy, value: cadence)

        TrackingPicker(trackingType: $trackingType, color: Color(selectedColor))

        ZStack(alignment: .leading) {
          Text(trackingTypeDescription)
            .font(.footnote)
            .foregroundStyle(.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
            .id(trackingType)
            .transition(.blurReplace.combined(with: .scale(scale: 0.98)))
        }
        .animation(.snappy, value: trackingType)

        if trackingType == .multipleDaily || trackingType == .counter {
          CustomSection(label: "Settings for \(trackingTypeLabel)") {
            VStack(spacing: 2) {
              if trackingType == .multipleDaily {
                HStack {
                  Text(cadence.targetTitle)
                    .labelStyle(type: .secondary)

                  Spacer()
                  TextField("Target", value: $dailyTarget, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
                    .inputStyle(size: .large, radius: 4, color: Color(selectedColor))
                }
                .padding(.leading)
                .padding(.all, 2)
                .sameLevelBorder(isFlat: true)
              }

              if trackingType == .counter || trackingType == .multipleDaily {
                HStack {
                  Text("Unit of Measure")
                    .labelStyle(type: .secondary)

                  Spacer()
                  Picker("Unit of Measure", selection: $selectedUnit) {
                    ForEach(UnitOfMeasure.Category.allCases, id: \.self) {
                      category in
                      Section(header: Text(category.displayName)) {
                        ForEach(UnitOfMeasure.allCasesGrouped[category] ?? [], id: \.self) { unit in
                          Text(unit.displayName).tag(unit as UnitOfMeasure?)
                        }
                      }
                    }
                  }
                }
                .padding(.leading)
                .padding(.vertical, 8)
                .sameLevelBorder(isFlat: true)

                if selectedUnit == .currency {
                  HStack {
                    Text("Currency Symbol")
                      .labelStyle(type: .secondary)

                    Spacer()
                    TextField("Symbol", text: $currencySymbol)
                      .multilineTextAlignment(.trailing)
                      .frame(maxWidth: 100)
                      .inputStyle(size: .large, radius: 4, color: Color(selectedColor))
                  }
                  .padding(.leading)
                  .padding(.all, 2)
                  .sameLevelBorder(isFlat: true)
                }
              }

              if trackingType == .counter || trackingType == .multipleDaily {
                HStack {
                  Text("Default Quick Add Value")
                    .labelStyle(type: .secondary)

                  Spacer()
                  TextField("Value", value: $defaultRecordValue, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
                    .inputStyle(size: .large, radius: 4, color: Color(selectedColor))
                }
                .padding(.leading)
                .padding(.all, 2)
                .sameLevelBorder(isFlat: true)
              }
            }
            .padding(.all, 2)
            .sameLevelGroupBackground()
          }
        }

        CustomSection(label: "Notifications") {
          VStack(spacing: 2) {
            Button(action: { showingNotificationSettings = true }) {
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text("Notification settings")
                    .labelStyle(type: .secondary)
                  Text(
                    NotificationSettingsHelpers.reminderSummary(
                      isEnabled: recurringReminderEnabled,
                      cadence: cadence,
                      reminderTime: reminderTime,
                      reminderWeekday: reminderWeekday
                    )
                  )
                  .font(.caption)
                  .foregroundStyle(.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                  .font(AppFont.mono(12))
                  .foregroundStyle(.textTertiary)
              }
              .padding(.horizontal)
              .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .sameLevelBorder(isFlat: true)
          }
          .padding(.all, 2)
        }

        HabitHistorySection(
          cadence: cadence,
          trackingStartedAt: $trackingStartedAt,
          earliestEntryDate: earliestExistingEntryDate,
          autoAdjustedMessage: historyMessage ?? (!existingStreakEntries.isEmpty ? backfillSummary : nil),
          onTrackingStartedAtChanged: { historyMessage = nil }
        ) {
          router.showScreen(.sheet) { _ in
            ExistingStreakSheet(
              cadence: cadence,
              trackingType: trackingType,
              dailyTarget: dailyTarget,
              defaultDailyValue: defaultRecordValue,
              existingEntries: existingStreakEntries,
              accentColor: Color(selectedColor)
            ) { entries in
              applyExistingStreakEntries(entries)
            }
          }
        }

        CustomSeparator()
          .padding(.horizontal, -16)
      }
      .padding()
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    }
    .accentColor(Color(selectedColor))
    .scrollClipDisabled(true)
    .scrollDismissesKeyboard(.immediately)
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .navigationTitle("New Calendar")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Create") {
          Task {
            if await handleCreateCalendar() {
              router.dismissEnvironment()
            }
          }
        }
        .disabled(trimmedName.isEmpty)
      }
    }
    .onAppear {
      isNameFocused = true
    }
    .task {
      await observeCustomerInfo()
    }
    .sheet(isPresented: $showingNotificationSettings) {
      NotificationSettingsDraftSheet(
        calendarName: name,
        cadence: cadence,
        trackingType: trackingType,
        accentColor: Color(selectedColor),
        customerInfo: customerInfo,
        recurringReminderEnabled: $recurringReminderEnabled,
        reminderTime: $reminderTime,
        notificationPrivacyMode: $notificationPrivacyMode,
        suppressWhenCompleted: $suppressWhenCompleted,
        additionalReminderTimes: $additionalReminderTimes,
        streakProtectionEnabled: $streakProtectionEnabled,
        streakProtectionThreshold: $streakProtectionThreshold,
        reminderWeekday: $reminderWeekday
      )
    }
    .onChange(of: trackingType) { _, _ in
      clearExistingStreakHistory()
      if trackingType != .multipleDaily {
        additionalReminderTimes = []
      }
    }
    .onChange(of: dailyTarget) { _, _ in
      if trackingType == .multipleDaily {
        clearExistingStreakHistory()
      }
    }
  }

  private var backfillSummary: String {
    LocalizedCountText.backfilling(existingStreakEntries.count, cadence: cadence, locale: locale)
  }

  @MainActor
  private func observeCustomerInfo() async {
    do {
      customerInfo = try await Purchases.shared.customerInfo()
    } catch {
      print("Error fetching customer info: \(error.localizedDescription)")
    }

    for await info in Purchases.shared.customerInfoStream {
      customerInfo = info
      AnalyticsState.shared.updatePremiumStatus(customerInfo: info)
    }
  }
}
