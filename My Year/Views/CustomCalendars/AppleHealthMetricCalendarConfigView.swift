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
  @State private var isLoadingPreview = false
  @State private var importedValues: [Date: Int]?
  @State private var calendarError: CalendarError?
  @State private var needsSettings = false
  @FocusState private var isNameFocused: Bool
  @Environment(\.router) private var router

  private let healthService = AppleHealthMetricService()

  init(metric: AppleHealthMetric, onCreate: @escaping (CustomCalendar) -> Void) {
    self.metric = metric
    self.onCreate = onCreate
    _name = State(initialValue: metric.defaultCalendarName)
    _selectedColor = State(initialValue: metric.defaultColor)
    _dailyTarget = State(initialValue: metric.defaultTarget)
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
      && !isLoadingPreview
      && previewValues?.isEmpty == false
  }

  private var previewValues: [Date: Int]? {
    importedValues
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

        AppleHealthImportPreviewSection(
          metric: metric,
          selectedColor: Color(selectedColor),
          dailyTarget: $dailyTarget,
          previewValues: previewValues,
          isLoadingPreview: isLoadingPreview,
          needsSettings: needsSettings,
          onRetry: {
            Task {
              await loadImportPreview()
            }
          }
        )

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
        Button("Create & Import") {
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
    .task {
      await loadImportPreview()
    }
    .alert(item: $calendarError) { error in
      Alert(
        title: Text(error.title),
        message: Text(error.message),
        dismissButton: .default(Text("OK"))
      )
    }
  }

  @MainActor
  private func createAppleHealthCalendar() async {
    guard canCreate else { return }
    isCreatingCalendar = true
    defer { isCreatingCalendar = false }

    do {
      try await healthService.requestAuthorization(for: metric)
      let values: [Date: Int]
      if let previewValues {
        values = previewValues
      } else {
        values = try await healthService.currentYearValues(for: metric)
      }
      guard !values.isEmpty else {
        calendarError = .appleHealthSyncFailed(AppleHealthMetricServiceError.noReadableHealthData)
        return
      }
      let entries = AppleHealthMetricEntryMapper.entries(from: values, target: dailyTarget)
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
        importedDays: values.count,
        completedDays: entries.values.filter(\.completed).count
      )
      router.dismissEnvironment()
    } catch {
      needsSettings = true
      calendarError = .appleHealthSyncFailed(error)
    }
  }

  @MainActor
  private func loadImportPreview() async {
    guard !isLoadingPreview else { return }
    isLoadingPreview = true
    defer { isLoadingPreview = false }

    do {
      try await healthService.requestAuthorization(for: metric)
      CalendarAnalyticsTracker.shared.trackAppleHealthPermissionResult(metric, didGrantAccess: true)
      let values = try await healthService.currentYearValues(for: metric)
      importedValues = values
      CalendarAnalyticsTracker.shared.trackAppleHealthImportPreviewLoaded(
        metric: metric,
        importedDays: values.count,
        completedDays: AppleHealthMetricEntryMapper.entries(from: values, target: dailyTarget)
          .values
          .filter(\.completed)
          .count,
        target: dailyTarget
      )
    } catch {
      CalendarAnalyticsTracker.shared.trackAppleHealthPermissionResult(metric, didGrantAccess: false)
      needsSettings = true
      calendarError = .appleHealthSyncFailed(error)
    }
  }

  private static func currentYearStartDate() -> Date {
    let calendar = LocalDayCalendar.calendar
    let year = calendar.component(.year, from: Date())
    return calendar.date(from: DateComponents(year: year, month: 1, day: 1))
      ?? LocalDayCalendar.startOfDay(for: Date())
  }
}
