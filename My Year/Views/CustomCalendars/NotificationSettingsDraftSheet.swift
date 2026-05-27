import RevenueCat
import RevenueCatUI
import SharedModels
import SwiftfulRouting
import SwiftUI

struct NotificationSettingsDraftSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.router) private var router

    let calendarName: String
    let cadence: CalendarCadence
    let trackingType: TrackingType
    let accentColor: Color
    let customerInfo: CustomerInfo?

    @Binding var recurringReminderEnabled: Bool
    @Binding var reminderTime: Date
    @Binding var notificationPrivacyMode: NotificationPrivacyMode
    @Binding var suppressWhenCompleted: Bool
    @Binding var additionalReminderTimes: [ReminderTime]
    @Binding var streakProtectionEnabled: Bool
    @Binding var streakProtectionThreshold: Int
    @Binding var reminderWeekday: Int

    private var isPremiumUser: Bool {
        isPremium(customerInfo: customerInfo)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    ReminderScheduleSection(
                        cadence: cadence,
                        accentColor: accentColor,
                        style: .draft,
                        recurringReminderEnabled: $recurringReminderEnabled,
                        reminderTime: $reminderTime,
                        reminderWeekday: $reminderWeekday
                    )

                    if recurringReminderEnabled {
                        AdditionalRemindersSection(
                            cadence: cadence,
                            trackingType: trackingType,
                            accentColor: accentColor,
                            isPremiumUser: isPremiumUser,
                            style: .draft,
                            onUpgrade: showPremiumPaywall,
                            additionalReminderTimes: $additionalReminderTimes,
                            reminderTime: $reminderTime
                        )

                        ReminderBehaviorSection(
                            cadence: cadence,
                            accentColor: accentColor,
                            style: .draft,
                            suppressWhenCompleted: $suppressWhenCompleted,
                            streakProtectionEnabled: $streakProtectionEnabled
                        )

                        PrivacySection(
                            style: .draft,
                            accentColor: accentColor,
                            notificationPrivacyMode: $notificationPrivacyMode
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        additionalReminderTimes =
                            (cadence == .daily && trackingType == .multipleDaily && isPremiumUser)
                                ? NotificationSettingsHelpers.sanitizedAdditionalReminderTimes(
                                    additionalReminderTimes,
                                    cadence: cadence,
                                    trackingType: trackingType
                                )
                                : []
                        dismiss()
                    }
                }
            }
            .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
        }
    }
}

extension NotificationSettingsDraftSheet {
    private func showPremiumPaywall() {
        router.showScreen(.sheet) { _ in
            PremiumPaywallSheet(displayCloseButton: true, trigger: .notificationGate)
        }
    }
}
