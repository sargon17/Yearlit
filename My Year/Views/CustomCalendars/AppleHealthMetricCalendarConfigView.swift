import SharedModels
import SwiftUI
import SwiftfulRouting

struct AppleHealthMetricCalendarConfigView: View {
  let metric: AppleHealthMetric
  let onCreate: (CustomCalendar) -> Void

  @State private var name: String
  @State private var selectedColor: String
  @State private var dailyTarget: Int
  @State private var isCreatingCalendar = false
  @State private var importedValues: [Date: Int]
  @FocusState private var isNameFocused: Bool
  @Environment(\.router) private var router

  init(
    metric: AppleHealthMetric,
    importedValues: [Date: Int],
    onCreate: @escaping (CustomCalendar) -> Void
  ) {
    self.metric = metric
    self.onCreate = onCreate
    _name = State(initialValue: metric.defaultCalendarName)
    _selectedColor = State(initialValue: metric.defaultColor)
    _dailyTarget = State(initialValue: metric.defaultTarget)
    _importedValues = State(initialValue: importedValues)
  }

  private var trimmedName: String {
    name.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var targetValidationMessage: LocalizedStringKey? {
    dailyTarget < 1 ? "Target must be at least 1." : nil
  }

  private var canCreate: Bool {
    !trimmedName.isEmpty
      && dailyTarget >= 1
      && !isCreatingCalendar
      && !importedValues.isEmpty
  }

  private var previewEntries: [String: CalendarEntry] {
    AppleHealthMetricEntryMapper.entries(from: importedValues, target: dailyTarget)
  }

  private var importedDayCount: Int {
    importedValues.count
  }

  private var completedDayCount: Int {
    previewEntries.values.filter(\.completed).count
  }

  private var completedDayIndices: Set<Int> {
    let calendar = LocalDayCalendar.calendar
    return Set(
      importedValues.compactMap { date, value in
        guard value >= dailyTarget else { return nil }
        return calendar.ordinality(of: .day, in: .year, for: date).map { $0 - 1 }
      })
  }

  private var averageValue: Int? {
    let values = importedValues.values
    guard !values.isEmpty else { return nil }
    return Int((Double(values.reduce(0, +)) / Double(values.count)).rounded())
  }

  private var targetSuggestions: [Int] {
    var suggestions = [metric.defaultTarget]
    if let averageValue, averageValue > 0 {
      suggestions.append(averageValue)
    }
    return Array(Set(suggestions))
      .filter { $0 > 0 }
      .sorted()
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        CustomSeparator()
          .padding(.horizontal, -16)

        CalendarIdentityLCDSection(
          name: $name,
          selectedColor: $selectedColor,
          prompt: metric.defaultCalendarName,
          isNameFocused: $isNameFocused
        )

        CustomSection(label: "Daily Target") {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text(metric.targetLabel)
                .labelStyle(type: .secondary)

              Spacer()

              TextField("Target", value: $dailyTarget, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
                .inputStyle(size: .large, radius: 4, color: Color(selectedColor))
            }
            .padding(.leading)
            .padding(.all, 2)
            .sameLevelBorder(isFlat: true)

            if let targetValidationMessage {
              Text(targetValidationMessage)
                .font(.footnote)
                .foregroundStyle(.moodTerrible)
                .padding(.horizontal, 8)
            }
          }
          .padding(.all, 2)
          .sameLevelGroupBackground()
        }

        Text(
          "Yearlit imports \(metric.defaultCalendarName.lowercased()) from January 1 through today. "
            + "Your target decides which imported days become completed."
        )
        .font(.footnote)
        .foregroundStyle(.textTertiary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)

        CalendarCreationPreview(color: Color(selectedColor), completedDays: completedDayIndices)

        Text(
          "\(completedDayCount) days reached \(dailyTarget.formatted()) "
            + "\(metric.unit.displayName.lowercased())."
        )
        .font(AppFont.mono(11, weight: .medium))
        .foregroundStyle(.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)

        importPreviewSection

        CustomSeparator()
          .padding(.horizontal, -16)
      }
      .padding()
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    }
    .accentColor(Color(selectedColor))
    .scrollClipDisabled(true)
    .scrollDismissesKeyboard(.immediately)
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .navigationTitle(metric.defaultCalendarName)
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Add this Calendar") {
          Task {
            await createAppleHealthCalendar()
          }
        }
        .disabled(!canCreate)
      }
    }
    .onAppear {
      isNameFocused = true
    }
  }

  @MainActor
  private func createAppleHealthCalendar() async {
    guard canCreate else { return }
    isCreatingCalendar = true
    defer { isCreatingCalendar = false }

    let entries = AppleHealthMetricEntryMapper.entries(from: importedValues, target: dailyTarget)
    let calendar = CustomCalendar(
      name: trimmedName,
      color: selectedColor,
      cadence: .daily,
      trackingType: .binary,
      trackingStartedAt: Self.currentYearStartDate(),
      dailyTarget: dailyTarget,
      entries: entries,
      isArchived: false,
      recurringReminderEnabled: false,
      unit: metric.unit,
      defaultRecordValue: nil,
      currencySymbol: nil,
      reminderTimeZone: TimeZone.current.identifier,
      notificationPrivacyMode: .full,
      suppressWhenCompleted: false,
      additionalReminderTimes: [],
      streakProtectionEnabled: false,
      source: metric.source
    )
    onCreate(calendar)
    CalendarAnalyticsTracker.shared.trackAppleHealthCalendarCreated(
      calendar: calendar,
      metric: metric,
      importedDays: importedValues.count,
      completedDays: entries.values.filter(\.completed).count
    )
    router.dismissEnvironment()
  }

  @ViewBuilder
  private var importPreviewSection: some View {
    CustomSection(label: "Import Preview") {
      VStack(spacing: 2) {
        previewRow(title: "Imported days", value: importedDayCount.formatted(.number))
        previewRow(title: "Completed at target", value: completedDayCount.formatted(.number))
        if let averageValue {
          previewRow(title: "Average imported day", value: averageValue.formatted(.number))
        }

        if targetSuggestions.count > 1 {
          VStack(alignment: .leading, spacing: 8) {
            Text("Target suggestions")
              .labelStyle(type: .secondary)

            HStack(spacing: 8) {
              ForEach(targetSuggestions, id: \.self) { target in
                Button {
                  dailyTarget = target
                } label: {
                  Text(target.formatted(.number))
                    .font(.footnote.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(minWidth: 64)
                }
                .sameLevelBorder(isFlat: true)
                .foregroundStyle(target == dailyTarget ? Color(selectedColor) : .textSecondary)
              }
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding()
          .sameLevelBorder(isFlat: true)
        }
      }
      .padding(.all, 2)
      .sameLevelGroupBackground()
    }
  }

  private func previewRow(title: LocalizedStringKey, value: String) -> some View {
    HStack {
      Text(title)
        .labelStyle(type: .secondary)
      Spacer()
      Text(value)
        .fontWeight(.bold)
        .foregroundStyle(.textPrimary)
    }
    .padding()
    .sameLevelBorder(isFlat: true)
  }

  private static func currentYearStartDate() -> Date {
    let calendar = LocalDayCalendar.calendar
    let year = calendar.component(.year, from: Date())
    return calendar.date(from: DateComponents(year: year, month: 1, day: 1))
      ?? LocalDayCalendar.startOfDay(for: Date())
  }
}
