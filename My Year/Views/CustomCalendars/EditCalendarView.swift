import SharedModels
import SwiftUI

struct EditCalendarView: View {
  @Environment(\.dismiss) private var dismiss: DismissAction
  let calendar: CustomCalendar
  let onSave: (CustomCalendar) -> Void
  let onDelete: (CustomCalendar) -> Void

  @State private var name: String
  @State private var selectedColor: String
  @State private var trackingType: TrackingType
  @State private var dailyTarget: Int
  @State private var recurringReminderEnabled: Bool
  @State private var reminderTime: Date
  @State private var selectedUnit: UnitOfMeasure?
  @State private var defaultRecordValue: Int
  @State private var calendarError: CalendarError?
  @State private var showingDeleteConfirmation = false
  @State private var currencySymbol: String

  @FocusState private var isNameFocused: Bool
  @Environment(\.colorScheme) var colorScheme

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

  private func scheduleNotifications(for calendar: CustomCalendar) {
    guard calendar.recurringReminderEnabled, let hour = calendar.reminderHour,
      let minute = calendar.reminderMinute
    else {
      UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
        calendar.id.uuidString
      ])
      return
    }

    let content = UNMutableNotificationContent()
    content.title = String(
      format: NSLocalizedString(
        "notification.reminder.title", comment: "Notification title for calendar reminder"),
      calendar.name)
    content.body = String(
      format: NSLocalizedString(
        "notification.reminder.body", comment: "Notification body for calendar reminder"),
      calendar.name, calendar.dailyTarget)
    content.sound = .default

    let components = DateComponents(hour: hour, minute: minute)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

    let request = UNNotificationRequest(
      identifier: calendar.id.uuidString, content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        DispatchQueue.main.async {
          self.calendarError = .notificationSchedulingFailed(error)
        }
      }
    }
  }

  private func validateReminderTime(_ time: Date) -> Date {
    let calendar = Calendar.current
    let now = Date()

    // Extract hour and minute components
    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
    let nowComponents = calendar.dateComponents([.hour, .minute], from: now)

    // If time is in the past for today, set it for tomorrow
    if timeComponents.hour! < nowComponents.hour!
      || (timeComponents.hour! == nowComponents.hour!
        && timeComponents.minute! <= nowComponents.minute!)
    {
      return calendar.date(byAdding: .day, value: 1, to: time)!
    }
    return time
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {

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

        if trackingType == .multipleDaily || trackingType == .counter {
          CustomSection(label: "Settings for \(trackingType.label)") {

            VStack(spacing: 2) {

              if trackingType == .multipleDaily {
                HStack {
                  Text("Daily Target")
                    .font(.system(size: 12, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.textTertiary)

                  Spacer()
                  TextField("Target", value: $dailyTarget, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
                    .inputStyle(size: .large, radius: 4, color: Color(selectedColor))
                }
                .padding(.leading)
                .padding(.all, 2)
                .sameLevelBorder()
              }

              if trackingType == .counter || trackingType == .multipleDaily {
                HStack {
                  Text("Unit of Measure")
                    .font(.system(size: 12, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.textTertiary)
                  Spacer()
                  if selectedUnit == nil {
                    Text("None")
                  }
                  Picker("Unit of Measure", selection: $selectedUnit) {
                    ForEach(UnitOfMeasure.Category.allCases, id: \.self) {
                      category in
                      Section(header: Text(category.rawValue)) {
                        ForEach(UnitOfMeasure.allCasesGrouped[category] ?? [], id: \.self) { unit in
                          Text(unit.displayName).tag(unit as UnitOfMeasure?)
                        }
                      }
                    }
                  }
                }
                .padding(.leading)
                .padding(.vertical, 8)
                .sameLevelBorder()

                if selectedUnit == .currency {
                  HStack {
                    Text("Currency Symbol")
                      .font(.system(size: 12, design: .monospaced).weight(.semibold))
                      .foregroundStyle(.textTertiary)
                    Spacer()
                    TextField("Symbol", text: $currencySymbol)
                      .multilineTextAlignment(.trailing)
                      .frame(maxWidth: 100)
                      .inputStyle(size: .large, radius: 4, color: Color(selectedColor))
                  }
                  .padding(.leading)
                  .padding(.all, 2)
                  .sameLevelBorder()

                }

              }

              if trackingType == .counter || trackingType == .multipleDaily {
                HStack {
                  Text("Default Quick Add Value")
                    .font(.system(size: 12, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.textTertiary)
                  Spacer()
                  TextField("Value", value: $defaultRecordValue, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
                    .inputStyle(size: .large, radius: 4, color: Color(selectedColor))
                }
                .padding(.leading)
                .padding(.all, 2)
                .sameLevelBorder()

              }
            }
            .padding(.all, 2)
            .background(getVoidColor(colorScheme: colorScheme))
            .cornerRadius(6)
            .outerSameLevelShadow(radius: 6)

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
                      .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
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
          .outerSameLevelShadow(radius: 6)
          .patternStyle()
          .cornerRadius(6)

        }

        CustomSection(label: "Recurring Reminder") {
          VStack(spacing: 2) {

            HStack {
              Text("Set a remined")
                .font(.system(size: 12, design: .monospaced).weight(.semibold))
                .foregroundStyle(.textTertiary)
              Spacer()

              Toggle(
                "",
                isOn: Binding(
                  get: { recurringReminderEnabled },
                  set: { newValue in
                    withAnimation(.snappy) {
                      recurringReminderEnabled = newValue
                    }
                  }
                ))
            }
            .tint(Color(selectedColor))
            .padding(.horizontal)
            .padding(.vertical, 6)
            .sameLevelBorder()

            if recurringReminderEnabled {
              HStack {
                DatePicker(
                  "", selection: $reminderTime, displayedComponents: [.hourAndMinute]
                )
                .tint(Color(selectedColor))
                .datePickerStyle(.wheel)
                .inputStyle(radius: 4, color: Color(selectedColor))
              }
              .padding(.all, 2)
              .sameLevelBorder()
            }
          }.padding(.all, 2)
            .background(getVoidColor(colorScheme: colorScheme))
            .cornerRadius(6)
            .outerSameLevelShadow(radius: 6)

        }

        CustomSection(label: "Danger Zone") {
          VStack(spacing: 2) {
            Button(action: {
              showingDeleteConfirmation = true
            }) {
              Text("Delete Calendar")
                .frame(maxWidth: .infinity, alignment: .center)
                .fontWeight(.bold)
                .padding()
            }.sameLevelBorder(color: .moodTerrible)
              .foregroundStyle(.surfaceMuted)
          }
          .padding(.all, 2)
          .background(getVoidColor(colorScheme: colorScheme))
          .cornerRadius(6)
          .outerSameLevelShadow(radius: 6)
        }
        .alert("Delete Calendar", isPresented: $showingDeleteConfirmation) {
          Button("Cancel", role: .cancel) {}
          Button("Delete", role: .destructive) {
            onDelete(calendar)
            dismiss()
          }
        } message: {
          Text("Are you sure you want to delete this calendar? This action cannot be undone.")
        }
      }
    }
    .padding()
    .accentColor(Color(selectedColor))
    .scrollClipDisabled(true)
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .background(Color("surface-muted"))
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
          let updatedCalendar = CustomCalendar(
            id: calendar.id,
            name: trimmedName,
            color: selectedColor,
            trackingType: trackingType,
            dailyTarget: dailyTarget,
            entries: calendar.entries,
            recurringReminderEnabled: recurringReminderEnabled,
            reminderTime: recurringReminderEnabled ? validateReminderTime(reminderTime) : nil,
            order: calendar.order,
            unit: (trackingType == .counter || trackingType == .multipleDaily) ? selectedUnit : nil,
            defaultRecordValue: (trackingType == .counter || trackingType == .multipleDaily)
              ? defaultRecordValue : nil,
            currencySymbol: ((trackingType == .counter || trackingType == .multipleDaily)
              && selectedUnit == .currency) ? currencySymbol : nil
          )
          onSave(updatedCalendar)
          scheduleNotifications(for: updatedCalendar)
          dismiss()
        }
        .disabled(name.isEmpty)
      }
    }
  }
}
