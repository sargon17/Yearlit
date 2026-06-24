import SharedModels
import SwiftUI
import SwiftfulRouting

struct ConnectedCalendarSourcePickerView: View {
  let onCreate: (CustomCalendar) -> Void

  @ObservedObject private var store = CustomCalendarStore.shared
  @Environment(\.router) private var router

  private var hasAppleHealthStepsConnection: Bool {
    store.snapshot.calendars.contains { $0.source == .appleHealthSteps }
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        CustomSeparator()
          .padding(.horizontal, -16)

        VStack(alignment: .leading, spacing: 10) {
          Text("Choose a data source")
            .font(.headline)
            .foregroundStyle(.textPrimary)

          Text("Connected Calendars fill Check-ins from another source.")
            .font(.footnote)
            .foregroundStyle(.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)

        Button {
          if hasAppleHealthStepsConnection {
            router.showScreen(.push) { _ in
              AppleHealthStepsCalendarConfigView(onCreate: onCreate)
            }
          } else {
            router.showScreen(.push) { _ in
              AppleHealthPermissionView(onCreate: onCreate)
            }
          }
        } label: {
          VStack(alignment: .leading, spacing: 6) {
            Text("Apple Health Steps")
              .font(.headline)
              .foregroundStyle(.textPrimary)
              .frame(maxWidth: .infinity, alignment: .leading)

            Text("Import daily step counts and complete Periods when you reach your target.")
              .font(.footnote)
              .foregroundStyle(.textTertiary)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .padding()
          .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
          .sameLevelBorder()
        }
        .buttonStyle(.plain)

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
