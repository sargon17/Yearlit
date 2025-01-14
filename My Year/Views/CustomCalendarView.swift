import SwiftUI
import SharedModels

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
    
    var calendar: CustomCalendar {
        store.calendars.first { $0.id == calendarId }!
    }
    
    @State private var selectedDate: SelectedDate = .none
    
    private func getMaxCount() -> Int {
        let maxCount = calendar.entries.values.map { $0.count }.max() ?? 1
        return max(maxCount, 1) // Ensure we don't divide by zero
    }
    
    private func colorForDay(_ day: Int) -> Color {
        let store = ValuationStore.shared // Using this for date calculations
        let dayDate = store.dateForDay(day)
        
        if day >= store.currentDayNumber {
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
        let store = ValuationStore.shared // Using this for date calculations
        let date = store.dateForDay(day)
        if day < store.currentDayNumber {
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
                    Text(calendar.name.capitalized)
                        .font(.system(size: 38))
                        .foregroundColor(Color("text-primary"))
                        .fontWeight(.black)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                let stats = getStats()
                HStack {
                    VStack(alignment: .leading) {
                        Text("Active Days")
                            .font(.system(size: 14))
                            .foregroundColor(Color("text-secondary"))
                        Text("\(stats.activeDays)")
                            .font(.system(size: 24))
                            .foregroundColor(Color("text-primary"))
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    if calendar.trackingType != .binary {
                        VStack(alignment: .center) {
                            Text("Total Count")
                                .font(.system(size: 14))
                                .foregroundColor(Color("text-secondary"))
                            Text("\(stats.totalCount)")
                                .font(.system(size: 24))
                                .foregroundColor(Color("text-primary"))
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Max Count")
                                .font(.system(size: 14))
                                .foregroundColor(Color("text-secondary"))
                            Text("\(stats.maxCount)")
                                .font(.system(size: 24))
                                .foregroundColor(Color("text-primary"))
                                .fontWeight(.bold)
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
        .navigationTitle(calendar.name)
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