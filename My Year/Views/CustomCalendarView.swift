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
                let opacity = min(1.0, Double(entry.count) / 5.0) // Max intensity at 5 entries
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
    
    var body: some View {
        VStack {
            // Year progress header
            VStack(spacing: 10) {
                HStack(alignment: .center, spacing: 6) {
                    Text(Calendar.current.component(.year, from: Date()).description)
                        .font(.system(size: 68))
                        .foregroundColor(Color("text-primary"))
                        .fontWeight(.black)
                    
                    Spacer()
                    
                    let store = ValuationStore.shared
                    let percent = Double(store.currentDayNumber) / Double(store.numberOfDaysInYear)
                    Text(String(format: "%.1f%%", percent * 100))
                        .font(.system(size: 38))
                        .foregroundColor(Color("text-primary").opacity(0.5))
                        .fontWeight(.regular)
                }
                .padding(.horizontal)
                
                HStack {
                    Spacer()
                    
                    Text("Left: ")
                        .font(.system(size: 22))
                        .foregroundColor(Color("text-primary").opacity(0.5))
                        .fontWeight(.regular)
                    + Text("\(ValuationStore.shared.numberOfDaysInYear - ValuationStore.shared.currentDayNumber)")
                        .font(.system(size: 38))
                        .foregroundColor(Color("text-primary"))
                        .fontWeight(.bold)
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
                        selectedDate = .none
                    }
                }
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
            }
            
            Section {
                switch calendar.trackingType {
                case .binary:
                    Toggle("Completed", isOn: $completed)
                case .counter, .multipleDaily:
                    Stepper("Count: \(count)", value: $count, in: 0...99)
                }
            }
        }
        .navigationTitle("Add Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let entry = CalendarEntry(
                        date: date,
                        count: count,
                        completed: completed
                    )
                    onSave(entry)
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