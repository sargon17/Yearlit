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
        Text("How do you want to track progress?")
          .font(.headline)
          .foregroundStyle(.textPrimary)

        Text("Choose how this Calendar gets its Check-ins.")
          .font(.footnote)
          .foregroundStyle(.textTertiary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 8)

      HStack(spacing: 2) {
        creationPathButton(
          title: "Track myself",
          description: "Log Check-ins directly in Yearlit."
        ) {
          router.showScreen(.push) { _ in
            CreateManualCalendarView(onCreate: onCreate)
          }
        }

        creationPathButton(
          title: "Connect Apple Health",
          description: "Fill Check-ins from Apple Health automatically."
        ) {
          guard userCanCreateCalendar() else {
            router.showScreen(.sheet) { _ in
              OnboardingPaywall(
                showsCloseButton: true,
                isPresentedAsSheet: true,
                trigger: .calendarLimit,
                onNext: {}
              )
            }
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
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 6) {
        Text(title)
          .font(.headline)
          .foregroundStyle(.textPrimary)
          .frame(maxWidth: .infinity, alignment: .leading)

        Text(description)
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

  private func userCanCreateCalendar() -> Bool {
    isPremiumUser || store.snapshot.calendars.count < 3
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
