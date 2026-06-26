import SharedModels
import SwiftUI
import SwiftfulRouting
import UIKit

struct AppleHealthPermissionView: View {
  let metric: AppleHealthMetric
  let onCreate: (CustomCalendar) -> Void

  @State private var isConnecting = false
  @State private var calendarError: CalendarError?
  @State private var needsSettings = false
  @Environment(\.router) private var router
  @Environment(\.openURL) private var openURL

  private let healthService = AppleHealthMetricService()

  var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        CustomSeparator()
          .padding(.horizontal, -16)

        VStack(alignment: .leading, spacing: 10) {
          Text("Connect Apple Health")
            .font(.headline)
            .foregroundStyle(.textPrimary)

          Text(
            "Yearlit only reads \(metric.defaultCalendarName.lowercased()). "
              + "It does not write to Apple Health."
          )
          .font(.footnote)
          .foregroundStyle(.textTertiary)

          Text("After connecting, Yearlit previews your imported days before creating the Calendar.")
            .font(.footnote)
            .foregroundStyle(.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)

        if needsSettings {
          VStack(spacing: 10) {
            Button("Open Settings") {
              if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                openURL(settingsURL)
              }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .fontWeight(.bold)
            .padding()
            .sameLevelBorder()

            Button("Track myself instead") {
              router.showScreen(.push) { _ in
                CreateManualCalendarView(onCreate: onCreate)
              }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .fontWeight(.bold)
            .padding()
            .sameLevelBorder()
          }
          .foregroundStyle(.textSecondary)
        } else {
          Button {
            Task {
              await connectAppleHealth()
            }
          } label: {
            HStack {
              Spacer()
              if isConnecting {
                ProgressView()
                  .tint(.textPrimary)
              } else {
                Text("Connect Apple Health")
                  .fontWeight(.bold)
              }
              Spacer()
            }
            .padding()
          }
          .disabled(isConnecting)
          .sameLevelBorder()
          .foregroundStyle(.textSecondary)
        }

        CustomSeparator()
          .padding(.horizontal, -16)
      }
      .padding()
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    }
    .scrollClipDisabled(true)
    .scrollDismissesKeyboard(.immediately)
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .navigationTitle("Apple Health")
    .navigationBarTitleDisplayMode(.large)
    .alert(item: $calendarError) { error in
      Alert(
        title: Text(error.title),
        message: Text(error.message),
        dismissButton: .default(Text("OK"))
      )
    }
  }

  @MainActor
  private func connectAppleHealth() async {
    guard !isConnecting else { return }
    isConnecting = true
    defer { isConnecting = false }

    do {
      try await healthService.requestAuthorization(for: metric)
      CalendarAnalyticsTracker.shared.trackAppleHealthPermissionResult(metric, didGrantAccess: true)
      router.showScreen(.push) { _ in
        AppleHealthMetricCalendarConfigView(metric: metric, onCreate: onCreate)
      }
    } catch {
      CalendarAnalyticsTracker.shared.trackAppleHealthPermissionResult(metric, didGrantAccess: false)
      needsSettings = true
      calendarError = .appleHealthSyncFailed(error)
    }
  }
}
