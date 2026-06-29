import RevenueCat
import SharedModels
import SwiftUI
import SwiftfulRouting

struct CreateManualCalendarView: View {
  @Environment(\.locale) var locale
  let onCreate: (CustomCalendar) -> Void

  @State var customerInfo: CustomerInfo?
  @ObservedObject var store = CustomCalendarStore.shared
  @State var name = ""
  @State var selectedColor = "qs-amber"
  @State var cadence: CalendarCadence = .daily
  @State var trackingType: TrackingType = .binary
  @State var dailyTarget = 2
  @State var selectedUnit: UnitOfMeasure? = Optional.none
  @State var defaultRecordValue: Int = 1
  @State var currencySymbol: String = "$"
  @State var existingStreakEntries: [String: CalendarEntry] = [:]
  @State var trackingStartedAt: Date = LocalDayCalendar.startOfDay(for: Date())
  @State var historyMessage: String?
  @State var notificationSettings = NotificationSettingsDraft.manualDefault(
    reminderWeekday: Calendar.current.component(.weekday, from: Date())
  )
  @State var showingNotificationSettings: Bool = false

  @FocusState var isNameFocused: Bool
  @Environment(\.router) var router

  var isPremiumUser: Bool {
    isPremium(customerInfo: customerInfo)
  }

  var trimmedName: String {
    name.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func userCanCreateCalendar() -> Bool {
    return isPremiumUser || store.snapshot.calendars.count < 3
  }

  var earliestExistingEntryDate: Date? {
    HabitHistoryDateResolver.earliestEntryDate(from: existingStreakEntries, cadence: cadence)
  }

  var usesValueSettings: Bool {
    trackingType == .counter || trackingType == .multipleDaily
  }

  var normalizedDailyTarget: Int {
    max(1, dailyTarget)
  }

  func resolvedTrackingStartedAt() -> Date {
    HabitHistoryDateResolver.resolvedStartDate(
      selectedDate: trackingStartedAt,
      earliestEntryDate: earliestExistingEntryDate,
      cadence: cadence
    )
  }

  var normalizedTrackingStartedAt: Date {
    HabitHistoryDateResolver.normalized(trackingStartedAt, cadence: cadence)
  }

  func applyExistingStreakEntries(_ entries: [String: CalendarEntry]) {
    for (key, entry) in entries {
      existingStreakEntries[key] = entry
    }
    guard let earliestDate = earliestExistingEntryDate,
      earliestDate < normalizedTrackingStartedAt
    else { return }
    trackingStartedAt = earliestDate
    historyMessage = HabitHistoryDateResolver.startMovedMessage(for: earliestDate)
  }

  func clearExistingStreakHistory() {
    existingStreakEntries = [:]
    historyMessage = nil
  }

  var body: some View {
    ScrollView {
      createFormContent
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
    .navigationTitle("New Calendar")
    .navigationBarTitleDisplayMode(.large)
    .toolbar { createToolbar }
    .onAppear {
      isNameFocused = true
    }
    .task {
      await observeCustomerInfo()
    }
    .sheet(isPresented: $showingNotificationSettings) {
      notificationSettingsSheet
    }
    .onChange(of: trackingType) { _, _ in
      clearExistingStreakHistory()
      if trackingType != .multipleDaily {
        notificationSettings.additionalReminderTimes = []
      }
    }
    .onChange(of: dailyTarget) { _, _ in
      if trackingType == .multipleDaily {
        clearExistingStreakHistory()
      }
    }
  }

}

extension CreateManualCalendarView {
  var backfillSummary: String {
    LocalizedCountText.backfilling(existingStreakEntries.count, cadence: cadence, locale: locale)
  }

  @MainActor
  func observeCustomerInfo() async {
    guard RevenueCatClient.isConfigured else { return }

    do {
      customerInfo = try await Purchases.shared.customerInfo()
    } catch {
      NSLog("Failed to fetch customer info: \(error.localizedDescription)")
    }

    for await info in Purchases.shared.customerInfoStream {
      customerInfo = info
      AnalyticsState.shared.updatePremiumStatus(customerInfo: info)
    }
  }
}
