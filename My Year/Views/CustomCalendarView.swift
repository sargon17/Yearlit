import SharedModels
import SwiftUI
import UserNotifications
import WidgetKit

enum SelectedDate: Equatable, Identifiable {
  case none
  case selected(Date)

  var id: Date? {
    switch self {
    case .none:
      return nil
    case .selected(let date):
      return date
    }
  }

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
  @AppStorage("wandFillForce") private var wandFillForce: Double = 0.5

  private let today = Date()

  @State private var selectedDate: SelectedDate? = nil
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
    store.clearEntries(calendarId: self.calendar.id)

    let calendar = Calendar.current
    let startOfYear = calendar.date(
      from: DateComponents(year: valuationStore.selectedYear, month: 1, day: 1))!

    for day in 0..<valuationStore.currentDayNumber {
      let date = calendar.date(byAdding: .day, value: day, to: startOfYear)!

      if date <= today && Double.random(in: 0.0...1.0) < wandFillForce {
        switch self.calendar.trackingType {
        case .binary:
          let entry = CalendarEntry(date: date, count: 1, completed: true)
          store.addEntry(calendarId: self.calendar.id, entry: entry)
        case .counter:
          let count = Int.random(in: 1...5)
          let entry = CalendarEntry(date: date, count: count, completed: count > 0)
          store.addEntry(calendarId: self.calendar.id, entry: entry)
        case .multipleDaily:
          let count = Int.random(in: 1...self.calendar.dailyTarget)
          let entry = CalendarEntry(
            date: date, count: count, completed: count >= self.calendar.dailyTarget)
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
    } else {
      selectedDate = nil
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
    return CalendarStats(
      activeDays: activeDays, totalCount: totalCount, maxCount: maxCount,
      longestStreak: longestStreak, currentStreak: currentStreak)
  }

  private func handleQuickAdd() {
    // Get the date for the previous day (today is not yet available)
    let today = valuationStore.dateForDay(valuationStore.currentDayNumber - 1)
    var newEntry = CalendarEntry(date: today, count: 1, completed: true)  // Default entry

    // Check if an entry already exists for today
    if let existingEntry = store.getEntry(calendarId: calendar.id, date: today) {
      // If the tracking type is counter or multipleDaily, increment the count by the defaultRecordValue
      if calendar.trackingType == .counter || calendar.trackingType == .multipleDaily {
        let addValue = calendar.defaultRecordValue ?? 1  // Use defaultRecordValue or 1 if nil
        newEntry = CalendarEntry(
          date: today,
          count: existingEntry.count + addValue,
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
    } else {
      // If no entry exists, create a new one using defaultRecordValue for count
      if calendar.trackingType == .counter || calendar.trackingType == .multipleDaily {
        let addValue = calendar.defaultRecordValue ?? 1  // Use defaultRecordValue or 1 if nil
        newEntry = CalendarEntry(date: today, count: addValue, completed: addValue > 0)
      } else {  // Binary remains count 1, completed true
        newEntry = CalendarEntry(date: today, count: 1, completed: true)
      }
    }
    store.addEntry(calendarId: calendar.id, entry: newEntry)
    WidgetCenter.shared.reloadAllTimelines()

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

      // Calculate today's count
      let todayDateString = customDateFormatter(date: today)
      let todaysLogCount = calendar.entries[todayDateString]?.count ?? 0

      CalendarStatisticsView(
        stats: getStats(),
        accentColor: Color(calendar.color),
        todaysCount: todaysLogCount,  // Pass today's count
        unit: calendar.unit,  // Pass the unit
        currencySymbol: calendar.currencySymbol  // Pass the currency symbol
      )
      .padding(.top, 20)

      CustomSeparator()

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
      .sheet(item: $selectedDate) { selected in
        // Ensure selected.date is non-nil before proceeding
        if let date = selected.date {
          DayEntryEditSheet(
            calendar: calendar,
            date: date,
            store: store  // Pass the store
          )
        } else {
          // Optional: Provide a fallback view or handle the nil case appropriately
          Text("Error: No date selected.")
        }
      }
      .alert(item: $calendarError) { error in
        Alert(
          title: Text(error.title), message: Text(error.message),
          dismissButton: .default(Text("OK")))
      }
  }
}

// MARK: - Day Entry Edit Sheet View

struct DayEntryEditSheet: View {
  @Environment(\.dismiss) private var dismiss
  let calendar: CustomCalendar
  let date: Date
  let store: CustomCalendarStore  // Receive the store

  @State private var entryCount: Int
  @State private var entryCompleted: Bool

  init(calendar: CustomCalendar, date: Date, store: CustomCalendarStore) {
    self.calendar = calendar
    self.date = date
    self.store = store
    // Initialize state based on existing entry or defaults
    let existingEntry = store.getEntry(calendarId: calendar.id, date: date)
    _entryCount = State(initialValue: existingEntry?.count ?? 0)
    _entryCompleted = State(initialValue: existingEntry?.completed ?? false)
  }

  private func saveEntry() {
    let newEntry = CalendarEntry(date: date, count: entryCount, completed: entryCompleted)
    store.addEntry(calendarId: calendar.id, entry: newEntry)
    WidgetCenter.shared.reloadAllTimelines()
    dismiss()
  }

  var body: some View {
    NavigationView {  // Wrap in NavigationView for title and buttons
      Form {
        Section {
          if calendar.trackingType == .binary {
            Toggle("Completed", isOn: $entryCompleted)
          } else {
            HStack {
              Text(
                "Count"
                  + (calendar.unit != nil
                    ? " (\(calendar.unit == .currency ? (calendar.currencySymbol ?? "$") : calendar.unit!.rawValue))"
                    : ""))
              Spacer()
              TextField("Value", value: $entryCount, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
                .onChange(of: entryCount) { newValue in
                  // Automatically mark as completed if count > 0 for counter/multiple
                  if calendar.trackingType == .counter || calendar.trackingType == .multipleDaily {
                    entryCompleted = newValue > 0
                  }
                }
            }
          }
        }
        .listRowBackground(Color("surface-secondary"))
      }
      // Format the date to a String for the navigation title
      .navigationTitle(dateFormatterLong.string(from: date))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") { saveEntry() }
        }
      }
      .background(Color("surface-muted").ignoresSafeArea())
      .scrollContentBackground(.hidden)
    }
    .presentationDetents([.medium])
  }
}

private let dateFormatterLong: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateStyle = .long
  formatter.timeStyle = .none
  return formatter
}()

enum CalendarError: LocalizedError, Identifiable {
  case invalidName
  case notificationPermissionDenied
  case notificationSchedulingFailed(Error)
  case errorAddingEntry(Error)

  var id: String { self.localizedDescription }

  var title: String {
    switch self {
    case .invalidName:
      return "Invalid Name"
    case .notificationPermissionDenied:
      return "Notification Permission Denied"
    case .notificationSchedulingFailed:
      return "Notification Error"
    case .errorAddingEntry:
      return "Entry Error"
    }
  }

  var message: String {
    errorDescription ?? "An unknown error occurred."
  }

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
