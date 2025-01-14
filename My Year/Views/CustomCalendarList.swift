import SwiftUI
import SharedModels

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
                            destination: CustomCalendarView(calendarId: calendar.id)
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
            Button(action: { showingCreateSheet = true }) {
                Image(systemName: "plus")
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
    }
}

struct CreateCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    let onCreate: (CustomCalendar) -> Void
    
    @State private var name = ""
    @State private var selectedColor = "mood-good"
    @State private var trackingType: TrackingType = .binary
    @State private var dailyTarget = 2
    
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
                        dailyTarget: dailyTarget
                    )
                    onCreate(calendar)
                }
                .disabled(name.isEmpty)
            }
        }
    }
}

#Preview {
    NavigationView {
        CustomCalendarList()
    }
} 
