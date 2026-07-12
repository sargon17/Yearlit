import RevenueCat
import SharedModels
import SwiftUI
import SwiftfulRouting

struct CreateCalendarChoiceView: View {
  let onCreate: (CustomCalendar) -> Void

  @State private var customerInfo: CustomerInfo?
  @ObservedObject private var store = CustomCalendarStore.shared
  @Environment(\.router) private var router

  private var isPremiumUser: Bool {
    isPremium(customerInfo: customerInfo)
  }

  var body: some View {
    VStack(spacing: 32) {
      Spacer()
      CustomSeparator()
        .padding(.horizontal, -16)

      VStack(alignment: .leading, spacing: 10) {
        Text("Build a Calendar")
          .font(.headline)
          .foregroundStyle(.textPrimary)

        Text("Start fresh, or bring in the year you already lived.")
          .font(.footnote)
          .foregroundStyle(.textTertiary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 8)

      VStack(spacing: 12) {
        creationPathButton(
          title: "Log it in Yearlit",
          description: "Create a Calendar you check in yourself.",
          detail: "FLEXIBLE · DAILY OR WEEKLY",
          preview: (Set(stride(from: 1, through: 350, by: 11)), Color("qs-amber"))
        ) {
          guard userCanCreateCalendar() else {
            showCalendarLimitPaywall()
            return
          }
          router.showScreen(.push) { _ in
            CreateManualCalendarView(onCreate: onCreate)
          }
        }

        creationPathButton(
          title: "Fill from Apple Health",
          description: "Turn activity already on your iPhone into a Calendar.",
          detail: "AUTOMATIC · INCLUDES THIS YEAR",
          preview: (Set(stride(from: 0, through: 360, by: 3)), Color("qs-green"))
        ) {
          guard userCanCreateCalendar() else {
            showCalendarLimitPaywall()
            return
          }

          router.showScreen(.push) { _ in
            ConnectedCalendarSourcePickerView(onCreate: onCreate)
          }
        }
      }

      CustomSeparator()
        .padding(.horizontal, -16)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .navigationTitle("Create Calendar")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          router.dismissScreen()
        }
      }
    }
    .task {
      await observeCustomerInfo()
    }
  }

  private func creationPathButton(
    title: LocalizedStringKey,
    description: LocalizedStringKey,
    detail: LocalizedStringKey,
    preview: (completedDays: Set<Int>, color: Color),
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 10) {
        Text(title)
          .font(.headline)
          .foregroundStyle(.textPrimary)
          .frame(maxWidth: .infinity, alignment: .leading)

        Text(description)
          .font(.footnote)
          .foregroundStyle(.textTertiary)
          .frame(maxWidth: .infinity, alignment: .leading)
        CalendarCreationPreview(color: preview.color, completedDays: preview.completedDays)

        Text(detail)
          .font(AppFont.mono(10, weight: .medium))
          .foregroundStyle(.textTertiary)
      }
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .sameLevelBorder()
    }
    .buttonStyle(.plain)
  }

  private func userCanCreateCalendar() -> Bool {
    isPremiumUser || store.snapshot.calendars.count < 3
  }

  private func showCalendarLimitPaywall() {
    router.showScreen(.sheet) { _ in
      OnboardingPaywall(
        showsCloseButton: true,
        isPresentedAsSheet: true,
        trigger: .calendarLimit,
        onNext: {}
      )
    }
  }

  @MainActor
  private func observeCustomerInfo() async {
    do {
      customerInfo = try await Purchases.shared.customerInfo()
    } catch {
      print("Error fetching customer info: \(error.localizedDescription)")
    }

    for await info in Purchases.shared.customerInfoStream {
      customerInfo = info
      AnalyticsState.shared.updatePremiumStatus(customerInfo: info)
    }
  }
}
