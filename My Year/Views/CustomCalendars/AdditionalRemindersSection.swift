import SharedModels
import SwiftUI

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

  private func infoRow(title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
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
            .font(AppFont.mono(16))
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
        .font(AppFont.mono(12))
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
            .font(AppFont.mono(16))
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
