import SharedModels
import SwiftUI

struct CustomCalendarHeaderView: View {
  let calendar: CustomCalendar
  let renderSnapshot: CalendarRenderSnapshot
  let yearText: String
  let selectedYear: Int
  let isCurrentPeriodCompleted: Bool
  let showsDeveloperControls: Bool
  let showsAppleHealthDebugControls: Bool
  let isSyncingAppleHealth: Bool
  let onEdit: () -> Void
  let onFillRandomEntries: () -> Void
  let onQuickAdd: () -> Void
  let onShowYearPicker: () -> Void
  let onNotificationSettings: () -> Void
  let onAppleHealthDebugSync: () -> Void

  var body: some View {
    VStack(spacing: 10) {
      HStack(alignment: .center, spacing: 6) {
        VStack(alignment: .leading, spacing: 0) {
          titleRow
          metadataRow
        }
      }
      .padding(.horizontal)
      .padding(.top, 10)
      CustomSeparator()
    }
  }

  private var titleRow: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Text(calendar.name.capitalized)
        .font(AppFont.sans(36))
        .fontWeight(.black)
        .lineLimit(2)
        .minimumScaleFactor(0.5)
        .foregroundColor(Color("text-primary"))
        .onTapGesture(perform: onEdit)
        .padding(.top)

      Spacer()

      if showsDeveloperControls {
        Button(action: onFillRandomEntries) {
          Image(systemName: "wand.and.stars")
            .foregroundColor(Color(calendar.color))
        }
        .padding(.horizontal, 4)
      }

      if showsQuickAddButton {
        Button(action: onQuickAdd) {
          ZStack {
            RoundedRectangle(cornerRadius: 3)
              .fill(Color(calendar.color).opacity(0.1))
              .frame(width: 20, height: 20)

            Image(systemName: quickAddSystemImage)
              .font(.system(size: 16))
              .foregroundColor(Color(calendar.color))
          }
        }
        .frame(width: 24, height: 24)
      }
    }
  }

  private var metadataRow: some View {
    HStack(spacing: 10) {
      timelineLabel

      if !calendar.isAppleHealthConnected {
        reminderLabel
      }

      if showsAppleHealthDebugControls {
        Text("•")
          .font(AppFont.mono(4, weight: .black))
          .foregroundColor(Color("text-tertiary"))
          .padding(.horizontal, 2)

        Button(action: onAppleHealthDebugSync) {
          HStack(spacing: 4) {
            Image(systemName: isSyncingAppleHealth ? "arrow.triangle.2.circlepath" : "heart.text.square")
            Text(isSyncingAppleHealth ? "Syncing" : "Debug sync")
          }
          .font(AppFont.mono(12))
          .foregroundColor(Color("text-tertiary"))
        }
        .buttonStyle(.plain)
        .disabled(isSyncingAppleHealth)
      }
    }
  }

  @ViewBuilder
  private var timelineLabel: some View {
    if renderSnapshot.isShowingYour365 {
      VStack(alignment: .leading, spacing: 2) {
        if let title = renderSnapshot.your365HeaderTitle {
          Text(title)
            .font(AppFont.mono(12))
            .foregroundColor(Color("text-tertiary"))
        }
      }
    } else {
      Button(action: onShowYearPicker) {
        Text(yearText)
          .font(AppFont.mono(12))
          .foregroundColor(Color("text-tertiary"))
      }

      Text("•")
        .font(AppFont.mono(4, weight: .black))
        .foregroundColor(Color("text-tertiary"))
        .padding(.horizontal, 2)
    }
  }

  private var reminderLabel: some View {
    HStack(alignment: .center, spacing: 4) {
      if calendar.recurringReminderEnabled,
        let hour = calendar.reminderHour,
        let minute = calendar.reminderMinute {
        let reminderTime = String(format: "%02d:%02d", hour, minute)
        Image(systemName: "bell")
          .font(AppFont.mono(12))
          .foregroundColor(Color("text-tertiary"))
        Text(reminderTime)
          .font(AppFont.mono(12))
          .foregroundColor(Color("text-tertiary"))
      } else {
        Image(systemName: "bell.slash")
          .font(AppFont.mono(12))
          .foregroundColor(Color("text-tertiary"))
        Text("Off")
          .font(AppFont.mono(12))
          .foregroundColor(Color("text-tertiary"))
      }
    }
    .onTapGesture(perform: onNotificationSettings)
  }

  private var showsQuickAddButton: Bool {
    let currentYear = Calendar.current.component(.year, from: Date())
    return (renderSnapshot.isShowingYour365 || selectedYear == currentYear)
      && !calendar.isAppleHealthConnected
  }

  private var quickAddSystemImage: String {
    calendar.trackingType == .binary && isCurrentPeriodCompleted ? "minus" : "plus"
  }
}
