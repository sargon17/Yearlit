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
    "qs-rose",
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
    Form {
      Section {
        TextField("Calendar Name", text: $name)
          .foregroundColor(Color("text-primary"))
          .fontWeight(.bold)

        Picker("Tracking Type", selection: $trackingType) {
          Text("Once a day").tag(TrackingType.binary)
          Text("Multiple times (unlimited)").tag(TrackingType.counter)
          Text("Multiple times (with target)").tag(TrackingType.multipleDaily)
        }

        if trackingType == .multipleDaily {
          HStack {
            Text("Daily Target")
            Spacer()
            TextField("Target", value: $dailyTarget, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
          }
        }
      }
      .listRowBackground(Color("surface-secondary"))

      // Group Unit of Measure and Currency Symbol together conditionally
      if trackingType == .counter || trackingType == .multipleDaily {
        Section { // Section for Unit/Symbol
          Picker("Unit of Measure", selection: $selectedUnit) {
            Text("None").tag(nil as UnitOfMeasure?)
            ForEach(UnitOfMeasure.Category.allCases, id: \.self) { category in
              Section(header: Text(category.rawValue)) {
                ForEach(UnitOfMeasure.allCasesGrouped[category] ?? [], id: \.self) { unit in
                  Text(unit.displayName).tag(unit as UnitOfMeasure?)
                }
              }
            }
          }

          if selectedUnit == .currency {
            HStack {
              Text("Currency Symbol")
              Spacer()
              TextField("Symbol", text: $currencySymbol)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
            }
          }
        } // End Section for Unit/Symbol
        .listRowBackground(Color("surface-secondary"))
      }

      // Add Stepper for Default Record Value (Separate Section)
      if trackingType == .counter || trackingType == .multipleDaily {
        Section {
          HStack {
            Text("Default Quick Add Value")
            Spacer()
            TextField("Value", value: $defaultRecordValue, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
          }
        }
        .listRowBackground(Color("surface-secondary"))
      }

      Section {
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
                    selectedColor = color
                  }
              }
            }.padding(2)
            .padding(.horizontal, 10)
          }.padding(.horizontal, -20)
      } header: {
        Text("Color")
      }
      .padding(0)
      .listRowBackground(Color("surface-secondary"))

      Section {
        Toggle(
          "Recurring Reminder",
          isOn: Binding(
            get: { recurringReminderEnabled },
            set: { newValue in
              if newValue {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) {
                  granted, error in
                  if let error = error {
                    DispatchQueue.main.async {
                      self.calendarError = .notificationPermissionDenied
                      recurringReminderEnabled = false
                    }
                    return
                  }
                  DispatchQueue.main.async {
                    recurringReminderEnabled = granted
                    if !granted {
                      self.calendarError = .notificationPermissionDenied
                    }
                  }
                }
              } else {
                recurringReminderEnabled = newValue
              }
            }
          ))
        if recurringReminderEnabled {
          DatePicker(
            "Reminder Time", selection: $reminderTime, displayedComponents: [.hourAndMinute]
          )
          .environment(\.timeZone, TimeZone.current)
          Text("Reminders will be sent in your local timezone")
            .font(.caption)
            .foregroundColor(Color("text-tertiary"))
        }
      }
      .listRowBackground(Color("surface-secondary"))

      Section {
        Button(action: {
          showingDeleteConfirmation = true
        }) {
          Text("Delete Calendar")
            .frame(maxWidth: .infinity, alignment: .center)
            .fontWeight(.bold)
        }
      } header: {
        Text("Danger Zone")
          .foregroundColor(Color("mood-terrible"))
      }
      .listRowBackground(Color("mood-terrible"))
      .foregroundColor(Color("surface-muted"))
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
    .scrollContentBackground(.hidden)
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
            defaultRecordValue: (trackingType == .counter || trackingType == .multipleDaily) ? defaultRecordValue : nil,
            currencySymbol: ((trackingType == .counter || trackingType == .multipleDaily) && selectedUnit == .currency) ? currencySymbol : nil
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
