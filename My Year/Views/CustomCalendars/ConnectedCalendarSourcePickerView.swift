import SharedModels
import SwiftUI
import SwiftfulRouting
import UIKit

struct ConnectedCalendarSourcePickerView: View {
  let onCreate: (CustomCalendar) -> Void

  @ObservedObject private var store = CustomCalendarStore.shared
  @State private var selectedMetric: AppleHealthMetric = .steps
  @State private var isLoadingPreview = false
  @State private var calendarError: CalendarError?
  @State private var needsSettings = false
  @Environment(\.router) private var router
  @Environment(\.openURL) private var openURL

  private let healthService = AppleHealthMetricService()

  private var sampleDays: Set<Int> {
    let interval = selectedMetric == .steps ? 3 : 5
    return Set(stride(from: selectedMetric == .steps ? 0 : 2, through: 360, by: interval))
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        CustomSeparator()
          .padding(.horizontal, -16)

        VStack(alignment: .leading, spacing: 10) {
          Text("Your year is already here")
            .font(.headline)
            .foregroundStyle(.textPrimary)

          Text("Choose one signal. Yearlit turns this year's history into completed Periods.")
            .font(.footnote)
            .foregroundStyle(.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)

        CalendarCreationPreview(color: Color(selectedMetric.defaultColor), completedDays: sampleDays)

        CustomSection(label: "Signal") {
          VStack(spacing: 2) {
            ForEach(AppleHealthMetric.allCases) { metric in
              metricButton(metric)
            }
          }
          .padding(2)
          .sameLevelGroupBackground()
        }

        VStack(alignment: .leading, spacing: 8) {
          Text(
            "Yearlit reads only \(selectedMetric.defaultCalendarName.lowercased()). "
              + "It never writes to Apple Health."
          )
          .font(.footnote)
          .foregroundStyle(.textTertiary)

          if needsSettings {
            Button("Open Settings") {
              if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                openURL(settingsURL)
              }
            }
            .primaryActionStyle()

            Button("Create a manual Calendar instead") {
              router.showScreen(.push) { _ in
                CreateManualCalendarView(onCreate: onCreate)
              }
            }
            .primaryActionStyle()
          } else {
            Button {
              Task { await previewYear() }
            } label: {
              HStack {
                Spacer()
                if isLoadingPreview {
                  ProgressView().tint(.textPrimary)
                  Text("Reading \(Calendar.current.component(.year, from: Date()))")
                } else {
                  Text("Preview my year")
                }
                Spacer()
              }
              .fontWeight(.bold)
              .padding()
            }
            .disabled(isLoadingPreview)
            .sameLevelBorder()
            .foregroundStyle(.textSecondary)
          }
        }

        CustomSeparator()
          .padding(.horizontal, -16)
      }
      .padding()
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    .scrollClipDisabled(true)
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .navigationTitle("Apple Health")
    .navigationBarTitleDisplayMode(.inline)
    .alert(item: $calendarError) { error in
      Alert(title: Text(error.title), message: Text(error.message), dismissButton: .default(Text("OK")))
    }
  }

  private func metricButton(_ metric: AppleHealthMetric) -> some View {
    Button {
      selectedMetric = metric
      needsSettings = false
      CalendarAnalyticsTracker.shared.trackAppleHealthMetricSelected(
        metric,
        hasExistingCalendar: hasConnection(for: metric)
      )
    } label: {
      HStack(alignment: .top, spacing: 12) {
        Circle()
          .fill(metric == selectedMetric ? Color(metric.defaultColor) : .textTertiary.opacity(0.35))
          .frame(width: 10, height: 10)
          .padding(.top, 5)

        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text(metric.defaultCalendarName)
              .font(.headline)
              .foregroundStyle(.textPrimary)
            Spacer()
            if metric == .steps {
              Text("BEST PLACE TO START")
                .font(AppFont.mono(8, weight: .medium))
                .foregroundStyle(Color(metric.defaultColor))
            }
          }

          Text(
            "Complete a day at \(metric.defaultTarget.formatted()) "
              + "\(metric.unit.displayName.lowercased())."
          )
          .font(.footnote)
          .foregroundStyle(.textTertiary)

          if hasConnection(for: metric) {
            Text("ALREADY CONNECTED")
              .font(AppFont.mono(9, weight: .medium))
              .foregroundStyle(.textSecondary)
          }
        }
      }
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .sameLevelBorder(isFlat: true)
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(metric == selectedMetric ? .isSelected : [])
  }

  private func hasConnection(for metric: AppleHealthMetric) -> Bool {
    store.snapshot.calendars.contains { $0.source == metric.source }
  }

  @MainActor
  private func previewYear() async {
    guard !isLoadingPreview else { return }
    isLoadingPreview = true
    defer { isLoadingPreview = false }

    do {
      try await healthService.requestAuthorization(for: selectedMetric)
      CalendarAnalyticsTracker.shared.trackAppleHealthPermissionResult(selectedMetric, didGrantAccess: true)
      let values = try await healthService.currentYearValues(for: selectedMetric)
      guard !values.isEmpty else {
        calendarError = .appleHealthSyncFailed(AppleHealthMetricServiceError.noReadableHealthData)
        return
      }
      router.showScreen(.push) { _ in
        AppleHealthMetricCalendarConfigView(
          metric: selectedMetric,
          importedValues: values,
          onCreate: onCreate
        )
      }
    } catch {
      CalendarAnalyticsTracker.shared.trackAppleHealthPermissionResult(selectedMetric, didGrantAccess: false)
      needsSettings = true
      calendarError = .appleHealthSyncFailed(error)
    }
  }
}

extension View {
  fileprivate func primaryActionStyle() -> some View {
    self
      .frame(maxWidth: .infinity)
      .fontWeight(.bold)
      .padding()
      .sameLevelBorder()
      .foregroundStyle(.textSecondary)
  }
}
