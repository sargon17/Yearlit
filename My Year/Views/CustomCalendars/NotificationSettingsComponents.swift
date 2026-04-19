import SharedModels
import SwiftUI

enum NotificationSettingsStyle {
  case draft
  case saved
}

struct NotificationSettingsSection<Content: View>: View {
  let label: LocalizedStringKey
  let description: LocalizedStringKey?
  let style: NotificationSettingsStyle
  let content: () -> Content

  @Environment(\.colorScheme) private var colorScheme

  init(
    label: LocalizedStringKey,
    description: LocalizedStringKey? = nil,
    style: NotificationSettingsStyle,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.label = label
    self.description = description
    self.style = style
    self.content = content
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      VStack(alignment: .leading, spacing: 4) {
        Text(label)
          .labelStyle(type: style == .saved ? .secondary : .tertiary)
          .textCase(nil)

        if let description {
          Text(description)
            .descriptionStyle()
            .textCase(nil)
        }
      }

      VStack(alignment: .leading, spacing: style == .saved ? 1 : 2) {
        content()
      }
      .padding(style == .saved ? 1 : 2)
      .background(
        Group {
          if style == .saved {
            Rectangle().fill(getVoidColor(colorScheme: colorScheme))
          } else {
            RoundedRectangle(cornerRadius: 6).fill(getVoidColor(colorScheme: colorScheme))
          }
        }
      )
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct ReminderScheduleSection: View {
  let cadence: CalendarCadence
  let accentColor: Color
  let style: NotificationSettingsStyle

  @Binding var recurringReminderEnabled: Bool
  @Binding var reminderTime: Date
  @Binding var reminderWeekday: Int

  var body: some View {
    NotificationSettingsSection(
      label: cadence == .weekly ? "Weekly Reminder" : "Daily Reminder",
      description: cadence == .weekly
        ? "A recurring notification on your chosen weekday and time."
        : "A recurring notification at your chosen time.",
      style: style
    ) {
      toggleRow

      if recurringReminderEnabled {
        if cadence == .weekly {
          weekdayRow
        }
        timeRow
      }
    }
  }

  private var toggleRow: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(cadence == .weekly ? "Send a weekly reminder" : "Send a daily reminder")
          .labelStyle(type: .secondary)
      }
      Spacer()
      Toggle("", isOn: $recurringReminderEnabled)
    }
    .tint(accentColor)
    .padding(.horizontal)
    .padding(.vertical, 8)
    .notificationSurface()
  }

  private var weekdayRow: some View {
    HStack {
      Text("Weekday")
        .labelStyle(type: .secondary)
      Spacer()
      Picker("Weekday", selection: $reminderWeekday) {
        ForEach(NotificationSettingsHelpers.orderedWeekdays(), id: \.self) { weekday in
          Text(NotificationSettingsHelpers.weekdayName(weekday)).tag(weekday)
        }
      }
      .pickerStyle(.menu)
      .tint(accentColor)
    }
    .padding(.horizontal)
    .padding(.vertical, 10)
    .notificationSurface()
  }

  @ViewBuilder
  private var timeRow: some View {
    switch style {
    case .saved:
      HStack(spacing: 6) {
        DatePicker("", selection: $reminderTime, displayedComponents: [.hourAndMinute])
          .tint(accentColor)
          .datePickerStyle(.compact)
          .labelsHidden()
        Spacer()
      }
      .padding(.horizontal)
      .padding(.vertical, 8)
      .notificationSurface()

    case .draft:
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

struct AdditionalRemindersSection: View {
  let cadence: CalendarCadence
  let trackingType: TrackingType
  let accentColor: Color
  let isPremiumUser: Bool
  let style: NotificationSettingsStyle
  let onUpgrade: () -> Void

  @Binding var additionalReminderTimes: [ReminderTime]
  @Binding var reminderTime: Date

  private let maxTotalReminderTimesPerDay = 5

  var body: some View {
    NotificationSettingsSection(label: "Multiple Times", style: style) {
      if cadence == .weekly {
        infoRow(
          title: "Not available for weekly reminders",
          description: "Weekly calendars only send one reminder on the selected weekday."
        )
      } else if trackingType != .multipleDaily {
        infoRow(
          title: "Only for Target tracking",
          description: "Extra reminders are available when your habit has a daily target."
        )
      } else {
        addRow

        if !isPremiumUser {
          lockedRow
        }

        if additionalReminderTimes.isEmpty {
          emptyRow
        } else {
          ForEach(additionalReminderTimes, id: \.id) { time in
            additionalTimeRow(time: time)
          }
        }
      }
    }
  }

  private var maxAdditionalReminderTimes: Int {
    max(0, maxTotalReminderTimesPerDay - 1)
  }

  private func normalizedAdditionalReminderTimes(_ times: [ReminderTime]) -> [ReminderTime] {
    NotificationSettingsHelpers.sanitizedAdditionalReminderTimes(
      times,
      cadence: cadence,
      trackingType: trackingType,
      maxTotalReminderTimesPerDay: maxTotalReminderTimesPerDay
    )
  }

  private func addAdditionalReminderTime() {
    guard isPremiumUser else {
      onUpgrade()
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

  private func updateTime(_ time: ReminderTime, to newDate: Date) {
    guard isPremiumUser else {
      onUpgrade()
      return
    }
    guard let index = additionalReminderTimes.firstIndex(where: { $0.id == time.id }) else { return }
    var updated = additionalReminderTimes
    updated[index] = ReminderTime(from: newDate)
    additionalReminderTimes = normalizedAdditionalReminderTimes(updated)
  }

  private func removeTime(_ time: ReminderTime) {
    guard isPremiumUser else {
      onUpgrade()
      return
    }
    withAnimation(.easeIn(duration: 0.12)) {
      additionalReminderTimes.removeAll { $0.id == time.id }
    }
  }

  private func infoRow(title: String, description: String) -> some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .labelStyle(type: .secondary)
        Text(description)
          .font(.caption)
          .foregroundStyle(.textTertiary)
      }
      Spacer()
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
    .notificationSurface()
  }

  private var addRow: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Additional reminders")
          .labelStyle(type: .secondary)
        Text("Up to \(maxTotalReminderTimesPerDay) total times per day.")
          .font(.caption)
          .foregroundStyle(.textTertiary)
      }
      Spacer()

      switch style {
      case .saved:
        Button(action: addAdditionalReminderTime) {
          Image(systemName: "plus")
            .font(.system(size: 16, design: .monospaced))
            .foregroundStyle(.textTertiary)
            .frame(width: 24, height: 24)
        }
      case .draft:
        Button("Add") { addAdditionalReminderTime() }
          .fontWeight(.bold)
          .tint(accentColor)
      }
    }
    .padding(.horizontal)
    .padding(.vertical, style == .saved ? 14 : 10)
    .notificationSurface()
  }

  private var lockedRow: some View {
    HStack(spacing: 8) {
      Image(systemName: "lock.fill")
        .font(.system(size: 12, design: .monospaced))
        .foregroundStyle(.textTertiary)
      Text("Upgrade to Premium to add more times.")
        .font(.footnote)
        .foregroundStyle(.textTertiary)
      Spacer()
      Button("Upgrade") { onUpgrade() }
        .fontWeight(.bold)
        .tint(accentColor)
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
    .notificationSurface()
  }

  private var emptyRow: some View {
    HStack {
      Text("No additional times.")
        .font(.footnote)
        .foregroundStyle(.textTertiary)
      Spacer()
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
    .notificationSurface()
  }

  private func additionalTimeRow(time: ReminderTime) -> some View {
    HStack {
      DatePicker(
        "",
        selection: Binding(
          get: { time.toDate() },
          set: { newDate in updateTime(time, to: newDate) }
        ),
        displayedComponents: [.hourAndMinute]
      )
      .labelsHidden()
      .tint(accentColor)
      .datePickerStyle(.compact)
      .disabled(!isPremiumUser)

      Spacer()

      switch style {
      case .saved:
        Button(role: .destructive) { removeTime(time) } label: {
          Image(systemName: "minus")
            .font(.system(size: 16, design: .monospaced))
            .foregroundStyle(.red.secondary)
            .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)

      case .draft:
        Button(role: .destructive) { removeTime(time) } label: {
          Text("Remove")
            .foregroundStyle(.moodTerrible)
        }
        .buttonStyle(.plain)
        .disabled(!isPremiumUser)
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .notificationSurface()
  }
}

struct PrivacySection: View {
  let style: NotificationSettingsStyle
  let accentColor: Color
  @Binding var notificationPrivacyMode: NotificationPrivacyMode

  var body: some View {
    NotificationSettingsSection(
      label: "Privacy",
      description: style == .saved ? "Determines how the notifications appear on your lock screen." : nil,
      style: style
    ) {
      switch style {
      case .saved:
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

      case .draft:
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
      }
    }
  }
}

struct ReminderBehaviorSection: View {
  let cadence: CalendarCadence
  let accentColor: Color
  let style: NotificationSettingsStyle

  @Binding var suppressWhenCompleted: Bool
  @Binding var streakProtectionEnabled: Bool

  var body: some View {
    if style == .saved {
      NotificationSettingsSection(
        label: "Streak Protection",
        description: cadence == .weekly
          ? "We will send you a reminder when you're about to miss the week."
          : "We will send you a reminder when you're about to miss a day.",
        style: style
      ) {
        streakProtectionRow
        suppressionRow
      }
    } else {
      NotificationSettingsSection(label: "Behavior", style: style) {
        suppressionRow
        streakProtectionRow
      }
    }
  }

  private var streakProtectionRow: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Late-day rescue reminder")
          .labelStyle(type: .secondary)
        if style == .draft {
          Text(
            cadence == .weekly
              ? "On the last day of the week at 9 PM, if your streak is at risk, we send one extra reminder."
              : "At 9 PM, if your streak is at risk, we send one extra reminder."
          )
          .font(.caption)
          .foregroundStyle(.textTertiary)
        }
      }
      Spacer()
      Toggle("", isOn: $streakProtectionEnabled)
    }
    .tint(accentColor)
    .padding(.horizontal)
    .padding(.vertical, 10)
    .notificationSurface()
  }

  private var suppressionRow: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Smart suppression")
          .labelStyle(type: .secondary)
        Text(
          cadence == .weekly
            ? "While the app is open, hides reminders if you've already logged this week."
            : "While the app is open, hides reminders if you've already logged today."
        )
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

enum NotificationSettingsHelpers {
  static func sanitizedAdditionalReminderTimes(
    _ times: [ReminderTime],
    cadence: CalendarCadence,
    trackingType: TrackingType,
    maxTotalReminderTimesPerDay: Int = 5
  ) -> [ReminderTime] {
    guard cadence == .daily, trackingType == .multipleDaily else { return [] }

    let maxAdditionalReminderTimes = max(0, maxTotalReminderTimesPerDay - 1)
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

  static func orderedWeekdays() -> [Int] {
    let calendar = Calendar.current
    return (0 ..< 7).map { offset in
      ((calendar.firstWeekday - 1 + offset) % 7) + 1
    }
  }

  static func weekdayName(_ weekday: Int) -> String {
    let symbols = Calendar.current.weekdaySymbols
    let index = max(1, min(7, weekday)) - 1
    return symbols[index]
  }

  static func reminderSummary(
    isEnabled: Bool,
    cadence: CalendarCadence,
    reminderTime: Date,
    reminderWeekday: Int
  ) -> String {
    guard isEnabled else {
      return cadence == .weekly
        ? "Off • set a weekly reminder and privacy level."
        : "Off • set a daily reminder and privacy level."
    }

    let time = reminderTime.formatted(date: .omitted, time: .shortened)
    if cadence == .weekly {
      return "On • \(weekdayName(reminderWeekday)) at \(time)."
    }
    return "On • every day at \(time)."
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
