import SharedModels
import SwiftUI
import SwiftfulRouting
import UserNotifications
import WidgetKit

struct DayEntryEditSheet: View {
  @Environment(\.dismiss) private var dismiss
  let calendar: CustomCalendar
  let date: Date
  let store: CustomCalendarStore  // Receive the store
  let onSave: ((CalendarEntry) -> Void)?
  let onDismiss: (() -> Void)?

  @State private var selectedDate: Date
  @State private var entryCount: Int
  @State private var entryCompleted: Bool

  init(
    calendar: CustomCalendar,
    date: Date,
    store: CustomCalendarStore,
    onSave: ((CalendarEntry) -> Void)? = nil,
    onDismiss: (() -> Void)? = nil
  ) {
    self.calendar = calendar
    self.date = date
    self.store = store
    self.onSave = onSave
    self.onDismiss = onDismiss
    // Initialize state based on existing entry or defaults
    let existingEntry = store.getEntry(calendarId: calendar.id, date: date)
    _selectedDate = State(initialValue: Self.bucketDate(for: date, cadence: calendar.cadence))
    _entryCount = State(initialValue: existingEntry?.count ?? 0)
    _entryCompleted = State(initialValue: existingEntry?.completed ?? false)
  }

  private func saveEntry() {
    guard !calendar.isAppleHealthConnected else {
      dismiss()
      return
    }
    let originalDate = Self.bucketDate(for: date, cadence: calendar.cadence)
    let targetDate = Self.bucketDate(for: selectedDate, cadence: calendar.cadence)
    let existingEntry = store.getEntry(calendarId: calendar.id, date: targetDate)
    let newEntry = normalizedEntry()

    if originalDate != targetDate, let originalEntry = store.getEntry(calendarId: calendar.id, date: originalDate) {
      store.deleteEntry(calendarId: calendar.id, date: originalDate)
      CalendarAnalyticsTracker.shared.trackEntryMutation(
        calendar: calendar,
        oldEntry: originalEntry,
        newEntry: nil,
        source: .editSheet
      )
    }

    store.addEntry(calendarId: calendar.id, entry: newEntry)
    CalendarAnalyticsTracker.shared.trackEntryMutation(
      calendar: calendar,
      oldEntry: existingEntry,
      newEntry: newEntry,
      source: .editSheet
    )
    onSave?(newEntry)
    dismiss()
  }

  private func normalizedEntry() -> CalendarEntry {
    let entryDate = Self.bucketDate(for: selectedDate, cadence: calendar.cadence)
    switch calendar.trackingType {
    case .binary:
      return CalendarEntry(date: entryDate, count: entryCompleted ? 1 : 0, completed: entryCompleted)
    case .counter:
      return CalendarEntry(date: entryDate, count: entryCount, completed: entryCount > 0)
    case .multipleDaily:
      return CalendarEntry(date: entryDate, count: entryCount, completed: entryCount >= calendar.dailyTarget)
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      entryEditor

      HStack(alignment: .top, spacing: 12) {
        VerticalDateWheelModule(
          calendar: calendar,
          selectedDate: $selectedDate,
          accentColor: Color(calendar.color)
        )

        if calendar.trackingType != .binary {
          VerticalAmountWheelModule(
            calendar: calendar,
            entryCount: $entryCount,
            accentColor: Color(calendar.color)
          )
        }
      }
      .frame(height: 280)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .navigationBarTitleDisplayMode(.large)
    .onDisappear {
      onDismiss?()
    }
    .onChange(of: selectedDate) { _, newDate in
      fillExistingProgressIfPresent(for: newDate)
    }
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") { saveEntry() }
      }
    }
  }

  @ViewBuilder
  private var entryEditor: some View {
    switch calendar.trackingType {
    case .binary:
      CustomSection(label: "Entry") {
        Toggle(isOn: $entryCompleted) {
          Text("Completed")
            .textDefault()
        }
        .tint(Color(calendar.color))
        .padding(12)
        .sameLevelBorder(radius: 6, isFlat: true)
        .outerSameLevelShadow(radius: 6)
      }
    case .counter, .multipleDaily:
      CustomSection(label: LocalizedStringKey(countLabel)) {
        TextField("", value: $entryCount, formatter: countFormatter)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)
          .inputStyle(color: Color(calendar.color))
          .keyboardType(.numberPad)
      }
    }
  }

  private func fillExistingProgressIfPresent(for date: Date) {
    guard let existingEntry = store.getEntry(calendarId: calendar.id, date: Self.bucketDate(for: date, cadence: calendar.cadence))
    else { return }

    switch calendar.trackingType {
    case .binary:
      guard existingEntry.completed else { return }
      entryCompleted = true
    case .counter, .multipleDaily:
      guard existingEntry.count > 0 else { return }
      entryCount = existingEntry.count
    }
  }

  private var countLabel: String {
    if let unit = calendar.unit, unit != .none {
      if unit == .currency {
        return calendar.currencySymbol ?? "$"
      }
      return unit.displayName
    }
    return String(localized: "Count")
  }

  private static func bucketDate(for date: Date, cadence: CalendarCadence) -> Date {
    switch cadence {
    case .daily:
      return LocalDayCalendar.startOfDay(for: date)
    case .weekly:
      return LocalDayCalendar.startOfWeek(for: date)
    }
  }
}

private var countFormatter: NumberFormatter {
  let formatter = NumberFormatter()
  formatter.numberStyle = .none
  return formatter
}

private struct VerticalDateWheelModule: View {
  let calendar: CustomCalendar
  @Binding var selectedDate: Date
  let accentColor: Color

  private var values: [DateWheelValue] {
    let calendarSystem = LocalDayCalendar.calendar
    let start = bucketDate(for: calendar.trackingStartedAt)
    let today = bucketDate(for: Date())
    let component: Calendar.Component = calendar.cadence == .weekly ? .weekOfYear : .day
    let distance = max(0, calendarSystem.dateComponents([component], from: start, to: today).value(for: component) ?? 0)

    return (0...distance).compactMap { offset in
      guard let date = calendarSystem.date(byAdding: component, value: -offset, to: today) else { return nil }
      return DateWheelValue(offset: offset, date: bucketDate(for: date))
    }
  }

  var body: some View {
    CustomSection(label: calendar.cadence == .weekly ? "Week" : "Day") {
      VerticalTickWheel(
        values: values.map(\.offset),
        selectedID: Binding(
          get: { selectedOffset },
          set: { newValue in
            guard let value = values.first(where: { $0.offset == newValue }) else { return }
            selectedDate = value.date
          }
        ),
        accentColor: accentColor,
        showsSelectionIndicator: false
      ) { offset, isSelected in
        let date = values.first(where: { $0.offset == offset })?.date ?? selectedDate
        Text(relativeLabel(for: date, offset: offset))
          .font(AppFont.mono(isSelected ? 16 : 13, weight: isSelected ? .bold : .regular))
          .foregroundStyle(isSelected ? accentColor : .textSecondary)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity)
      }
      .accessibilityLabel(calendar.cadence == .weekly ? "Selected week" : "Selected day")
      .frame(height: 248)
    }
  }

  private var selectedOffset: Int {
    let selectedBucket = bucketDate(for: selectedDate)
    return values.first(where: { $0.date == selectedBucket })?.offset ?? 0
  }

  private func relativeLabel(for date: Date, offset: Int) -> String {
    if calendar.cadence == .weekly {
      if offset == 0 { return String(localized: "This week") }
      if offset == 1 { return String(localized: "Last week") }
      if offset < 8 { return String(localized: "\(offset) weeks ago") }
      return weekRangeLabel(for: date)
    }

    if offset == 0 { return String(localized: "Today") }
    if offset == 1 { return String(localized: "Yesterday") }
    if offset < 7 { return String(localized: "\(offset) days ago") }
    return shortDateFormatter.string(from: date)
  }

  private func weekRangeLabel(for date: Date) -> String {
    let end = LocalDayCalendar.calendar.date(byAdding: .day, value: 6, to: date) ?? date
    return "\(shortDateFormatter.string(from: date))-\(shortDateFormatter.string(from: end))"
  }

  private func bucketDate(for date: Date) -> Date {
    switch calendar.cadence {
    case .daily:
      return LocalDayCalendar.startOfDay(for: date)
    case .weekly:
      return LocalDayCalendar.startOfWeek(for: date)
    }
  }
}

private struct VerticalAmountWheelModule: View {
  let calendar: CustomCalendar
  @Binding var entryCount: Int
  let accentColor: Color

  @State private var maxValue: Int

  init(calendar: CustomCalendar, entryCount: Binding<Int>, accentColor: Color) {
    self.calendar = calendar
    _entryCount = entryCount
    self.accentColor = accentColor
    let baseMax = max(entryCount.wrappedValue + 200, 200)
    let boostedMax = max(baseMax, calendar.dailyTarget * 5)
    _maxValue = State(initialValue: boostedMax)
  }

  private var values: [Int] {
    Array(0...maxValue)
  }

  var body: some View {
    CustomSection(label: "Amount") {
      VerticalAmountTickWheel(
        value: $entryCount,
        maxValue: $maxValue,
        accentColor: accentColor,
      )
      .accessibilityLabel("Entry amount")
      .frame(height: 248)
    }
  }
}

private struct VerticalAmountTickWheel: View {
  @Binding var value: Int
  @Binding var maxValue: Int
  let accentColor: Color

  @State private var lastHapticValue: Int?
  @State private var selection: Int?

  private let tickSpacing: CGFloat = 10
  private let tickHeight: CGFloat = 2
  private let majorTickWidth: CGFloat = 34
  private let minorTickWidth: CGFloat = 18

  var body: some View {
    GeometryReader { geometry in
      let verticalPadding = max(0, (geometry.size.height - tickHeight) / 2)

      ScrollView(.vertical) {
        LazyVStack(spacing: tickSpacing) {
          ForEach(0...maxValue, id: \.self) { index in
            let isMajor = index % 5 == 0
            RoundedRectangle(cornerRadius: 1)
              .fill(isMajor ? Color.textSecondary : Color.textTertiary)
              .frame(width: isMajor ? majorTickWidth : minorTickWidth, height: tickHeight)
              .frame(maxWidth: .infinity)
              .id(index)
          }
        }
        .scrollTargetLayout()
        .padding(.vertical, verticalPadding)
      }
      .scrollIndicators(.hidden)
      .scrollPosition(id: $selection, anchor: .center)
      .overlay(alignment: .top) {
        LinearGradient(
          colors: [
            Color("surface-muted"),
            Color("surface-muted").opacity(0.85),
            Color("surface-muted").opacity(0)
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: max(24, geometry.size.height * 0.18))
        .allowsHitTesting(false)
      }
      .overlay(alignment: .bottom) {
        LinearGradient(
          colors: [
            Color("surface-muted").opacity(0),
            Color("surface-muted").opacity(0.85),
            Color("surface-muted")
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: max(24, geometry.size.height * 0.18))
        .allowsHitTesting(false)
      }
      .overlay(alignment: .center) {
        RoundedRectangle(cornerRadius: 1)
          .fill(accentColor)
          .frame(height: 2)
          .padding(.horizontal, 14)
      }
      .sameLevelBorder(radius: 6, isFlat: true)
      .outerSameLevelShadow(radius: 6)
      .onChange(of: selection) { _, newValue in
        guard let newValue else { return }
        if value != newValue {
          value = newValue
        }
        if newValue != lastHapticValue {
          lastHapticValue = newValue
          Task {
            await hapticFeedback(.light)
          }
        }
        if newValue >= maxValue - 20 {
          maxValue += 200
        }
      }
      .onChange(of: value) { _, newValue in
        if selection != newValue {
          selection = newValue
        }
      }
      .onAppear {
        selection = value
        lastHapticValue = value
      }
    }
  }
}

private struct VerticalTickWheel<Value: Hashable, Label: View>: View {
  let values: [Value]
  @Binding var selectedID: Value
  let accentColor: Color
  var showsSelectionIndicator: Bool = true
  var onSelected: (Value) -> Void = { _ in }
  @ViewBuilder let label: (Value, Bool) -> Label

  @State private var lastHapticValue: Value?
  @State private var selection: Value?

  private let rowHeight: CGFloat = 44

  var body: some View {
    GeometryReader { geometry in
      let verticalPadding = max(0, (geometry.size.height - rowHeight) / 2)

      ScrollView(.vertical) {
        LazyVStack(spacing: 0) {
          ForEach(values, id: \.self) { value in
            label(value, value == selectedID)
              .frame(height: rowHeight)
              .id(value)
          }
        }
        .scrollTargetLayout()
        .padding(.vertical, verticalPadding)
      }
      .scrollIndicators(.hidden)
      .scrollPosition(id: $selection, anchor: .center)
      .overlay(alignment: .top) {
        LinearGradient(
          colors: [
            Color("surface-muted"),
            Color("surface-muted").opacity(0.85),
            Color("surface-muted").opacity(0)
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: max(24, geometry.size.height * 0.18))
        .allowsHitTesting(false)
      }
      .overlay(alignment: .bottom) {
        LinearGradient(
          colors: [
            Color("surface-muted").opacity(0),
            Color("surface-muted").opacity(0.85),
            Color("surface-muted")
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: max(24, geometry.size.height * 0.18))
        .allowsHitTesting(false)
      }
      .overlay(alignment: .center) {
        if showsSelectionIndicator {
          RoundedRectangle(cornerRadius: 1)
            .fill(accentColor)
            .frame(height: 2)
            .padding(.horizontal, 14)
        }
      }
      .sameLevelBorder(radius: 6, isFlat: true)
      .outerSameLevelShadow(radius: 6)
      .onChange(of: selection) { _, newValue in
        guard let newValue else { return }
        if selectedID != newValue {
          selectedID = newValue
        }
        onSelected(newValue)
        if newValue != lastHapticValue {
          lastHapticValue = newValue
          Task {
            await hapticFeedback(.light)
          }
        }
      }
      .onChange(of: selectedID) { _, newValue in
        if selection != newValue {
          selection = newValue
        }
      }
      .onAppear {
        selection = selectedID
        lastHapticValue = selectedID
      }
    }
  }
}

private struct DateWheelValue: Hashable {
  let offset: Int
  let date: Date
}

private let shortDateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.setLocalizedDateFormatFromTemplate("MMM d")
  return formatter
}()
