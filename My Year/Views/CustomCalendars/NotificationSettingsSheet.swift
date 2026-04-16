import Garnish
import RevenueCat
import RevenueCatUI
import SharedModels
import SwiftUI
import SwiftfulRouting

struct NotificationSettingsSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.router) private var router
  @Environment(\.colorScheme) private var colorScheme
  @ObservedObject private var store = CustomCalendarStore.shared

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
          VStack(alignment: .leading, spacing: 6) {
            betaBadge()
            Text(
              "Reminders are in beta and still evolving. Expect small changes, and occasional delays or misses while we tune reliability."
            )
            .descriptionStyle()
            .textCase(nil)
          }
          .frame(maxWidth: .infinity, alignment: .leading)

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

                HStack(spacing: 6) {
                  DatePicker("", selection: $reminderTime, displayedComponents: [.hourAndMinute])
                    .tint(Color(calendar.color))
                    .datePickerStyle(.compact)
                    .labelsHidden()

                  Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .notificationSurface()

                if calendar.trackingType == .multipleDaily {
                  if !additionalReminderTimes.isEmpty {
                    ForEach(additionalReminderTimes, id: \.id) { time in
                      additionalTimeRow(time: time)
                    }
                  }
                  if additionalReminderTimes.count < maxAdditionalReminderTimes {
                    HStack {
                      VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                          Text("Additional reminders")
                            .labelStyle(type: .secondary)
                          if !isPremiumUser {
                            proBadge()
                          }
                        }
                      }
                      Spacer()
                      Button(
                        action: addAdditionalReminderTime,
                        label: {
                          ZStack {
                            Image(systemName: "plus")
                              .font(.system(size: 16, design: .monospaced))
                              .foregroundStyle(.textTertiary)
                          }.frame(width: 24, height: 24)
                        })
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 14)
                    .notificationSurface()
                  }
                }
              }
            }
          }

          if recurringReminderEnabled {
            // if calendar.trackingType == .multipleDaily {
            //   NotificationSection(
            //     label: "Multiple Times",
            //     description: "Extra reminders for daily repeating habits."
            //   ) {
            //     VStack(spacing: 1) {
            //       HStack {
            //         VStack(alignment: .leading, spacing: 4) {
            //           HStack(spacing: 6) {
            //             Text("Additional reminders")
            //               .labelStyle(type: .secondary)
            //             if !isPremiumUser {
            //               proBadge()
            //             }
            //           }
            //         }
            //         Spacer()
            //         if additionalReminderTimes.count < maxAdditionalReminderTimes {
            //           Button(
            //             action: addAdditionalReminderTime,
            //             label: {
            //               ZStack {
            //                 Image(systemName: "plus")
            //                   .font(.system(size: 16, design: .monospaced))
            //                   .foregroundStyle(.textTertiary)
            //               }.frame(width: 24, height: 24)
            //             })
            //         }
            //       }
            //       .padding(.horizontal)
            //       .padding(.vertical, 14)
            //       .notificationSurface()

            //       if !additionalReminderTimes.isEmpty {
            //         ForEach(additionalReminderTimes, id: \.id) { time in
            //           additionalTimeRow(time: time)
            //         }
            //       }
            //     }
            //   }
            // }

            NotificationSection(
              label: "Streak Protection", description: "We will send you a reminder when you're about to miss a day."
            ) {
              VStack(spacing: 1) {
                HStack {
                  VStack(alignment: .leading, spacing: 4) {
                    Text("Late-day rescue reminder")
                      .labelStyle(type: .secondary)
                  }
                  Spacer()
                  Toggle("", isOn: $streakProtectionEnabled)
                }
                .tint(Color(calendar.color))
                .padding(.horizontal)
                .padding(.vertical, 10)
                .notificationSurface()

                HStack {
                  VStack(alignment: .leading, spacing: 4) {
                    Text("Smart suppression")
                      .labelStyle(type: .secondary)
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
          Button("Done") {
            Task {
              await saveAndDismiss()
            }
          }
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

  private func proBadge() -> some View {
    let bgColor = GarnishColor.blend(.surfaceMuted, with: .moodExcellent, ratio: 0.2)
    let fgColor = GarnishColor.blend(.textPrimary, with: .moodExcellent, ratio: 0.5)
    let strokeStyle = StrokeStyle(
      lineWidth: 1, lineCap: .round, lineJoin: .bevel, miterLimit: 1, dash: [2], dashPhase: 3
    )

    return badge(text: "PRO", bgColor: bgColor, fgColor: fgColor, strokeStyle: strokeStyle)
  }

  private func betaBadge() -> some View {
    let bgColor = Color("surface-muted").opacity(0.4)
    let fgColor = Color.textTertiary

    return badge(text: "BETA", bgColor: bgColor, fgColor: fgColor, strokeStyle: nil)
  }

  private func badge(
    text: String,
    bgColor: Color,
    fgColor: Color,
    strokeStyle: StrokeStyle?
  ) -> some View {
    let shape = RoundedRectangle(cornerRadius: 4)

    return Text(text)
      .font(.system(size: 8, design: .monospaced))
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(
        Group {
          if let strokeStyle {
            shape.stroke(style: strokeStyle)
          } else {
            shape.strokeBorder(fgColor, lineWidth: 1)
          }
        }
      )
      .background(bgColor)
      .foregroundColor(fgColor)
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
    withAnimation(.easeOut(duration: 0.15)) {
      additionalReminderTimes = normalizedAdditionalReminderTimes(additionalReminderTimes + [proposed])
    }
  }

  private func additionalTimeRow(time: ReminderTime) -> some View {
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
            guard let index = additionalReminderTimes.firstIndex(where: { $0.id == time.id }) else {
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
        withAnimation(.easeIn(duration: 0.12)) {
          additionalReminderTimes.removeAll { $0.id == time.id }
        }
      } label: {
        ZStack {
          Image(systemName: "minus")
            .font(.system(size: 16, design: .monospaced))
            .foregroundStyle(.red.secondary)
        }
        .frame(width: 24, height: 24)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .contentShape(Rectangle())

    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .notificationSurface()
    .transition(
      .asymmetric(
        insertion: .opacity.combined(with: .offset(y: 8)),
        removal: .opacity.combined(with: .offset(y: -8))
      )
    )
  }

  private func saveAndDismiss() async {
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

    guard store.updateCalendar(updatedCalendar) else {
      router.showAlert(
        .alert,
        title: "Save failed",
        subtitle: "The notification settings could not be saved."
      )
      return
    }

    onSave(updatedCalendar)

    do {
      try await rescheduleNotifications(for: updatedCalendar, store: store)
      dismiss()
    } catch {
      router.showAlert(
        .alert,
        title: "Notification setup failed",
        subtitle: error.localizedDescription
      )
    }
  }
}

private struct NotificationSection<Content: View>: View {
  let label: LocalizedStringKey
  let content: () -> Content
  let description: LocalizedStringKey?
  @Environment(\.colorScheme) private var colorScheme

  init(
    label: LocalizedStringKey,
    description: LocalizedStringKey? = nil,
    @ViewBuilder content: @escaping () -> Content
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
