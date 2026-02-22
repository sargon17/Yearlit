import Garnish
import SharedModels
import SwiftDate
import SwiftUI

struct CreateFirstHabit: View {
    let onNext: () -> Void
    @ObservedObject private var store = CustomCalendarStore.shared
    @Environment(\.colorScheme) var colorScheme

    @State var name = ""
    @State var recurringReminderEnabled = true
    @State private var showingNotificationSettings: Bool = false
    @State private var reminderTime: Date = {
        var components = DateComponents()
        components.hour = 8
        components.minute = 30
        return Calendar.current.date(from: components) ?? Date()
    }()

    @State private var notificationPrivacyMode: NotificationPrivacyMode = .full
    @State private var suppressWhenCompleted: Bool = true
    @State private var additionalReminderTimes: [ReminderTime] = []
    @State private var streakProtectionEnabled: Bool = true
    @State private var streakProtectionThreshold: Int = 5

    var disabled: Bool {
        return name.count > 2 ? false : true
    }

    func handleNext() {
        let calendar = CustomCalendar(
            name: name,
            color: "qs-orange",
            trackingType: .binary,
            dailyTarget: 1,
            isArchived: false,
            recurringReminderEnabled: recurringReminderEnabled,
            reminderTime: recurringReminderEnabled ? reminderTime : nil,
            unit: UnitOfMeasure.none,
            defaultRecordValue: 1,
            currencySymbol: nil,
            reminderTimeZone: TimeZone.current.identifier,
            notificationPrivacyMode: notificationPrivacyMode,
            suppressWhenCompleted: suppressWhenCompleted,
            additionalReminderTimes: [],
            streakProtectionEnabled: streakProtectionEnabled,
            streakProtectionThreshold: streakProtectionThreshold
        )

        store.addCalendar(calendar)
        scheduleNotifications(for: calendar, store: store)

        onNext()
    }

    var body: some View {
        OnboardingView.OnboardingSlide(
            onNext: handleNext,
            onSkip: onNext,
            disabled: disabled,
            withSkip: true
        ) {
            VStack(spacing: 12) {
                CustomSection(label: "Give it a name") {
                    TextField(
                        "",
                        text: $name,
                        prompt: Text("Daily Training").foregroundColor(.white.opacity(0.2))
                    )
                    .inputStyle(color: .brand)
                    .accentColor(.brand)
                }

                CustomSection(label: "Recurring Reminder") {
                    VStack(spacing: 2) {
                        Button(action: { showingNotificationSettings = true }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Notification settings")
                                        .labelStyle(type: .secondary)
                                    Text(
                                        recurringReminderEnabled
                                            ? "On • set your time, privacy, and suppression."
                                            : "Off • add a daily reminder when you're ready."
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.textTertiary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(.textTertiary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        .sameLevelBorder()
                    }
                    .padding(.all, 2)
                    .background(getVoidColor(colorScheme: colorScheme))
                }

            }.padding()

        } lower: {
            VStack(alignment: .leading, spacing: 8) {
                Spacer()

                Text("Set your first habit.")
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundStyle(.textPrimary)

                // To make habits stick, keep them:
                VStack(alignment: .leading) {
                    Text("Step 1: Choose your focus (reading, learning, fitness, mindfulness)")
                    Text("Step 2: Set a tiny daily action")
                    Text("Step 3: Start today")
                }
                .multilineTextAlignment(.leading)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsDraftSheet(
                calendarName: name,
                trackingType: .binary,
                accentColor: .brand,
                customerInfo: nil,
                recurringReminderEnabled: $recurringReminderEnabled,
                reminderTime: $reminderTime,
                notificationPrivacyMode: $notificationPrivacyMode,
                suppressWhenCompleted: $suppressWhenCompleted,
                additionalReminderTimes: $additionalReminderTimes,
                streakProtectionEnabled: $streakProtectionEnabled,
                streakProtectionThreshold: $streakProtectionThreshold
            )
        }
    }
}
