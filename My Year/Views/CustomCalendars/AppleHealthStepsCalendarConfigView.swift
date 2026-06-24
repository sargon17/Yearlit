import SharedModels
import SwiftUI
import SwiftfulRouting

struct AppleHealthStepsCalendarConfigView: View {
  let onCreate: (CustomCalendar) -> Void

  @State private var name = "Daily Steps"
  @State private var selectedColor = "qs-amber"
  @State private var dailyTarget = 8000
  @State private var isCreatingCalendar = false
  @State private var calendarError: CalendarError?
  @FocusState private var isNameFocused: Bool
  @Environment(\.router) private var router

  private let healthStepsService = AppleHealthStepsService()

  private var trimmedName: String {
    name.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var targetValidationMessage: LocalizedStringKey? {
    dailyTarget < 1 ? "Step target must be at least 1." : nil
  }

  private var canCreate: Bool {
    !trimmedName.isEmpty && dailyTarget >= 1 && !isCreatingCalendar
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        CustomSeparator()
          .padding(.horizontal, -16)

        CustomSection(label: "Calendar Name") {
          TextField(
            "",
            text: $name,
            prompt: Text("Daily Steps").foregroundColor(.white.opacity(0.2))
          )
          .inputStyle(color: Color(selectedColor))
          .focused($isNameFocused)
        }

        CalendarColorPickerSection(selectedColor: $selectedColor)

        CustomSection(label: "Step Target") {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text("Steps per day")
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
          "Yearlit imports step counts from January 1 through today. "
            + "Days without Apple Health data stay empty."
        )
        .font(.footnote)
        .foregroundStyle(.textTertiary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)

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
    .navigationTitle("Daily Steps")
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
      try await healthStepsService.requestAuthorization()
      let stepCounts = try await healthStepsService.currentYearStepCounts()
      let entries = AppleHealthStepsEntryMapper.entries(from: stepCounts, target: dailyTarget)
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
        unit: .steps,
        defaultRecordValue: nil,
        currencySymbol: nil,
        reminderTimeZone: TimeZone.current.identifier,
        notificationPrivacyMode: .full,
        suppressWhenCompleted: false,
        additionalReminderTimes: [],
        streakProtectionEnabled: false,
        source: .appleHealthSteps
      )
      onCreate(calendar)
      router.dismissEnvironment()
    } catch {
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
