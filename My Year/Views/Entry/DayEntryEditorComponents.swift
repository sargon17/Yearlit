import SharedModels
import SwiftUI

struct CheckInDeviceScreen<Content: View, Actions: View>: View {
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

struct ScreenControlLabel: View {
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

struct DeviceActionButton: View {
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

struct VerticalDateWheelModule: View {
  let calendar: CustomCalendar
  @Binding var selectedDate: Date
  let accentColor: Color

  private var dateWheelValues: [DateWheelValue] {
    let calendarSystem = LocalDayCalendar.calendar
    let trackingStart = bucketDate(for: calendar.trackingStartedAt)
    let selectedStart = bucketDate(for: selectedDate)
    let start = min(trackingStart, selectedStart)
    let today = bucketDate(for: Date())
    let component: Calendar.Component = calendar.cadence == .weekly ? .weekOfYear : .day
    let distance = max(
      0,
      calendarSystem.dateComponents([component], from: start, to: today).value(for: component) ?? 0
    )

    return (0...distance).compactMap { offset in
      guard let date = calendarSystem.date(byAdding: component, value: -offset, to: today) else { return nil }
      return DateWheelValue(offset: offset, date: bucketDate(for: date))
    }
  }

  var body: some View {
    let values = dateWheelValues

    VStack(alignment: .leading, spacing: 10) {
      ScreenControlLabel(label: calendar.cadence == .weekly ? "Week" : "Day")

      CenterTrackedDateWheel(
        offsets: values.map(\.offset),
        selectedOffset: Binding(
          get: { offset(for: selectedDate, in: values) },
          set: { updateSelection(to: $0, in: values) }
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

  private func offset(for date: Date, in values: [DateWheelValue]) -> Int {
    let selectedBucket = bucketDate(for: date)
    return values.first(where: { $0.date == selectedBucket })?.offset ?? 0
  }

  private func updateSelection(to selectedOffset: Int, in values: [DateWheelValue]) {
    guard offset(for: selectedDate, in: values) != selectedOffset else { return }
    guard let value = values.first(where: { $0.offset == selectedOffset }) else {
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

struct VerticalAmountWheelModule: View {
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
        accentColor: accentColor
      )
      .accessibilityLabel("Entry amount")
      .frame(height: 218)
    }
    .padding(12)
    .frame(maxWidth: .infinity)
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
