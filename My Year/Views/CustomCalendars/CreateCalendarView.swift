import RevenueCat
import RevenueCatUI
import SharedModels
import SwiftUI
import SwiftfulRouting

struct CreateCalendarView: View {
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
  @State private var calendarSource: CalendarSource = .manual
  @State private var isCreatingCalendar: Bool = false
  @State private var calendarError: CalendarError?

  @FocusState private var isNameFocused: Bool
  @Environment(\.router) private var router

  private let healthStepsService = AppleHealthStepsService()

  private var isPremiumUser: Bool {
    isPremium(customerInfo: customerInfo)
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
    if calendarSource == .appleHealthSteps {
      return "Yearlit fills this Calendar from your Apple Health step history."
    }

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
    createCalendar(
      entries: existingStreakEntries, source: calendarSource, trackingStartedAt: resolvedTrackingStartedAt())
  }

  func createCalendar(entries: [String: CalendarEntry], source: CalendarSource, trackingStartedAt: Date) {
    let isAppleHealthCalendar = source == .appleHealthSteps
    let resolvedDailyTarget = isAppleHealthCalendar ? max(1, dailyTarget) : dailyTarget
    let resolvedAdditionalTimes =
      (!isAppleHealthCalendar && trackingType == .multipleDaily && isPremiumUser) ? additionalReminderTimes : []
    let calendar = CustomCalendar(
      name: name,
      color: selectedColor,
      cadence: cadence,
      trackingType: trackingType,
      trackingStartedAt: trackingStartedAt,
      dailyTarget: resolvedDailyTarget,
      entries: entries,
      isArchived: false,
      recurringReminderEnabled: isAppleHealthCalendar ? false : recurringReminderEnabled,
      reminderTime: !isAppleHealthCalendar && recurringReminderEnabled ? reminderTime : nil,
      reminderWeekday: !isAppleHealthCalendar && recurringReminderEnabled && cadence == .weekly ? reminderWeekday : nil,
      unit: isAppleHealthCalendar ? .steps : (trackingType == .counter || trackingType == .multipleDaily) ? selectedUnit : nil,
      defaultRecordValue: (!isAppleHealthCalendar && (trackingType == .counter || trackingType == .multipleDaily))
        ? defaultRecordValue : nil,
      currencySymbol: (!isAppleHealthCalendar && (trackingType == .counter || trackingType == .multipleDaily)
        && selectedUnit == .currency) ? currencySymbol : nil,
      reminderTimeZone: TimeZone.current.identifier,
      notificationPrivacyMode: notificationPrivacyMode,
      suppressWhenCompleted: isAppleHealthCalendar ? false : suppressWhenCompleted,
      additionalReminderTimes: resolvedAdditionalTimes,
      streakProtectionEnabled: isAppleHealthCalendar ? false : streakProtectionEnabled,
      streakProtectionThreshold: streakProtectionThreshold,
      source: source
    )
    if !isAppleHealthCalendar {
      scheduleNotifications(for: calendar, store: CustomCalendarStore.shared)
    }
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

    if calendarSource == .appleHealthSteps {
      do {
        try await healthStepsService.requestAuthorization()
        let stepCounts = try await healthStepsService.currentYearStepCounts()
        let entries = AppleHealthStepsEntryMapper.entries(from: stepCounts, target: dailyTarget)
        createCalendar(
          entries: entries,
          source: .appleHealthSteps,
          trackingStartedAt: Self.currentYearStartDate()
        )
        return true
      } catch {
        calendarError = .appleHealthSyncFailed(error)
        return false
      }
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

        CustomSection(label: "Data Source") {
          VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 2) {
              sourceButton(source: .manual, title: "Manual", icon: "hand.tap")
              sourceButton(source: .appleHealthSteps, title: "Apple Health Steps", icon: "figure.walk")
            }
            .padding(.all, 2)
            .sameLevelGroupBackground()

            Text(
              calendarSource == .appleHealthSteps
                ? "Fill this Calendar from current-year step history."
                : "Log progress yourself."
            )
            .font(.footnote)
            .foregroundStyle(.textTertiary)
            .padding(.horizontal, 8)
          }
        }

        CalendarCadencePicker(cadence: cadence, color: Color(selectedColor), isEditable: calendarSource == .manual) {
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

        if calendarSource == .manual {
          TrackingPicker(trackingType: $trackingType, color: Color(selectedColor))
        } else {
          lockedAppleHealthStepsSection
        }

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

        if calendarSource == .appleHealthSteps || trackingType == .multipleDaily || trackingType == .counter {
          CustomSection(
            label: calendarSource == .appleHealthSteps ? "Settings for Apple Health Steps" : "Settings for \(trackingTypeLabel)"
          ) {
            VStack(spacing: 2) {
              if calendarSource == .appleHealthSteps || trackingType == .multipleDaily {
                HStack {
                  Text(calendarSource == .appleHealthSteps ? "Steps Threshold" : cadence.targetTitle)
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

              if calendarSource == .manual && (trackingType == .counter || trackingType == .multipleDaily) {
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

              if calendarSource == .manual && (trackingType == .counter || trackingType == .multipleDaily) {
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

        if calendarSource == .manual {
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
        }
        if calendarSource == .manual {
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
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          router.dismissScreen()
        }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Create") {
          Task {
            guard !isCreatingCalendar else { return }
            isCreatingCalendar = true
            let didCreate = await handleCreateCalendar()
            isCreatingCalendar = false
            if didCreate {
              router.dismissScreen()
            }
          }
        }
        .disabled(name.isEmpty || isCreatingCalendar)
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
    .alert(item: $calendarError) { error in
      Alert(
        title: Text(error.title),
        message: Text(error.message),
        dismissButton: .default(Text("OK"))
      )
    }
    .onChange(of: trackingType) { _, _ in
      clearExistingStreakHistory()
      if trackingType != .multipleDaily {
        additionalReminderTimes = []
      }
    }
    .onChange(of: dailyTarget) { _, _ in
      if calendarSource == .appleHealthSteps || trackingType == .multipleDaily {
        clearExistingStreakHistory()
      }
    }
    .onChange(of: calendarSource) { _, source in
      applyCalendarSourceDefaults(source)
    }
  }

  private func sourceButton(source: CalendarSource, title: LocalizedStringKey, icon: String) -> some View {
    Button {
      withAnimation(.snappy) {
        calendarSource = source
      }
      Task {
        await hapticFeedback(.rigid)
      }
    } label: {
      PickerOptionTile(isSelected: calendarSource == source, isEnabled: true) {
        PickerOptionContent(
          icon: icon,
          title: title,
          accentColor: Color(selectedColor),
          isSelected: calendarSource == source
        )
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text(title))
  }

  private var lockedAppleHealthStepsSection: some View {
    CustomSection(label: "Tracking Type") {
      PickerOptionTile(isSelected: true, isEnabled: false) {
        PickerOptionContent(
          icon: TrackingType.binary.icon,
          title: "Binary Target",
          accentColor: Color(selectedColor),
          isSelected: true
        )
      }
      .padding(.all, 2)
      .sameLevelGroupBackground()
    }
  }

  private func applyCalendarSourceDefaults(_ source: CalendarSource) {
    guard source == .appleHealthSteps else { return }
    clearExistingStreakHistory()
    cadence = .daily
    trackingType = .binary
    dailyTarget = 8000
    selectedUnit = .steps
    defaultRecordValue = 1
    recurringReminderEnabled = false
    additionalReminderTimes = []
    suppressWhenCompleted = false
    streakProtectionEnabled = false
    trackingStartedAt = Self.currentYearStartDate()
  }

  private static func currentYearStartDate() -> Date {
    let calendar = LocalDayCalendar.calendar
    let year = calendar.component(.year, from: Date())
    return calendar.date(from: DateComponents(year: year, month: 1, day: 1))
      ?? LocalDayCalendar.startOfDay(for: Date())
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
