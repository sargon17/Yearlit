import SharedModels
import SwiftUI
import UserNotifications

enum SelectedDate: Equatable {
  case none
  case selected(Date)

  var date: Date? {
    switch self {
    case .none:
      return nil
    case .selected(let date):
      return date
    }
  }

  var isPresented: Bool {
    if case .selected = self {
      return true
    }
    return false
  }
}

struct CustomCalendarView: View {
  let calendarId: UUID
  private let store: CustomCalendarStore = CustomCalendarStore.shared
  private let valuationStore: ValuationStore = ValuationStore.shared

  var calendar: CustomCalendar {
    store.calendars.first { $0.id == calendarId }!
  }

  @State private var selectedDate: SelectedDate = .none
  @State private var showingEditSheet: Bool = false
  @State private var showingYearPicker: Bool = false
  @State private var tempSelectedYear: Int = Calendar.current.component(.year, from: Date())
  @State private var calendarError: CalendarError?

  private let availableYears: [Int] = {
    let currentYear: Int = Calendar.current.component(.year, from: Date())
    return Array((currentYear - 10)...currentYear).reversed()
  }()

  private func getMaxCount() -> Int {
    let maxCount = calendar.entries.values.map { $0.count }.max() ?? 1
    return max(maxCount, 1)  // Ensure we don't divide by zero
  }

  private func colorForDay(_ day: Int) -> Color {
    let dayDate = valuationStore.dateForDay(day)

    if day >= valuationStore.currentDayNumber {
      return Color("dot-inactive")
    }

    let dateFormatter: DateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let dateKey: String = dateFormatter.string(from: dayDate)

    if let entry: CalendarEntry = calendar.entries[dateKey] {
      switch calendar.trackingType {
      case .binary:
        return entry.completed ? Color(calendar.color) : Color("dot-active")
      case .counter, .multipleDaily:
        let maxCount: Int = getMaxCount()
        let opacity = max(0.2, Double(entry.count) / Double(maxCount))
        return Color(calendar.color).opacity(opacity)
      }
    }

    return Color("dot-active")
  }

  private func handleDayTap(_ day: Int) {
    let date: Date = valuationStore.dateForDay(day)
    if day < valuationStore.currentDayNumber {
      selectedDate = .selected(date)
    }
  }

  private func getStats() -> (activeDays: Int, totalCount: Int, maxCount: Int) {
    let activeDays = calendar.entries.values.filter { entry in
      switch calendar.trackingType {
      case .binary:
        return entry.completed
      case .counter, .multipleDaily:
        return entry.count > 0
      }
    }.count

    let totalCount = calendar.entries.values.reduce(0) { $0 + $1.count }
    let maxCount = calendar.entries.values.map { $0.count }.max() ?? 0

    return (activeDays, totalCount, maxCount)
  }

  var body: some View {
    VStack {
      // Stats header
      VStack(spacing: 10) {
        HStack(alignment: .center, spacing: 6) {
          VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
              Text(calendar.name.capitalized)
                .font(.system(size: 38))
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .foregroundColor(Color("text-primary"))
                .fontWeight(.black)
                .onTapGesture {
                  showingEditSheet = true
                }

              if calendar.recurringReminderEnabled, let hour = calendar.reminderHour,
                let minute = calendar.reminderMinute
              {
                HStack(alignment: .center, spacing: 4) {
                  let reminderTime = String(format: "%02d:%02d", hour, minute)
                  Image(systemName: "bell.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color("text-tertiary").opacity(0.5))
                  Text(reminderTime)
                    .font(.system(size: 12))
                    .foregroundColor(Color("text-tertiary").opacity(0.5))
                }.onTapGesture {
                  showingEditSheet = true
                }
              }

              Spacer()

              let today = valuationStore.dateForDay(valuationStore.currentDayNumber - 1)
              Button(action: {
                var newEntry = CalendarEntry(date: today, count: 1, completed: true)  // Default entry

                // Check if an entry already exists for today
                if let existingEntry = store.getEntry(calendarId: calendar.id, date: today) {
                  // If the tracking type is counter or multipleDaily, increment the count
                  if calendar.trackingType == .counter || calendar.trackingType == .multipleDaily {
                    newEntry = CalendarEntry(
                      date: today,
                      count: existingEntry.count + 1,
                      completed: existingEntry.completed
                    )
                  } else {
                    // If it's binary, toggle the completed state
                    newEntry = CalendarEntry(
                      date: today,
                      count: 1,
                      completed: !existingEntry.completed
                    )
                  }
                }
                store.addEntry(calendarId: calendar.id, entry: newEntry)
              }) {
                ZStack {
                  RoundedRectangle(cornerRadius: 4)
                    .fill(Color(calendar.color).opacity(0.1))
                    .frame(width: 24, height: 24)

                  Image(
                    systemName: calendar.trackingType == .binary
                      && store.getEntry(calendarId: calendar.id, date: today) != nil
                      && store.getEntry(calendarId: calendar.id, date: today)!.completed
                      ? "minus" : "plus"
                  )
                  .font(.system(size: 16))
                  .foregroundColor(Color(calendar.color))
                }
              }.frame(width: 24, height: 24)

            }

            Button(action: { showingYearPicker = true }) {
              Text("\(valuationStore.year.description)")
                .font(.system(size: 16))
                .foregroundColor(Color("text-tertiary"))
                .fontWeight(.bold)
            }
          }
        }
        .padding(.horizontal)

        let stats = getStats()
        HStack {
          VStack(alignment: .leading) {
            Text("\(stats.activeDays)")
              .font(.system(size: 24))
              .foregroundColor(Color("text-primary"))
              .fontWeight(.bold)

            Text("Active Days")
              .font(.system(size: 10))
              .foregroundColor(Color("text-tertiary"))
          }

          Spacer()

          if calendar.trackingType != .binary {
            VStack(alignment: .center) {
              Text("\(stats.totalCount)")
                .font(.system(size: 24))
                .foregroundColor(Color("text-primary"))
                .fontWeight(.bold)

              Text("Total Count")
                .font(.system(size: 10))
                .foregroundColor(Color("text-tertiary"))
            }

            Spacer()

            VStack(alignment: .trailing) {
              Text("\(stats.maxCount)")
                .font(.system(size: 24))
                .foregroundColor(Color("text-primary"))
                .fontWeight(.bold)

              Text("Max Count")
                .font(.system(size: 10))
                .foregroundColor(Color("text-tertiary"))
            }
          }
        }
        .padding(.horizontal)
      }

      // Calendar grid
      GeometryReader { geometry in
        let dotSize: CGFloat = 10
        let padding: CGFloat = 20
        let store = ValuationStore.shared

        let availableWidth = geometry.size.width - (padding * 2)
        let availableHeight = geometry.size.height - (padding * 2)

        let aspectRatio = availableWidth / availableHeight
        let targetColumns = Int(sqrt(Double(365) * aspectRatio))
        let columns = min(targetColumns, 365)
        let rows = Int(ceil(Double(365) / Double(columns)))

        let horizontalSpacing =
          (availableWidth - (dotSize * CGFloat(columns))) / CGFloat(columns - 1)
        let verticalSpacing = (availableHeight - (dotSize * CGFloat(rows))) / CGFloat(rows - 1)

        VStack(spacing: verticalSpacing) {
          ForEach(0..<rows, id: \.self) { row in
            HStack(spacing: horizontalSpacing) {
              ForEach(0..<columns, id: \.self) { col in
                let day = row * columns + col
                if day < store.numberOfDaysInYear {
                  RoundedRectangle(cornerRadius: 3)
                    .fill(colorForDay(day))
                    .frame(width: dotSize, height: dotSize)
                    .onTapGesture {
                      handleDayTap(day)
                    }
                } else {
                  Color.clear.frame(width: dotSize, height: dotSize)
                }
              }
            }
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showingEditSheet) {
      NavigationView {
        EditCalendarView(calendar: calendar) { updatedCalendar in
          store.updateCalendar(updatedCalendar)
        }
        .background(Color("surface-muted"))
      }
      .background(Color("surface-muted"))
    }
    .sheet(isPresented: $showingYearPicker) {
      NavigationView {
        VStack {
          Picker("Select Year", selection: $tempSelectedYear) {
            ForEach(availableYears, id: \.self) { year in
              Text(year.description)
                .foregroundColor(Color("text-primary"))
                .tag(year)
            }
          }
          .pickerStyle(.wheel)
        }
        .navigationTitle("Select Year")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              tempSelectedYear = valuationStore.selectedYear
              showingYearPicker = false
            }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
              valuationStore.selectedYear = tempSelectedYear
              showingYearPicker = false
            }
          }
        }
        .onAppear {
          tempSelectedYear = valuationStore.selectedYear
        }
        .background(Color("surface-muted"))
      }
      .background(Color("surface-muted"))
      .presentationDetents([.height(280)])
    }
    .sheet(
      isPresented: Binding(
        get: { selectedDate.isPresented },
        set: { if !$0 { selectedDate = .none } }
      )
    ) {
      if let date = selectedDate.date {
        NavigationView {
          CalendarEntryView(calendar: calendar, date: date) { entry in
            store.addEntry(calendarId: calendar.id, entry: entry)
          }
          .background(Color("surface-muted"))
        }
        .background(Color("surface-muted"))
        .presentationDetents([.fraction(0.3)])
      }
    }
    .alert(
      isPresented: Binding(
        get: { calendarError != nil },
        set: { if !$0 { calendarError = nil } }
      )
    ) {
      Alert(
        title: Text("Notification Error"),
        message: Text(calendarError?.errorDescription ?? "Unknown error"),
        dismissButton: .default(Text("OK")))
    }
  }
}

struct CalendarEntryView: View {
  let calendar: CustomCalendar
  let date: Date
  let onSave: (CalendarEntry) -> Void

  @Environment(\.dismiss) private var dismiss
  @State private var count = 0
  @State private var completed = false

  var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter.string(from: date)
  }

  var body: some View {
    Form {
      Section {
        Text(formattedDate)
          .font(.headline)
      }.listRowBackground(Color("surface-primary"))

      Section {
        switch calendar.trackingType {
        case .binary:
          Toggle(
            "Completed",
            isOn: Binding(
              get: { completed },
              set: { newValue in
                completed = newValue
                let entry = CalendarEntry(
                  date: date,
                  count: count,
                  completed: newValue
                )
                onSave(entry)
              }
            )
          )
          .foregroundColor(Color("text-primary"))
          .tint(Color(calendar.color))
        case .counter:
          Stepper(
            "Count: \(count)",
            value: Binding(
              get: { count },
              set: { newValue in
                count = newValue
                let entry = CalendarEntry(
                  date: date,
                  count: newValue,
                  completed: completed
                )
                onSave(entry)
              }
            ), in: 0...99
          )
          .foregroundColor(Color("text-primary"))
        case .multipleDaily:
          VStack(alignment: .leading, spacing: 8) {
            Stepper(
              "Count: \(count) / \(calendar.dailyTarget)",
              value: Binding(
                get: { count },
                set: { newValue in
                  count = newValue
                  let entry = CalendarEntry(
                    date: date,
                    count: newValue,
                    completed: newValue >= calendar.dailyTarget
                  )
                  onSave(entry)
                }
              ), in: 0...99
            )
            .foregroundColor(Color("text-primary"))

            ProgressView(value: Double(count), total: Double(calendar.dailyTarget))
              .tint(Color(calendar.color))
          }
        }
      }.listRowBackground(Color("surface-primary"))
    }
    .scrollContentBackground(.hidden)
    .background(Color("surface-muted"))
    .navigationTitle("Add Entry")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Done") {
          dismiss()
        }
      }
    }
    .onAppear {
      if let existingEntry = CustomCalendarStore.shared.getEntry(
        calendarId: calendar.id, date: date)
      {
        count = existingEntry.count
        completed = existingEntry.completed
      }
    }
  }
}

struct EditCalendarView: View {
  @Environment(\.dismiss) private var dismiss
  let calendar: CustomCalendar
  let onSave: (CustomCalendar) -> Void

  @State private var name: String
  @State private var selectedColor: String
  @State private var trackingType: TrackingType
  @State private var dailyTarget: Int
  @State private var recurringReminderEnabled: Bool
  @State private var reminderTime: Date
  @State private var calendarError: CalendarError?

  init(calendar: CustomCalendar, onSave: @escaping (CustomCalendar) -> Void) {
    self.calendar = calendar
    self.onSave = onSave
    _name = State(initialValue: calendar.name)
    _selectedColor = State(initialValue: calendar.color)
    _trackingType = State(initialValue: calendar.trackingType)
    _dailyTarget = State(initialValue: calendar.dailyTarget)
    _recurringReminderEnabled = State(initialValue: calendar.recurringReminderEnabled)

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
    "mood-neutral",
    "mood-good",
    "mood-excellent",
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
      }
      .listRowBackground(Color("surface-primary"))

      Section {
        Picker("Tracking Type", selection: $trackingType) {
          Text("Once a day").tag(TrackingType.binary)
          Text("Multiple times (unlimited)").tag(TrackingType.counter)
          Text("Multiple times (with target)").tag(TrackingType.multipleDaily)
        }

        if trackingType == .multipleDaily {
          Stepper("Daily Target: \(dailyTarget)", value: $dailyTarget, in: 1...10)
        }
      }
      .listRowBackground(Color("surface-primary"))

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
      .listRowBackground(Color("surface-primary"))

      Section {
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
        }
      } header: {
        Text("Color")
      }
      .listRowBackground(Color("surface-primary"))
    }
    .scrollContentBackground(.hidden)
    .background(Color("surface-muted"))
    .navigationTitle("Edit Calendar")
    .navigationBarTitleDisplayMode(.inline)
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
            reminderTime: recurringReminderEnabled ? validateReminderTime(reminderTime) : nil
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

private enum CalendarError: LocalizedError {
  case invalidName
  case notificationPermissionDenied
  case notificationSchedulingFailed(Error)

  var errorDescription: String? {
    switch self {
    case .invalidName:
      return "Please enter a valid name (1-50 characters)"
    case .notificationPermissionDenied:
      return "Please enable notifications in Settings to receive reminders."
    case .notificationSchedulingFailed(let error):
      return "Failed to schedule notification: \(error.localizedDescription)"
    }
  }
}

#Preview {
  NavigationView {
    CustomCalendarView(
      calendarId: CustomCalendar(
        name: "Test Calendar",
        color: "mood-good",
        trackingType: .binary
      ).id
    )
  }
}
