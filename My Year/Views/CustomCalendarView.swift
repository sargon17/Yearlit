import SharedModels
import SwiftUI
import UserNotifications
import WidgetKit

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
  let calendar: CustomCalendar
  @StateObject private var store: CustomCalendarStore = CustomCalendarStore.shared
  @ObservedObject private var valuationStore: ValuationStore = ValuationStore.shared
  @AppStorage("runtimeDebugEnabled") private var runtimeDebugEnabled: Bool = false

  private let today = Date()

  @State private var selectedDate: SelectedDate = .none
  @State private var showingEditSheet: Bool = false
  @State private var showingYearPicker: Bool = false
  @State private var tempSelectedYear: Int = Calendar.current.component(.year, from: Date())
  @State private var calendarError: CalendarError?

  private let availableYears: [Int] = {
    let currentYear: Int = Calendar.current.component(.year, from: Date())
    return Array((currentYear - 10)...currentYear).reversed()
  }()

  private func fillRandomEntries() {
    // TODO: Implement clearEntries(calendarId:) in CustomCalendarStore to enable clearing before filling.
    // store.clearEntries(calendarId: self.calendar.id)
    
    let calendar = Calendar.current
    let startOfYear = calendar.date(from: DateComponents(year: valuationStore.selectedYear, month: 1, day: 1))!
    
    for day in 0..<valuationStore.currentDayNumber {
      let date = calendar.date(byAdding: .day, value: day, to: startOfYear)!
      let dateKey = customDateFormatter(date: date)
      
      if date <= today {
        switch self.calendar.trackingType {
        case .binary:
          let entry = CalendarEntry(date: date, count: 1, completed: Bool.random())
          store.addEntry(calendarId: self.calendar.id, entry: entry)
        case .counter:
          let count = Int.random(in: 0...5)
          let entry = CalendarEntry(date: date, count: count, completed: count > 0)
          store.addEntry(calendarId: self.calendar.id, entry: entry)
        case .multipleDaily:
          let count = Int.random(in: 0...self.calendar.dailyTarget)
          let entry = CalendarEntry(date: date, count: count, completed: count >= self.calendar.dailyTarget)
          store.addEntry(calendarId: self.calendar.id, entry: entry)
        }
      }
    }
  }

  private func getMaxCount() -> Int {
    let maxCount = calendar.entries.values.map { $0.count }.max() ?? 1
    return max(maxCount, 1)  // Ensure we don't divide by zero
  }

  private func colorForDay(_ day: Int) -> Color {
    let dayDate = valuationStore.dateForDay(day)

    if day >= valuationStore.currentDayNumber {
      return Color("dot-inactive")
    }

    let dateKey: String = customDateFormatter(date: dayDate)

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

  private func getStats() -> CalendarStats {
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

    var currentStreak = 0
    var longestStreak = 0

    // Calculate Longest Streak
    var tempLongestStreak = 0
    for day in (0..<valuationStore.currentDayNumber).reversed() {
      let dayDate = valuationStore.dateForDay(day)
      let dateKey = customDateFormatter(date: dayDate)

      if isDayActive(dateKey: dateKey) {
        tempLongestStreak += 1
      } else {
        longestStreak = max(longestStreak, tempLongestStreak)
        tempLongestStreak = 0  // Reset the streak
      }
    }
    longestStreak = max(longestStreak, tempLongestStreak)  // Check if the streak continues to the beginning of the year

    // Calculate Current Streak
    for day in (0..<valuationStore.currentDayNumber).reversed() {
      let dayDate = valuationStore.dateForDay(day)
      let dateKey = customDateFormatter(date: dayDate)

      // If the day is today, skip checking the entry to avoid resetting the streak
      if isToday(date: dayDate) {
        if isDayActive(dateKey: dateKey) {
          currentStreak += 1
        }
        continue
      }

      if isDayActive(dateKey: dateKey) {
        currentStreak += 1
      } else {
        break
      }
    }

    func isDayActive(dateKey: String) -> Bool {
      if let entry = calendar.entries[dateKey] {
        switch calendar.trackingType {
        case .binary:
          return entry.completed
        case .counter, .multipleDaily:
          return entry.count >= calendar.dailyTarget
        }
      }
      return false
    }
    return CalendarStats(activeDays: activeDays, totalCount: totalCount, maxCount: maxCount, longestStreak: longestStreak, currentStreak: currentStreak)
  }

  private func handleQuickAdd() {
    do {
      // Get the date for the previous day (today is not yet available)
      let today = valuationStore.dateForDay(valuationStore.currentDayNumber - 1)
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
      WidgetCenter.shared.reloadAllTimelines()
    } catch {
      calendarError = .errorAddingEntry(error)
    }

    // Vibrate to provide haptic feedback
    let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
    impactFeedbackgenerator.prepare()
    impactFeedbackgenerator.impactOccurred()
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 10) {
        // Stats header    
        VStack(spacing: 10) {
          HStack(alignment: .center, spacing: 6) {
          VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
              Text(calendar.name.capitalized)
                .font(.system(size: 36, design: .monospaced))
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .foregroundColor(Color("text-primary"))
                .fontWeight(.black)
                .onTapGesture {
                  showingEditSheet = true
                }
                .padding(.top)
              Spacer()

              let today = valuationStore.dateForDay(valuationStore.currentDayNumber - 1)

              if My_YearApp.isDebugMode && runtimeDebugEnabled {
                Button(action: fillRandomEntries) {
                  Image(systemName: "wand.and.stars")
                    .foregroundColor(Color(calendar.color))
                }
                .padding(.horizontal, 4)
              }

              Button(action: {
                handleQuickAdd()
              }) {
                ZStack {
                  RoundedRectangle(cornerRadius: 3)
                    .fill(Color(calendar.color).opacity(0.1))
                    .frame(width: 20, height: 20)

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

            HStack(spacing: 4) {
              Button(action: { showingYearPicker = true }) {
                Text("\(valuationStore.year.description)")
                  .font(.system(size: 12, design: .monospaced))
                  .foregroundColor(Color("text-tertiary"))
              }


              if calendar.recurringReminderEnabled, let hour = calendar.reminderHour,
                let minute = calendar.reminderMinute
              {
                Text("•")
                  .font(.system(size: 4, weight: .black, design: .monospaced))
                  .foregroundColor(Color("text-tertiary"))
                  .padding(.horizontal, 2)

                HStack(alignment: .center, spacing: 4) {
                  let reminderTime = String(format: "%02d:%02d", hour, minute)
                  Image(systemName: "bell")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color("text-tertiary"))
                  Text(reminderTime)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color("text-tertiary"))
                }.onTapGesture {
                  showingEditSheet = true
                }
              }
            }
          }
        }
        .padding(.horizontal)
        CustomSeparator()
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
      .frame(height: UIScreen.main.bounds.height * 0.85)


      let stats = getStats()
      CalendarStatisticsView(stats: stats, accentColor: Color(calendar.color))

      VStack(spacing: 0) {
        Text("Independently engineered. Lovingly crafted.")
        Text("Thank you for your support!")

        Spacer()
        HStack(spacing: 4) {
          Text("Mykhaylo Tymofyeyev")
          Text("•")
          Text("[@tymofyeyev_m](https://x.com/tymofyeyev_m)").foregroundColor(Color(calendar.color))
        }
        .foregroundColor(Color("text-tertiary"))

      }.padding(.horizontal)
      .font(.system(size: 9, design: .monospaced))
      .foregroundColor(Color("text-tertiary").opacity(0.5))
      .multilineTextAlignment(.center)
      .padding(.bottom, 40)

    }.scrollIndicators(.hidden)
    .refreshable {
      store.loadCalendars()
      WidgetCenter.shared.reloadAllTimelines()
    }
    .sheet(isPresented: $showingEditSheet) {
      NavigationView {
        EditCalendarView(
          calendar: calendar,
          onSave: { updatedCalendar in
            store.updateCalendar(updatedCalendar)
          },
          onDelete: { _ in
            store.deleteCalendar(id: calendar.id)
          }
        )
        .background(Color("surface-muted"))
      }
      .background(Color("surface-muted"))
    }
    .sheet(isPresented: $showingYearPicker) {
      NavigationStack {
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
        .navigationBarTitleDisplayMode(.large)
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
    }.overlay {
      HStack {
        Rectangle()
          .fill(Color("devider-bottom"))
          .frame(maxHeight: .infinity, alignment: .trailing)
          .frame(maxWidth: 1)

        Spacer()

        Rectangle()
          .fill(Color("devider-top"))
          .frame(maxHeight: .infinity, alignment: .trailing)
          .frame(maxWidth: 1)
        
        }
      }.ignoresSafeArea(edges: .bottom)
    .sheet(
      isPresented: Binding(
        get: { selectedDate.isPresented },
        set: { if !$0 { selectedDate = .none } }
      )
    ) {
      if let date = selectedDate.date {
        NavigationStack {
          CalendarEntryView(calendar: calendar, date: date) { entry in
            store.addEntry(calendarId: calendar.id, entry: entry)
          }
          .background(Color("surface-muted"))
        }
        .background(Color("surface-muted"))
        .presentationDetents([.fraction(0.5)])
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
    let formatter: DateFormatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter.string(from: date)
  }

  var body: some View {
    VStack(spacing: 0) {

      HStack {
        Text("Add Entry")
        .font(.system(size: 32, design: .monospaced))
        .foregroundColor(Color("text-secondary"))
        .fontWeight(.bold)
        Spacer()
        
      }
      .padding(.horizontal)
      .padding(.bottom, 8)
      CustomSeparator()

    Form {
      Section {
        Text(formattedDate)
          .font(.system(size: 12, design: .monospaced))
          .foregroundColor(Color("text-secondary"))
      }.listRowBackground(Color("surface-secondary"))

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
                WidgetCenter.shared.reloadAllTimelines()
              }
            )
          )
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
                WidgetCenter.shared.reloadAllTimelines()
              }
            ), in: 0...99
          )
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
                  WidgetCenter.shared.reloadAllTimelines()
                }
              ), in: 0...99
            )

            ProgressView(value: Double(count), total: Double(calendar.dailyTarget))
              .tint(Color(calendar.color))
          }
        }
      }.listRowBackground(Color("surface-secondary"))
    }
    }
    .font(.system(size: 12, design: .monospaced))
    .foregroundColor(Color("text-secondary"))
    .scrollContentBackground(.hidden)
    .background(Color("surface-muted"))
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

enum CalendarError: LocalizedError {
  case invalidName
  case notificationPermissionDenied
  case notificationSchedulingFailed(Error)
  case errorAddingEntry(Error)

  var errorDescription: String? {
    switch self {
    case .invalidName:
      return "Please enter a valid name (1-50 characters)"
    case .notificationPermissionDenied:
      return "Please enable notifications in Settings to receive reminders."
    case .notificationSchedulingFailed(let error):
      return "Failed to schedule notification: \(error.localizedDescription)"
    case .errorAddingEntry(let error):
      return "Failed to add entry: \(error.localizedDescription)"
    }
  }
}
