import SharedModels
import SwiftUI
import SwiftfulRouting

struct ConnectedCalendarSourcePickerView: View {
  let onCreate: (CustomCalendar) -> Void

  @ObservedObject private var store = CustomCalendarStore.shared
  @Environment(\.router) private var router

  private func hasConnection(for metric: AppleHealthMetric) -> Bool {
    store.snapshot.calendars.contains { $0.source == metric.source }
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        CustomSeparator()
          .padding(.horizontal, -16)

        VStack(alignment: .leading, spacing: 10) {
          Text("Choose an Apple Health metric")
            .font(.headline)
            .foregroundStyle(.textPrimary)

          Text("Yearlit reads these metrics from Apple Health and turns them into Check-ins.")
            .font(.footnote)
            .foregroundStyle(.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)

        ForEach(AppleHealthMetric.allCases) { metric in
          Button {
            let hasExistingCalendar = hasConnection(for: metric)
            CalendarAnalyticsTracker.shared.trackAppleHealthMetricSelected(
              metric,
              hasExistingCalendar: hasExistingCalendar
            )
            if hasExistingCalendar {
              router.showScreen(.push) { _ in
                AppleHealthMetricCalendarConfigView(metric: metric, onCreate: onCreate)
              }
            } else {
              router.showScreen(.push) { _ in
                AppleHealthPermissionView(metric: metric, onCreate: onCreate)
              }
            }
          } label: {
            VStack(alignment: .leading, spacing: 6) {
              Text(metric.title)
                .font(.headline)
                .foregroundStyle(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

              Text(metric.description)
                .font(.footnote)
                .foregroundStyle(.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .sameLevelBorder()
          }
          .buttonStyle(.plain)
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
    .navigationTitle("Data Source")
    .navigationBarTitleDisplayMode(.inline)
  }
}
