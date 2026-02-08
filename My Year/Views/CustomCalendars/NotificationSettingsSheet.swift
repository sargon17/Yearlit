import RevenueCat
import RevenueCatUI
import SharedModels
import SwiftUI
import SwiftfulRouting

struct NotificationSettingsSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.router) private var router
  @Environment(\.colorScheme) private var colorScheme

  let calendar: CustomCalendar
  let customerInfo: CustomerInfo?
  let onSave: (CustomCalendar) -> Void

  @State private var recurringReminderEnabled: Bool
  @State private var reminderTime: Date
  @State private var notificationPrivacyMode: NotificationPrivacyMode
  @State private var suppressWhenCompleted: Bool
  @State private var additionalReminderTimes: [ReminderTime]
  @State private var streakProtectionEnabled: Bool
  @State private var streakProtectionThreshold: Int

  private let maxTotalReminderTimesPerDay = 5

  private var isPremiumUser: Bool {
    isPremium(customerInfo: customerInfo)
  }

  init(
    calendar: CustomCalendar,
    customerInfo: CustomerInfo?,
    onSave: @escaping (CustomCalendar) -> Void
  ) {
    self.calendar = calendar
    self.customerInfo = customerInfo
    self.onSave = onSave

    _recurringReminderEnabled = State(initialValue: calendar.recurringReminderEnabled)

    let defaultTime =
      Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    if calendar.recurringReminderEnabled, let hour = calendar.reminderHour, let minute = calendar.reminderMinute {
      _reminderTime = State(
        initialValue: Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? defaultTime
      )
    } else {
      _reminderTime = State(initialValue: defaultTime)
    }

    _notificationPrivacyMode = State(initialValue: calendar.notificationPrivacyMode)
    _suppressWhenCompleted = State(initialValue: calendar.suppressWhenCompleted)
    _additionalReminderTimes = State(initialValue: calendar.additionalReminderTimes)
    _streakProtectionEnabled = State(initialValue: calendar.streakProtectionEnabled)
    _streakProtectionThreshold = State(initialValue: calendar.streakProtectionThreshold)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 32) {
          NotificationSection(label: "Daily Reminder", description: "A recurring notification at your chosen time.") {
            VStack(spacing: 1) {
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text("Send a daily reminder")
                    .labelStyle(type: .secondary)
                }
                Spacer()
                Toggle("", isOn: $recurringReminderEnabled)
              }
              .tint(Color(calendar.color))
              .padding(.horizontal)
              .padding(.vertical, 8)
              .notificationSurface()

              if recurringReminderEnabled {
                VStack {
                  HStack(spacing: 6) {
                    Text("Time")
                      .labelStyle(type: .secondary)

                    Spacer()
                    DatePicker("", selection: $reminderTime, displayedComponents: [.hourAndMinute])
                      .tint(Color(calendar.color))
                      .datePickerStyle(.graphical)
                      .frame(maxWidth: .greatestFiniteMagnitude)
                  }
                  .padding(.leading)
                  .notificationSurface()
                }
              }
            }
          }

          if recurringReminderEnabled {
            if calendar.trackingType == .multipleDaily {
              NotificationSection(
                label: "Multiple Times",
                description: "Extra reminders for daily repeating habits."
              ) {
                VStack(spacing: 1) {
                  HStack {
                    VStack(alignment: .leading, spacing: 4) {
                      Text("Additional reminders")
                        .labelStyle(type: .secondary)
                    }
                    Spacer()
                    Button(
                      action: addAdditionalReminderTime,
                      label: {
                        Image(systemName: "plus")
                          .font(.system(size: 16, design: .monospaced))
                          .foregroundStyle(.textTertiary)
                      })
                  }
                  .padding(.horizontal)
                  .padding(.vertical, 14)
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
                        .tint(Color(calendar.color))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .notificationSurface()
                  }

                  if !additionalReminderTimes.isEmpty {
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
                .tint(Color(calendar.color))
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
                    .tint(Color(calendar.color))
                  }
                  .padding(.horizontal)
                  .padding(.vertical, 10)
                  .notificationSurface()
                }

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
                .tint(Color(calendar.color))
                .padding(.horizontal)
                .padding(.vertical, 10)
                .notificationSurface()
              }
            }

            NotificationSection(
              label: "Privacy", description: "Determines how the notifications appear on your lock screen."
            ) {
              VStack(spacing: 1) {
                VStack {
                  HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 4) {
                      Text("Lock screen text")
                        .labelStyle(type: .secondary)
                      Text(notificationPrivacyMode.detail)
                        .descriptionStyle()
                    }

                    Spacer()
                  }
                  .padding(.horizontal)

                  Picker("Privacy Level", selection: $notificationPrivacyMode) {
                    ForEach(NotificationPrivacyMode.allCases, id: \.self) { mode in
                      Text(mode.description).tag(mode)
                    }
                  }
                  .pickerStyle(.segmented)
                  .font(.system(size: 12, design: .monospaced))
                  .padding(.horizontal, 6)
                }
                .padding(.vertical, 12)
                .notificationSurface()
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
          Button("Done") { saveAndDismiss() }
        }
      }
      .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
      .scrollContentBackground(.hidden)
      .scrollIndicators(.hidden)
    }
  }
}

extension NotificationSettingsSheet {
  private var maxAdditionalReminderTimes: Int {
    max(0, maxTotalReminderTimesPerDay - 1)
  }

  private func showPremiumPaywall() {
    router.showScreen(.sheet) { _ in
      PaywallView(displayCloseButton: true)
    }
  }

  private func normalizedAdditionalReminderTimes(_ times: [ReminderTime]) -> [ReminderTime] {
    guard calendar.trackingType == .multipleDaily else {
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
    guard calendar.trackingType == .multipleDaily else { return }
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
      .tint(Color(calendar.color))
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
        Image(systemName: "minus")
          .font(.system(size: 16, design: .monospaced))
          .foregroundStyle(.red.secondary)
      }
      .buttonStyle(.plain)
      .disabled(!isPremiumUser)
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .notificationSurface()
  }

  private func saveAndDismiss() {
    var updatedCalendar = calendar
    updatedCalendar.recurringReminderEnabled = recurringReminderEnabled

    if recurringReminderEnabled {
      let cal = Calendar.current
      updatedCalendar.reminderHour = cal.component(.hour, from: reminderTime)
      updatedCalendar.reminderMinute = cal.component(.minute, from: reminderTime)
    } else {
      updatedCalendar.reminderHour = nil
      updatedCalendar.reminderMinute = nil
    }

    updatedCalendar.notificationPrivacyMode = notificationPrivacyMode
    updatedCalendar.suppressWhenCompleted = suppressWhenCompleted

    if isPremiumUser && calendar.trackingType == .multipleDaily {
      updatedCalendar.additionalReminderTimes = normalizedAdditionalReminderTimes(additionalReminderTimes)
    } else {
      updatedCalendar.additionalReminderTimes = []
    }

    updatedCalendar.streakProtectionEnabled = streakProtectionEnabled
    updatedCalendar.streakProtectionThreshold = streakProtectionThreshold

    scheduleNotifications(for: updatedCalendar, store: CustomCalendarStore.shared)
    onSave(updatedCalendar)
    dismiss()
  }
}

private struct NotificationSection<Content: View>: View {
  let label: LocalizedStringKey
  let content: () -> Content
  let description: LocalizedStringKey?
  @Environment(\.colorScheme) private var colorScheme

  init(
    label: LocalizedStringKey,
    @ViewBuilder content: @escaping () -> Content,
    description: LocalizedStringKey? = nil
  ) {
    self.label = label
    self.content = content
    self.description = description
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      VStack(alignment: .leading, spacing: 4) {
        Text(label)
          .labelStyle(type: .secondary)
          .textCase(nil)
        if let description = description {
          Text(description)
            .descriptionStyle()
            .textCase(nil)
        }
      }

      VStack(alignment: .leading, spacing: 1) {
        content()
      }
      // Show 2pt black gaps between each flat surface.
      .padding(1)
      .background(
        Rectangle()
          .fill(getVoidColor(colorScheme: colorScheme))
      )

    }
    .frame(maxWidth: .infinity, alignment: .leading)
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
