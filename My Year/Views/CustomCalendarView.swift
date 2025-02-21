import SwiftUI
import SharedModels
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
    private let store = CustomCalendarStore.shared
    private let valuationStore = ValuationStore.shared
    
    var calendar: CustomCalendar {
        store.calendars.first { $0.id == calendarId }!
    }
    
    @State private var selectedDate: SelectedDate = .none
    @State private var showingEditSheet = false
    @State private var showingYearPicker = false
    @State private var tempSelectedYear: Int = Calendar.current.component(.year, from: Date())
    
    private let availableYears: [Int] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear-10)...currentYear).reversed()
    }()
    
    private func getMaxCount() -> Int {
        let maxCount = calendar.entries.values.map { $0.count }.max() ?? 1
        return max(maxCount, 1) // Ensure we don't divide by zero
    }
    
    private func colorForDay(_ day: Int) -> Color {
        let dayDate = valuationStore.dateForDay(day)
        
        if day >= valuationStore.currentDayNumber {
            return Color("dot-inactive")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateKey = dateFormatter.string(from: dayDate)
        
        if let entry = calendar.entries[dateKey] {
            switch calendar.trackingType {
            case .binary:
                return entry.completed ? Color(calendar.color) : Color("dot-active")
            case .counter, .multipleDaily:
                let maxCount = getMaxCount()
                let opacity = max(0.2, Double(entry.count) / Double(maxCount))
                return Color(calendar.color).opacity(opacity)
            }
        }
        
        return Color("dot-active")
    }
    
    private func handleDayTap(_ day: Int) {
        let date = valuationStore.dateForDay(day)
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
                        HStack(alignment: .center, spacing: 8) {
                            Text(calendar.name.capitalized)
                                .font(.system(size: 38))
                                .foregroundColor(Color("text-primary"))
                                .fontWeight(.black)
                            
                            Button(action: { showingEditSheet = true }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color("text-tertiary"))
                            }
                        }
                        
                        Button(action: { showingYearPicker = true }) {
                            Text("\(valuationStore.year.description)")
                                .font(.system(size: 16))
                                .foregroundColor(Color("text-tertiary"))
                                .fontWeight(.bold)
                        }
                    }
                    
                    Spacer()
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
                
                let horizontalSpacing = (availableWidth - (dotSize * CGFloat(columns))) / CGFloat(columns - 1)
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
                    Toggle("Completed", isOn: Binding(
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
                    ))
                    .foregroundColor(Color("text-primary"))
                    .tint(Color(calendar.color))
                case .counter:
                    Stepper("Count: \(count)", value: Binding(
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
                    ), in: 0...99)
                    .foregroundColor(Color("text-primary"))
                case .multipleDaily:
                    VStack(alignment: .leading, spacing: 8) {
                        Stepper("Count: \(count) / \(calendar.dailyTarget)", value: Binding(
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
                        ), in: 0...99)
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
            if let existingEntry = CustomCalendarStore.shared.getEntry(calendarId: calendar.id, date: date) {
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
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    init(calendar: CustomCalendar, onSave: @escaping (CustomCalendar) -> Void) {
        self.calendar = calendar
        self.onSave = onSave
        _name = State(initialValue: calendar.name)
        _selectedColor = State(initialValue: calendar.color)
        _trackingType = State(initialValue: calendar.trackingType)
        _dailyTarget = State(initialValue: calendar.dailyTarget)
        _recurringReminderEnabled = State(initialValue: calendar.recurringReminderEnabled)

        
        // Default reminder time set to 9:00 AM as it's a common time for daily reminders
        let defaultTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        if calendar.recurringReminderEnabled, let hour = calendar.reminderHour, let minute = calendar.reminderMinute {
            _reminderTime = State(initialValue: Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? defaultTime)
        } else {
            _reminderTime = State(initialValue: defaultTime)
        }
    }
    
    private let colors = [
        "mood-terrible",
        "mood-bad",
        "mood-neutral",
        "mood-good",
        "mood-excellent"
    ]
    
    private func scheduleNotifications(for calendar: CustomCalendar) {
        guard calendar.recurringReminderEnabled, let hour = calendar.reminderHour, let minute = calendar.reminderMinute else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [calendar.id.uuidString])
            return
        }

        let content = UNMutableNotificationContent()
        content.title = String(format: NSLocalizedString("notification.reminder.title", comment: "Notification title for calendar reminder"), calendar.name)
        content.sound = .default

        let components = DateComponents(hour: hour, minute: minute)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: calendar.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.showErrorAlert = true
                    self.errorMessage = "Failed to schedule notification: \(error.localizedDescription)"
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
        if timeComponents.hour! < nowComponents.hour! || (timeComponents.hour! == nowComponents.hour! && timeComponents.minute! <= nowComponents.minute!) {
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
                Toggle("Recurring Reminder", isOn: Binding(
                    get: { recurringReminderEnabled },
                    set: { newValue in
                        if newValue {
                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                                if let error = error {
                                    print("Failed to request notification permission: \(error.localizedDescription)")
                                }
                                DispatchQueue.main.async {
                                    recurringReminderEnabled = granted
                                    if !granted {
                                        // Show alert about enabling notifications in Settings
                                    }
                                }
                            }
                        } else {
                            recurringReminderEnabled = newValue
                        }
                    }
                ))
                if recurringReminderEnabled {
                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: [.hourAndMinute])
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
                    let updatedCalendar = CustomCalendar(
                        id: calendar.id,
                        name: name,
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
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Notification Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
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