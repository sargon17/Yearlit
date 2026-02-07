import Foundation
import SharedModels
import SwiftUI
import SwiftfulRouting

struct ExistingStreakSheet: View {
  let trackingType: TrackingType
  let dailyTarget: Int
  let defaultDailyValue: Int
  let existingEntries: [String: CalendarEntry]
  let accentColor: Color
  let onApply: ([String: CalendarEntry]) -> Void

  @State private var startDate: Date
  @State private var endDate: Date
  @State private var dailyValue: Int
  @State private var errorMessage: String?
  @State private var pendingEntries: [String: CalendarEntry] = [:]
  @State private var pendingOverwriteCount: Int = 0
  @State private var pendingTotalDays: Int = 0
  @State private var isOverwriteAlertPresented: Bool = false

  @Environment(\.router) private var router
  @Environment(\.colorScheme) private var colorScheme

  init(
    trackingType: TrackingType,
    dailyTarget: Int,
    defaultDailyValue: Int,
    existingEntries: [String: CalendarEntry],
    accentColor: Color,
    onApply: @escaping ([String: CalendarEntry]) -> Void
  ) {
    self.trackingType = trackingType
    self.dailyTarget = dailyTarget
    self.defaultDailyValue = max(1, defaultDailyValue)
    self.existingEntries = existingEntries
    self.accentColor = accentColor
    self.onApply = onApply
    let today = Self.makeLocalCalendar().startOfDay(for: Date())
    _startDate = State(initialValue: today)
    _endDate = State(initialValue: today)
    _dailyValue = State(initialValue: max(1, defaultDailyValue))
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        CustomSeparator()
          .padding(.horizontal, -16)

        CustomSection(label: "Streak Range") {
          VStack(spacing: 2) {
            DatePicker(
              "Start",
              selection: $startDate,
              in: ...Self.makeLocalCalendar().startOfDay(for: Date()),
              displayedComponents: [.date]
            )
            .tint(accentColor)
            .datePickerStyle(.compact)
            .padding(.horizontal)
            .padding(.vertical, 6)
            .sameLevelBorder(isFlat: true)

            DatePicker(
              "End",
              selection: $endDate,
              in: startDate...Self.makeLocalCalendar().startOfDay(for: Date()),
              displayedComponents: [.date]
            )
            .tint(accentColor)
            .datePickerStyle(.compact)
            .padding(.horizontal)
            .padding(.vertical, 6)
            .sameLevelBorder(isFlat: true)
          }
          .padding(.all, 2)
          .background(getVoidColor(colorScheme: colorScheme))
        }

        if trackingType == .counter {
          CustomSection(label: "Daily Value") {
            HStack {
              Text("Value")
                .labelStyle(type: .secondary)
              Spacer()
              TextField("Value", value: $dailyValue, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
                .inputStyle(size: .large, radius: 4, color: accentColor)
            }
            .padding(.leading)
            .padding(.all, 2)
            .sameLevelBorder(isFlat: true)
            .padding(.all, 2)
            .background(getVoidColor(colorScheme: colorScheme))
          }
        }

        if let errorMessage {
          Text(errorMessage)
            .font(.footnote)
            .foregroundStyle(.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
        }

        Spacer(minLength: 0)
      }
      .padding()
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
      .navigationTitle("Existing Streak")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            router.dismissScreen()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Apply") {
            handleApply()
          }
        }
      }
      .alert("Overwrite Entries?", isPresented: $isOverwriteAlertPresented) {
        Button("Cancel", role: .cancel) {}
        Button("Overwrite", role: .destructive) {
          onApply(pendingEntries)
          router.dismissScreen()
        }
      } message: {
        Text("This will overwrite \(pendingOverwriteCount) days within a \(pendingTotalDays)-day range.")
      }
    }
  }

  private func handleApply() {
    errorMessage = nil
    let calendar = Self.makeLocalCalendar()
    let startDay = calendar.startOfDay(for: startDate)
    let endDay = calendar.startOfDay(for: endDate)
    let today = calendar.startOfDay(for: Date())

    if endDay > today {
      errorMessage = "End date must be today or earlier."
      return
    }
    if startDay > endDay {
      errorMessage = "Start date must be on or before the end date."
      return
    }
    if trackingType == .counter, dailyValue <= 0 {
      errorMessage = "Daily value must be greater than zero."
      return
    }

    let result = buildExistingStreakEntries(
      startDate: startDay,
      endDate: endDay,
      trackingType: trackingType,
      dailyTarget: dailyTarget,
      dailyValue: trackingType == .counter ? dailyValue : dailyTarget,
      existingEntries: existingEntries
    )

    if result.overwriteCount > 0 {
      pendingEntries = result.entries
      pendingOverwriteCount = result.overwriteCount
      pendingTotalDays = result.totalDays
      isOverwriteAlertPresented = true
      return
    }

    onApply(result.entries)
    router.dismissScreen()
  }

  private static func makeLocalCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = .autoupdatingCurrent
    return calendar
  }
}
