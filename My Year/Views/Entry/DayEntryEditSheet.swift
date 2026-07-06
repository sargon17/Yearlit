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
  @State private var presentedDate: Date
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
    let bucketedDate = Self.bucketDate(for: date, cadence: calendar.cadence)
    let existingEntry = store.getEntry(calendarId: calendar.id, date: bucketedDate)
    _selectedDate = State(initialValue: bucketedDate)
    _presentedDate = State(initialValue: bucketedDate)
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
    let newEntry = normalizedEntry(date: targetDate)
    let originalEntry = store.getEntry(calendarId: calendar.id, date: originalDate)

    guard store.saveEntry(calendarId: calendar.id, entry: newEntry, replacingDate: originalDate) else {
      return
    }

    if originalDate != targetDate, let originalEntry {
      CalendarAnalyticsTracker.shared.trackEntryMutation(
        calendar: calendar,
        oldEntry: originalEntry,
        newEntry: nil,
        source: .editSheet
      )
    }

    CalendarAnalyticsTracker.shared.trackEntryMutation(
      calendar: calendar,
      oldEntry: existingEntry,
      newEntry: newEntry,
      source: .editSheet
    )
    onSave?(newEntry)
    dismiss()
  }

  private func normalizedEntry(date entryDate: Date) -> CalendarEntry {
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
    CheckInDeviceScreen {
      entryEditor

      Rectangle()
        .fill(Color.textTertiary.opacity(0.35))
        .frame(height: 1)

      HStack(alignment: .top, spacing: 0) {
        VerticalDateWheelModule(
          calendar: calendar,
          selectedDate: $selectedDate,
          accentColor: Color(calendar.color)
        )

        if calendar.trackingType != .binary {
          Rectangle()
            .fill(Color.textTertiary.opacity(0.35))
            .frame(width: 1)
            .padding(.vertical, 12)

          VerticalAmountWheelModule(
            calendar: calendar,
            entryCount: $entryCount,
            accentColor: Color(calendar.color),
            label: compactCountLabel
          )
        }
      }
      .frame(height: 250)
    } actions: {
      HStack(spacing: 10) {
        DeviceActionButton(title: "Cancel", action: { dismiss() })
        DeviceActionButton(
          title: "Save",
          accentColor: Color(calendar.color),
          labelColor: .brandInverted,
          action: saveEntry
        )
      }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .navigationBarTitleDisplayMode(.large)
    .onAppear {
      syncPresentedDate(date)
    }
    .onChange(of: date) { _, newDate in
      syncPresentedDate(newDate)
    }
    .onDisappear {
      onDismiss?()
    }
    .onChange(of: selectedDate) { _, newDate in
      fillExistingProgressIfPresent(for: newDate)
    }
  }

  private func syncPresentedDate(_ date: Date) {
    let bucketedDate = Self.bucketDate(for: date, cadence: calendar.cadence)
    guard bucketedDate != presentedDate else { return }
    presentedDate = bucketedDate
    selectedDate = bucketedDate
    fillExistingProgressIfPresent(for: bucketedDate)
  }

  @ViewBuilder
  private var entryEditor: some View {
    switch calendar.trackingType {
    case .binary:
      VStack(alignment: .leading, spacing: 10) {
        screenLabel("Entry")
        Toggle(isOn: $entryCompleted) {
          Text("Completed")
            .textDefault()
        }
        .tint(Color(calendar.color))
      }
      .padding(14)
    case .counter, .multipleDaily:
      VStack(alignment: .leading, spacing: 8) {
        screenLabel(LocalizedStringKey(countLabel))
        TextField("", value: $entryCount, formatter: countFormatter)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)
          .font(AppFont.pixelCircle(72))
          .foregroundStyle(Color(calendar.color))
          .textFieldStyle(.plain)
          .keyboardType(.numberPad)
          .contentTransition(.numericText())
      }
      .padding(.horizontal, 14)
      .padding(.top, 12)
      .padding(.bottom, 14)
    }
  }

  private func screenLabel(_ label: LocalizedStringKey) -> some View {
    Text(label)
      .font(AppFont.mono(10, weight: .bold))
      .foregroundStyle(.textTertiary)
      .textCase(.uppercase)
      .tracking(1.2)
  }

  private func fillExistingProgressIfPresent(for date: Date) {
    guard
      let existingEntry = store.getEntry(
        calendarId: calendar.id, date: Self.bucketDate(for: date, cadence: calendar.cadence))
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

  private var compactCountLabel: String {
    guard let unit = calendar.unit, unit != .none else {
      return String(localized: "Count")
    }
    return unit == .currency ? (calendar.currencySymbol ?? "$") : unit.rawValue
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

private struct CheckInDeviceScreen<Content: View, Actions: View>: View {
  @ViewBuilder let content: () -> Content
  @ViewBuilder let actions: () -> Actions

  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 0) {
        content()
      }
      .lcdScreenEffect(
        clipShape: UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12)
      )

      Rectangle()
        .fill(Color.textTertiary.opacity(0.35))
        .frame(height: 1)

      actions()
        .padding(12)
    }
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(
          LinearGradient(
            colors: [
              Color.black.opacity(0.98),
              Color.black.opacity(0.95),
              Color.black.opacity(0.9)
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
    )
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .overlay {
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.white.opacity(0.16), lineWidth: 1)
        .padding(1)
    }
    .overlay {
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.black.opacity(0.85), lineWidth: 2)
    }
    .overlay(alignment: .topLeading) {
      LinearGradient(
        colors: [
          Color.white.opacity(0.12),
          Color.white.opacity(0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .allowsHitTesting(false)
    }
    .shadow(color: .black.opacity(0.38), radius: 14, x: 0, y: 8)
  }
}

private struct ScreenControlLabel: View {
  let label: LocalizedStringKey

  var body: some View {
    Text(label)
      .font(AppFont.mono(10, weight: .bold))
      .foregroundStyle(.textTertiary)
      .textCase(.uppercase)
      .tracking(1.2)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct DeviceActionButton: View {
  let title: LocalizedStringKey
  var accentColor: Color = .surfaceMuted
  var labelColor: Color = .textSecondary
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(AppFont.mono(12, weight: .bold))
        .textCase(.uppercase)
        .tracking(1)
        .foregroundStyle(labelColor)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .sameLevelBorder(radius: 4, color: accentColor)
    }
    .buttonStyle(.plain)
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
    VStack(alignment: .leading, spacing: 10) {
      ScreenControlLabel(label: calendar.cadence == .weekly ? "Week" : "Day")

      CenterTrackedDateWheel(
        offsets: values.map(\.offset),
        selectedOffset: Binding(
          get: { offset(for: selectedDate) },
          set: { updateSelection(to: $0) }
        ),
        accentColor: accentColor,
        label: { offset in
          let date = values.first(where: { $0.offset == offset })?.date ?? selectedDate
          return relativeLabel(for: date, offset: offset)
        }
      )
      .accessibilityLabel(calendar.cadence == .weekly ? "Selected week" : "Selected day")
      .frame(height: 218)
    }
    .padding(12)
    .frame(maxWidth: .infinity)
  }

  private func offset(for date: Date) -> Int {
    let selectedBucket = bucketDate(for: date)
    return values.first(where: { $0.date == selectedBucket })?.offset ?? 0
  }

  private func updateSelection(to offset: Int) {
    guard self.offset(for: selectedDate) != offset else { return }
    guard let value = values.first(where: { $0.offset == offset }) else {
      return
    }
    selectedDate = value.date
  }

  private func relativeLabel(for date: Date, offset: Int) -> String {
    if calendar.cadence == .weekly {
      if offset == 0 { return String(localized: "This week") }
      if offset == 1 { return String(localized: "Last week") }
      return weekRangeLabel(for: date)
    }

    if offset == 0 { return String(localized: "Today") }
    if offset == 1 { return String(localized: "Yesterday") }
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

private struct CenterTrackedDateWheel: View {
  let offsets: [Int]
  @Binding var selectedOffset: Int
  let accentColor: Color
  let label: (Int) -> String

  @State private var lastHapticOffset: Int?
  @State private var selection: Int?

  private let rowHeight: CGFloat = 44

  var body: some View {
    GeometryReader { geometry in
      let verticalPadding = max(0, (geometry.size.height - rowHeight) / 2)

      ScrollView(.vertical) {
        LazyVStack(spacing: 0) {
          ForEach(offsets, id: \.self) { offset in
            Text(label(offset))
              .font(AppFont.mono(18, weight: .bold))
              .foregroundStyle(offset == selectedOffset ? accentColor : .textSecondary)
              .lineLimit(1)
              .minimumScaleFactor(0.7)
              .frame(maxWidth: .infinity)
              .frame(height: rowHeight)
              .id(offset)
              .scrollTransition(.interactive, axis: .vertical) { content, phase in
                content
                  .opacity(phase.isIdentity ? 1 : 0.48)
                  .rotation3DEffect(
                    .degrees(Double(phase.value) * -28),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.55
                  )
              }
          }
        }
        .scrollTargetLayout()
        .padding(.vertical, verticalPadding)
      }
      .scrollIndicators(.hidden)
      .scrollPosition(id: $selection, anchor: .center)
      .scrollTargetBehavior(.viewAligned)
      .mask { WheelFadeMask() }
      .onChange(of: selection) { _, newValue in
        guard let newValue else { return }
        if selectedOffset != newValue {
          selectedOffset = newValue
        }
        if newValue != lastHapticOffset {
          lastHapticOffset = newValue
          Task {
            await hapticFeedback(.light)
          }
        }
      }
      .onChange(of: selectedOffset) { _, newValue in
        if selection != newValue {
          selection = newValue
        }
      }
      .onAppear {
        selection = selectedOffset
        lastHapticOffset = selectedOffset
      }
    }
  }
}

private struct VerticalAmountWheelModule: View {
  let calendar: CustomCalendar
  @Binding var entryCount: Int
  let accentColor: Color
  let label: String

  @State private var maxValue: Int

  init(calendar: CustomCalendar, entryCount: Binding<Int>, accentColor: Color, label: String) {
    self.calendar = calendar
    _entryCount = entryCount
    self.accentColor = accentColor
    self.label = label
    let baseMax = max(entryCount.wrappedValue + 200, 200)
    let boostedMax = max(baseMax, calendar.dailyTarget * 5)
    _maxValue = State(initialValue: boostedMax)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ScreenControlLabel(label: LocalizedStringKey(label))

      VerticalAmountTickWheel(
        value: $entryCount,
        maxValue: $maxValue,
        accentColor: accentColor,
      )
      .accessibilityLabel("Entry amount")
      .frame(height: 218)
    }
    .padding(12)
    .frame(maxWidth: .infinity)
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
      .scrollTargetBehavior(.viewAligned)
      .mask { WheelFadeMask() }
      .overlay(alignment: .center) {
        RoundedRectangle(cornerRadius: 1)
          .fill(accentColor)
          .frame(height: 2)
          .padding(.horizontal, 14)
      }
      .onChange(of: selection) { _, newValue in
        guard let newValue else { return }
        if value != newValue {
          value = newValue
        }
        if newValue != lastHapticValue {
          lastHapticValue = newValue
          Task {
            await hapticFeedback(newValue % 5 == 0 ? .light : .soft)
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
        selection = nil
        lastHapticValue = value
        Task { @MainActor in
          selection = value
        }
      }
    }
  }
}

private struct WheelFadeMask: View {
  var body: some View {
    LinearGradient(
      stops: [
        .init(color: .clear, location: 0),
        .init(color: .black, location: 0.18),
        .init(color: .black, location: 0.82),
        .init(color: .clear, location: 1)
      ],
      startPoint: .top,
      endPoint: .bottom
    )
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
