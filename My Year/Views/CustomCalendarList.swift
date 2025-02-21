import SwiftUI
import SharedModels
import RevenueCat
import RevenueCatUI

struct CalendarListItem: View {
    let name: String
    let description: String
    let color: String
    
    var body: some View {
        HStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(color))
                .frame(width: 12, height: 12)
                .padding(.top, 5)
            
            VStack(alignment: .leading) {
                Text(name.capitalized)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color("text-primary"))
                    
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color("text-tertiary"))
            }
        }
    }
}

struct CustomCalendarList: View {
    @State private var showingCreateSheet = false
    @State private var displayPaywall = false
    @State private var customerInfo: CustomerInfo?
    private let store = CustomCalendarStore.shared
    
    var body: some View {
        List {
            // Main Year Calendar
            NavigationLink(
                destination: YearGrid()
                    .background(Color("surface-muted"))
            ) {
                CalendarListItem(
                    name: "Year Calendar",
                    description: "Daily mood tracking",
                    color: "mood-excellent"
                )
            }
            .listRowBackground(Color("surface-primary"))
            
            // Custom Calendars Section
            if !store.calendars.isEmpty {
                Section("Custom Calendars") {
                    ForEach(store.calendars) { calendar in
                        NavigationLink(
                            destination: SwipeableCalendarView(initialCalendarId: calendar.id)
                                .background(Color("surface-muted"))
                        ) {
                            CalendarListItem(
                                name: calendar.name,
                                description: calendar.trackingType.description,
                                color: calendar.color
                            )
                        }
                        .listRowBackground(Color("surface-primary"))
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            store.deleteCalendar(id: store.calendars[index].id)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("surface-muted"))
        .navigationTitle("Calendars")
        .toolbar {
            Button(action: { handleAddCalendar() }) {
                Image(systemName: "plus")
            }
        }
        .onAppear {
            Purchases.shared.getCustomerInfo { (customerInfo, error) in
                self.customerInfo = customerInfo
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            NavigationView {
                CreateCalendarView { newCalendar in
                    store.addCalendar(newCalendar)
                    showingCreateSheet = false
                }
                .background(Color("surface-muted"))
            }
            .background(Color("surface-muted"))
        }
        .sheet(isPresented: $displayPaywall) {
            PaywallView(displayCloseButton: true)
        }
    }

    func handleAddCalendar() {
        if customerInfo?.entitlements["premium"]?.isActive ?? false || store.calendars.count < 3 {
            showingCreateSheet = true
        } else {
            displayPaywall = true
        }
    }
}

struct CreateCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    let onCreate: (CustomCalendar) -> Void
    
    @State private var name = ""
    @State private var selectedColor = "mood-good"
    @State private var trackingType: TrackingType = .binary
    @State private var dailyTarget = 2
    @State private var recurringReminderEnabled: Bool = false
    @State private var reminderTime: Date = Date()
    
    private let colors = [
        "mood-terrible",
        "mood-bad",
        "mood-neutral",
        "mood-good",
        "mood-excellent"
    ]
    
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
                Toggle("Recurring Reminder", isOn: $recurringReminderEnabled)
                if recurringReminderEnabled {
                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: [.hourAndMinute])
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
        .navigationTitle("New Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    let calendar = CustomCalendar(
                        name: name,
                        color: selectedColor,
                        trackingType: trackingType,
                        dailyTarget: dailyTarget,
                        recurringReminderEnabled: recurringReminderEnabled,
                        reminderTime: recurringReminderEnabled ? reminderTime : nil
                    )
                    onCreate(calendar)
                }
                .disabled(name.isEmpty)
            }
        }
    }
}

struct SwipeableCalendarView: View {
    let initialCalendarId: UUID
    private let store = CustomCalendarStore.shared
    @State private var selectedIndex: Int
    
    init(initialCalendarId: UUID) {
        self.initialCalendarId = initialCalendarId
        let index = store.calendars.firstIndex { $0.id == initialCalendarId } ?? 0
        _selectedIndex = State(initialValue: index)
    }
    
    private var currentCalendar: CustomCalendar? {
        guard selectedIndex < store.calendars.count else { return nil }
        return store.calendars[selectedIndex]
    }
    
    private func quickAddEntry() {
        guard let calendar = currentCalendar else { return }
        
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateKey = dateFormatter.string(from: today)
        
        let currentEntry = calendar.entries[dateKey]
        
        switch calendar.trackingType {
        case .binary:
            // For binary, just toggle completion
            let entry = CalendarEntry(
                date: today,
                count: 1,
                completed: true
            )
            store.addEntry(calendarId: calendar.id, entry: entry)
            
        case .counter:
            // For counter, increment by 1
            let newCount = (currentEntry?.count ?? 0) + 1
            let entry = CalendarEntry(
                date: today,
                count: newCount,
                completed: true
            )
            store.addEntry(calendarId: calendar.id, entry: entry)
            
        case .multipleDaily:
            // For multiple daily, increment by 1 if under target
            let currentCount = currentEntry?.count ?? 0
            if currentCount < calendar.dailyTarget {
                let newCount = currentCount + 1
                let entry = CalendarEntry(
                    date: today,
                    count: newCount,
                    completed: newCount >= calendar.dailyTarget
                )
                store.addEntry(calendarId: calendar.id, entry: entry)
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(Array(store.calendars.enumerated()), id: \.element.id) { index, calendar in
                CustomCalendarView(calendarId: calendar.id)
                    .tag(index)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .never))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: quickAddEntry) {
                    Image(systemName: "plus")
                        .foregroundStyle(Color(currentCalendar?.color ?? "mood-good"))
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        CustomCalendarList()
    }
} 
