import RevenueCat
import SharedModels
import SwiftUI

struct CustomCalendarContentView: View {
  let activeCalendar: CustomCalendar
  let renderSnapshot: CalendarRenderSnapshot
  let yearText: String
  let selectedYear: Int
  let isCurrentPeriodCompleted: Bool
  let quickAddDate: Date?
  let showsDeveloperControls: Bool
  let showsAppleHealthDebugControls: Bool
  let isSyncingAppleHealth: Bool
  let checkInRippleOriginDate: Date?
  let checkInRippleTrigger: Int
  let statsBundle: StatsBundle?
  let currentPeriodLogCount: Int?
  let customerInfo: CustomerInfo?
  let colorScheme: ColorScheme
  let onEdit: () -> Void
  let onFillRandomEntries: () -> Void
  let onQuickAdd: () -> Void
  let onShowYearPicker: () -> Void
  let onNotificationSettings: () -> Void
  let onAppleHealthDebugSync: () -> Void
  let onDayTap: (Date) -> Void
  let onCheckIn: (Date) -> Void
  let onUpgrade: () -> Void
  let onShare: () -> Void

  var body: some View {
    VStack(spacing: 10) {
      CustomCalendarHeaderView(
        calendar: activeCalendar,
        renderSnapshot: renderSnapshot,
        yearText: yearText,
        selectedYear: selectedYear,
        isCurrentPeriodCompleted: isCurrentPeriodCompleted,
        showsDeveloperControls: showsDeveloperControls,
        showsAppleHealthDebugControls: showsAppleHealthDebugControls,
        isSyncingAppleHealth: isSyncingAppleHealth,
        onEdit: onEdit,
        onFillRandomEntries: onFillRandomEntries,
        onQuickAdd: onQuickAdd,
        onShowYearPicker: onShowYearPicker,
        onNotificationSettings: onNotificationSettings,
        onAppleHealthDebugSync: onAppleHealthDebugSync
      )

      GridView(
        handleDayTap: onDayTap,
        mappedDays: renderSnapshot.mappedGridDays,
        disabledDates: renderSnapshot.disabledGridDates,
        rippleOriginDate: checkInRippleOriginDate,
        rippleTrigger: checkInRippleTrigger
      )
      .id(renderSnapshot.timelineMode.rawValue)
      .frame(height: UIScreen.main.bounds.height * 0.62)

      if !activeCalendar.isAppleHealthConnected, let quickAddDate {
        Button {
          onCheckIn(quickAddDate)
        } label: {
          Text("check in")
            .frame(maxWidth: .infinity)
            .fontWeight(.medium)
            .padding(.vertical, 12)
            .padding(.horizontal)
        }
        .sameLevelBorder(radius: 4, isFlat: true)
        .padding(.horizontal)
        .padding(.top, 4)
      }

      if let statsBundle {
        CustomCalendarStatsSection(
          bundle: statsBundle,
          calendar: activeCalendar,
          colorScheme: colorScheme,
          currentPeriodLogCount: currentPeriodLogCount,
          customerInfo: customerInfo,
          onUpgrade: onUpgrade,
          onShare: onShare
        )
      }
    }
    .frame(maxWidth: .infinity, alignment: .top)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
  }
}
