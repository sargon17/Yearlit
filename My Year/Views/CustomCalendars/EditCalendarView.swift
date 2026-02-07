import RevenueCat
import SharedModels
import SwiftUI
import SwiftfulRouting

struct EditCalendarView: View {
  @Environment(\.dismiss) private var dismiss: DismissAction
  let calendar: CustomCalendar
  let onSave: (CustomCalendar) -> Void
  let onDelete: (CustomCalendar) -> Void

  @State private var customerInfo: CustomerInfo?
  @State private var name: String
  @State private var selectedColor: String
  @State private var trackingType: TrackingType
  @State private var dailyTarget: Int
  @State private var recurringReminderEnabled: Bool
  @State private var reminderTime: Date
  @State private var selectedUnit: UnitOfMeasure?
  @State private var defaultRecordValue: Int
  @State private var isArchived: Bool
  @State private var calendarError: CalendarError?
  @State private var showingDeleteConfirmation = false
  @State private var currencySymbol: String
  @State private var entries: [String: CalendarEntry]
  @State private var notificationPrivacyMode: NotificationPrivacyMode
  @State private var suppressWhenCompleted: Bool
  @State private var additionalReminderTimes: [ReminderTime]
  @State private var streakProtectionEnabled: Bool
  @State private var streakProtectionThreshold: Int
  @State private var showingNotificationSettings: Bool = false

  @FocusState private var isNameFocused: Bool
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.router) private var router

  init(
    calendar: CustomCalendar, onSave: @escaping (CustomCalendar) -> Void,
    onDelete: @escaping (CustomCalendar) -> Void
  ) {
    self.calendar = calendar
    self.onSave = onSave
    self.onDelete = onDelete
    _name = State(initialValue: calendar.name)
    _selectedColor = State(initialValue: calendar.color)
    _trackingType = State(initialValue: calendar.trackingType)
    _dailyTarget = State(initialValue: calendar.dailyTarget)
    _recurringReminderEnabled = State(initialValue: calendar.recurringReminderEnabled)
    _selectedUnit = State(initialValue: calendar.unit)
    _defaultRecordValue = State(initialValue: calendar.defaultRecordValue ?? 1)
    _currencySymbol = State(initialValue: calendar.currencySymbol ?? "$")
    _isArchived = State(initialValue: calendar.isArchived)
    _entries = State(initialValue: calendar.entries)
    _notificationPrivacyMode = State(initialValue: calendar.notificationPrivacyMode)
    _suppressWhenCompleted = State(initialValue: calendar.suppressWhenCompleted)
    _additionalReminderTimes = State(initialValue: calendar.additionalReminderTimes)
    _streakProtectionEnabled = State(initialValue: calendar.streakProtectionEnabled)
    _streakProtectionThreshold = State(initialValue: calendar.streakProtectionThreshold)

    // Default reminder time set to 9:00 AM as it's a common time for daily reminders
    let defaultTime =
      Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    if calendar.recurringReminderEnabled, let hour = calendar.reminderHour,
      let minute = calendar.reminderMinute
    {
      _reminderTime = State(
        initialValue: Calendar.current.date(
          bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? defaultTime)
    } else {
      _reminderTime = State(initialValue: defaultTime)
    }
  }

  private let colors = [
    "mood-terrible",
    "mood-bad",
    "qs-amber",
    "mood-neutral",
    "qs-lime",
    "mood-good",
    "qs-emerald",
    "qs-teal",
    "qs-cyan",
    "qs-sky",
    "qs-blue",
    "qs-indigo",
    "mood-excellent",
    "qs-fuchsia",
    "qs-pink",
    "qs-rose"
  ]

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
      return "Track a simple yes/no each day. Great for habits you either complete or skip."
    case .counter:
      return "Log a numeric value per day, like pages read or minutes practiced."
    case .multipleDaily:
      return "Check in multiple times per day toward a daily target."
    }
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

        TrackingPicker(trackingType: $trackingType, color: Color(selectedColor))

        ZStack(alignment: .leading) {
          Text(trackingTypeDescription)
            .font(.footnote)
            .foregroundStyle(.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
            .id(trackingType)
            .transition(.blurReplace)
        }
        .animation(.snappy, value: trackingType)

        if trackingType == .multipleDaily || trackingType == .counter {
          CustomSection(label: "Settings for \(trackingTypeLabel)") {

            VStack(spacing: 2) {

              if trackingType == .multipleDaily {
                HStack {
                  Text("Daily Target")
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
                  if selectedUnit == nil {
                    Text("None")
                  }
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
            .background(getVoidColor(colorScheme: colorScheme))

          }
        }

        CustomSection(label: "Color") {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack {
              ForEach(colors, id: \.self) { color in
                Circle()
                  .fill(Color(color))
                  .frame(width: 30, height: 30)
                  .overlay(
                    Circle()
                      .stroke(.white, lineWidth: selectedColor == color ? 2 : 0)
                  )
                  .onTapGesture {
                    withAnimation(.snappy) {
                      selectedColor = color
                    }
                    Task {
                      await hapticFeedback(.rigid)
                    }
                  }
              }
            }.padding(2)
              .padding(.horizontal, 10)
          }
          .padding(.vertical)
          .scrollClipDisabled(true)
          .sameLevelBorder(radius: 6, color: .black)
          .patternStyle()
          .cornerRadius(6)

        }

        CustomSection(label: "Notifications") {
          VStack(spacing: 2) {
            Button(action: { showingNotificationSettings = true }) {
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text("Notification settings")
                    .labelStyle(type: .secondary)
                  Text(
                    recurringReminderEnabled
                      ? "On • tap to customize privacy, suppression, and more."
                      : "Off • set a daily reminder and privacy level."
                  )
                  .font(.caption)
                  .foregroundStyle(.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                  .font(.system(size: 12, design: .monospaced))
                  .foregroundStyle(.textTertiary)
              }
              .padding(.horizontal)
              .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .sameLevelBorder(isFlat: true)
          }
          .padding(.all, 2)
          .background(getVoidColor(colorScheme: colorScheme))
        }

        CustomSection(label: "Already active streak?") {
          VStack(spacing: 8) {
            Button(action: {
              router.showScreen(.sheet) { _ in
                ExistingStreakSheet(
                  trackingType: trackingType,
                  dailyTarget: dailyTarget,
                  defaultDailyValue: defaultRecordValue,
                  existingEntries: entries,
                  accentColor: Color(selectedColor)
                ) { newEntries in
                  for (key, entry) in newEntries {
                    entries[key] = entry
                  }
                  let updatedCalendar = makeUpdatedCalendar()
                  onSave(updatedCalendar)
                }
              }
            }) {
              Text("Add existing streak")
                .frame(maxWidth: .infinity, alignment: .center)
                .fontWeight(.bold)
                .padding()
            }
            .sameLevelBorder()
            .foregroundStyle(.textSecondary)
          }
          .padding(.all, 2)
          .background(getVoidColor(colorScheme: colorScheme))
        }
        Text("Already started elsewhere? Bring your streak here.")
          .font(.footnote)
          .foregroundStyle(.textTertiary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 8)

        CustomSeparator()
          .padding(.horizontal, -16)
          .padding(.vertical, 16)

        CustomSection(label: "Danger Zone") {
          VStack(spacing: 2) {
            Button(action: {
              var updatedCalendar = calendar
              updatedCalendar.isArchived.toggle()
              isArchived = updatedCalendar.isArchived
              scheduleNotifications(for: updatedCalendar, store: CustomCalendarStore.shared)
              onSave(updatedCalendar)
              dismiss()
            }) {
              Text(isArchived ? "Unarchive Calendar" : "Archive Calendar")
                .frame(maxWidth: .infinity, alignment: .center)
                .fontWeight(.bold)
                .padding()
            }
            .sameLevelBorder()
            .foregroundStyle(.textSecondary)

          }
          .padding(.all, 2)
          .background(getVoidColor(colorScheme: colorScheme))

          Text(
            isArchived
              ? "Unarchiving restores this calendar to your boards and tracking lists."
              : "Archiving hides this calendar from your boards without deleting past data."
          )
          .font(.footnote)
          .foregroundStyle(.textTertiary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 8)
          .padding(.bottom, 12)

          VStack(spacing: 2) {
            Button(action: {
              showingDeleteConfirmation = true
            }) {
              Text("Delete Calendar")
                .frame(maxWidth: .infinity, alignment: .center)
                .fontWeight(.bold)
                .padding()
            }
            .sameLevelBorder(color: .moodTerrible)
            .foregroundStyle(.surfaceMuted)
          }
          .padding(.all, 2)
          .background(getVoidColor(colorScheme: colorScheme))
        }
        .alert("Delete Calendar", isPresented: $showingDeleteConfirmation) {
          Button("Cancel", role: .cancel) {}
          Button("Delete", role: .destructive) {
            onDelete(calendar)
            cancelNotifications(for: calendar)
            dismiss()
          }
        } message: {
          Text("Are you sure you want to delete this calendar? This action cannot be undone.")
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
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .onAppear {
      Purchases.shared.getCustomerInfo { info, _ in
        customerInfo = info
      }
    }
    .navigationTitle("Edit Calendar")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          dismiss()
        }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
          guard !trimmedName.isEmpty && trimmedName.count <= 50 else {
            calendarError = .invalidName
            return
          }
          let updatedCalendar = makeUpdatedCalendar()
          scheduleNotifications(for: updatedCalendar, store: CustomCalendarStore.shared)
          onSave(updatedCalendar)
          dismiss()
        }
        .disabled(name.isEmpty)
      }
    }
    .sheet(isPresented: $showingNotificationSettings) {
      NotificationSettingsDraftSheet(
        calendarName: name,
        trackingType: trackingType,
        accentColor: Color(selectedColor),
        customerInfo: customerInfo,
        recurringReminderEnabled: $recurringReminderEnabled,
        reminderTime: $reminderTime,
        notificationPrivacyMode: $notificationPrivacyMode,
        suppressWhenCompleted: $suppressWhenCompleted,
        additionalReminderTimes: $additionalReminderTimes,
        streakProtectionEnabled: $streakProtectionEnabled,
        streakProtectionThreshold: $streakProtectionThreshold
      )
    }
    .onChange(of: trackingType) { _, newValue in
      if newValue != .multipleDaily {
        additionalReminderTimes = []
      }
    }
  }

  private func makeUpdatedCalendar(isArchived overrideArchived: Bool? = nil) -> CustomCalendar {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    return CustomCalendar(
      id: calendar.id,
      name: trimmedName,
      color: selectedColor,
      trackingType: trackingType,
      dailyTarget: dailyTarget,
      entries: entries,
      isArchived: overrideArchived ?? isArchived,
      recurringReminderEnabled: recurringReminderEnabled,
      reminderTime: recurringReminderEnabled ? validateReminderTime(reminderTime) : nil,
      order: calendar.order,
      unit: (trackingType == .counter || trackingType == .multipleDaily) ? selectedUnit : nil,
      defaultRecordValue: (trackingType == .counter || trackingType == .multipleDaily)
        ? defaultRecordValue : nil,
      currencySymbol: ((trackingType == .counter || trackingType == .multipleDaily)
        && selectedUnit == .currency) ? currencySymbol : nil,
      reminderTimeZone: calendar.reminderTimeZone,
      notificationPrivacyMode: notificationPrivacyMode,
      suppressWhenCompleted: suppressWhenCompleted,
      additionalReminderTimes: additionalReminderTimes,
      streakProtectionEnabled: streakProtectionEnabled,
      streakProtectionThreshold: streakProtectionThreshold
    )
  }

}
