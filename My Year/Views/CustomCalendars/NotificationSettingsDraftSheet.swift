import RevenueCat
import RevenueCatUI
import SharedModels
import SwiftUI
import SwiftfulRouting

struct NotificationSettingsDraftSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.router) private var router
  @Environment(\.colorScheme) private var colorScheme

  let calendarName: String
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

  private let maxTotalReminderTimesPerDay = 5

  private var isPremiumUser: Bool { isPremium(customerInfo: customerInfo) }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 32) {
          NotificationSection(label: "Daily Reminder") {
            VStack(spacing: 2) {
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text("Send a daily reminder")
                    .labelStyle(type: .secondary)
                  Text("A recurring notification at your chosen time.")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
                }
                Spacer()
                Toggle("", isOn: $recurringReminderEnabled)
              }
              .tint(accentColor)
              .padding(.horizontal)
              .padding(.vertical, 8)
              .notificationSurface()

              if recurringReminderEnabled {
                VStack(spacing: 2) {
                  VStack(spacing: 6) {
                    HStack {
                      Text("Time")
                        .labelStyle(type: .secondary)
                      Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    DatePicker("", selection: $reminderTime, displayedComponents: [.hourAndMinute])
                      .labelsHidden()
                      .tint(accentColor)
                      .datePickerStyle(.wheel)
                      .inputStyle(radius: 4, color: accentColor)
                      .colorScheme(.dark)
                      .padding(.horizontal)
                      .padding(.bottom, 10)
                  }
                  .notificationSurface()
                }
              }
            }
          }

          if recurringReminderEnabled {
            NotificationSection(label: "Privacy") {
              VStack(spacing: 2) {
                HStack {
                  VStack(alignment: .leading, spacing: 4) {
                    Text("Lock screen text")
                      .labelStyle(type: .secondary)
                    Text(notificationPrivacyMode.detail)
                      .font(.caption)
                      .foregroundStyle(.textTertiary)
                  }
                  Spacer()
                  Picker("Privacy Level", selection: $notificationPrivacyMode) {
                    ForEach(NotificationPrivacyMode.allCases, id: \.self) { mode in
                      Text(mode.description).tag(mode)
                    }
                  }
                  .pickerStyle(.menu)
                  .tint(accentColor)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .notificationSurface()

                HStack {
                  VStack(alignment: .leading, spacing: 4) {
                    Text("Smart suppression")
                      .labelStyle(type: .secondary)
                    Text("Skips the reminder if you already logged today.")
                      .font(.caption)
                      .foregroundStyle(.textTertiary)
                  }
                  Spacer()
                  Toggle("", isOn: $suppressWhenCompleted)
                }
                .tint(accentColor)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .notificationSurface()
              }
            }

            NotificationSection(label: "Multiple Times") {
              VStack(spacing: 2) {
                if trackingType != .multipleDaily {
                  HStack {
                    VStack(alignment: .leading, spacing: 4) {
                      Text("Only for Target tracking")
                        .labelStyle(type: .secondary)
                      Text("Extra reminders are available when your habit has a daily target.")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                    }
                    Spacer()
                  }
                  .padding(.horizontal)
                  .padding(.vertical, 12)
                  .notificationSurface()
                } else {
                  HStack {
                    VStack(alignment: .leading, spacing: 4) {
                      Text("Additional reminders (Premium)")
                        .labelStyle(type: .secondary)
                      Text("Up to \(maxTotalReminderTimesPerDay) total times per day.")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                    }
                    Spacer()
                    Button("Add") { addAdditionalReminderTime() }
                      .fontWeight(.bold)
                      .tint(accentColor)
                  }
                  .padding(.horizontal)
                  .padding(.vertical, 10)
                  .notificationSurface()

                  if !isPremiumUser {
                    HStack(spacing: 8) {
                      Image(systemName: "lock.fill")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.textTertiary)
                      Text("Upgrade to Premium to add more times.")
                        .font(.footnote)
                        .foregroundStyle(.textTertiary)
                      Spacer()
                      Button("Upgrade") { showPremiumPaywall() }
                        .fontWeight(.bold)
                        .tint(accentColor)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .notificationSurface()
                  }

                  if additionalReminderTimes.isEmpty {
                    HStack {
                      Text("No additional times.")
                        .font(.footnote)
                        .foregroundStyle(.textTertiary)
                      Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .notificationSurface()
                  } else {
                    ForEach(additionalReminderTimes.indices, id: \.self) { idx in
                      additionalTimeRow(index: idx)
                    }
                  }
                }
              }
            }

            NotificationSection(label: "Streak Protection") {
              VStack(spacing: 2) {
                HStack {
                  VStack(alignment: .leading, spacing: 4) {
                    Text("Late-day rescue reminder")
                      .labelStyle(type: .secondary)
                    Text("At 9 PM, if your streak is at risk, we send one extra reminder.")
                      .font(.caption)
                      .foregroundStyle(.textTertiary)
                  }
                  Spacer()
                  Toggle("", isOn: $streakProtectionEnabled)
                }
                .tint(accentColor)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .notificationSurface()

                if streakProtectionEnabled {
                  HStack {
                    VStack(alignment: .leading, spacing: 4) {
                      Text("Threshold")
                        .labelStyle(type: .secondary)
                      Text("Only triggers when your streak is at least this long.")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                    }
                    Spacer()
                    Stepper(value: $streakProtectionThreshold, in: 1...60) {
                      Text("\(streakProtectionThreshold) days")
                        .foregroundStyle(.textSecondary)
                    }
                    .tint(accentColor)
                  }
                  .padding(.horizontal)
                  .padding(.vertical, 10)
                  .notificationSurface()
                }
              }
            }
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
            if trackingType != .multipleDaily {
              additionalReminderTimes = []
            } else if !isPremiumUser {
              additionalReminderTimes = []
            } else {
              additionalReminderTimes = normalizedAdditionalReminderTimes(additionalReminderTimes)
            }

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
  private var maxAdditionalReminderTimes: Int { max(0, maxTotalReminderTimesPerDay - 1) }

  private func showPremiumPaywall() {
    router.showScreen(.sheet) { _ in
      PaywallView(displayCloseButton: true)
    }
  }

  private struct NotificationSection<Content: View>: View {
    let label: LocalizedStringKey
    let content: () -> Content
    @Environment(\.colorScheme) private var colorScheme

    init(label: LocalizedStringKey, @ViewBuilder content: @escaping () -> Content) {
      self.label = label
      self.content = content
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        Text(label)
          .labelStyle(type: .tertiary)

        VStack(alignment: .leading, spacing: 2) {
          content()
        }
        // Show 2pt black gaps between each flat surface.
        .padding(2)
        .background(
          RoundedRectangle(cornerRadius: 6)
            .fill(getVoidColor(colorScheme: colorScheme))
        )
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func normalizedAdditionalReminderTimes(_ times: [ReminderTime]) -> [ReminderTime] {
    guard trackingType == .multipleDaily else {
      return []
    }

    var seen = Set<String>()
    let deduped = times.filter { time in
      let key = time.id
      if seen.contains(key) { return false }
      seen.insert(key)
      return true
    }

    let sorted = deduped.sorted {
      if $0.hour != $1.hour { return $0.hour < $1.hour }
      return $0.minute < $1.minute
    }

    return Array(sorted.prefix(maxAdditionalReminderTimes))
  }

  private func addAdditionalReminderTime() {
    guard trackingType == .multipleDaily else { return }
    guard isPremiumUser else {
      showPremiumPaywall()
      return
    }

    guard additionalReminderTimes.count < maxAdditionalReminderTimes else { return }

    let base = additionalReminderTimes.last?.toDate() ?? reminderTime
    let next = Calendar.current.date(byAdding: .hour, value: 1, to: base) ?? base
    let proposed = ReminderTime(from: next)
    additionalReminderTimes = normalizedAdditionalReminderTimes(additionalReminderTimes + [proposed])
  }

  private func additionalTimeRow(index: Int) -> some View {
    let time = additionalReminderTimes[index]

    return HStack {
      DatePicker(
        "",
        selection: Binding(
          get: { time.toDate() },
          set: { newDate in
            guard isPremiumUser else {
              showPremiumPaywall()
              return
            }
            var updated = additionalReminderTimes
            updated[index] = ReminderTime(from: newDate)
            additionalReminderTimes = normalizedAdditionalReminderTimes(updated)
          }
        ),
        displayedComponents: [.hourAndMinute]
      )
      .labelsHidden()
      .tint(accentColor)
      .datePickerStyle(.compact)
      .disabled(!isPremiumUser)

      Spacer()

      Button(role: .destructive) {
        guard isPremiumUser else {
          showPremiumPaywall()
          return
        }
        additionalReminderTimes.remove(at: index)
      } label: {
        Text("Remove")
          .foregroundStyle(.moodTerrible)
      }
      .buttonStyle(.plain)
      .disabled(!isPremiumUser)
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .notificationSurface()
  }
}

extension View {
  fileprivate func notificationSurface() -> some View {
    self
      .sameLevelBorder(radius: 6, isFlat: true)
      .overlay(
        RoundedRectangle(cornerRadius: 6)
          .stroke(Color.black.opacity(0.75), lineWidth: 2)
      )
  }
}
