import SharedModels
import SwiftUI

extension CalendarShareSheet {
  var your365Snapshot: Your365Snapshot? {
    guard calendar.cadence == .daily else { return nil }
    return calendar.makeYour365Snapshot(
      completedDates: your365CompletedDates(for: calendar),
      today: Date()
    )
  }

  var resolvedStats: CalendarStats {
    statsBundle?.basic ?? computeFallbackStats(for: calendar)
  }

  var resolvedCompletionRateTrailingLongWindow: Double {
    statsBundle?.completionRateTrailingLongWindow ?? 0
  }

  var resolvedAverageProgressTrailingShortWindow: Double {
    statsBundle?.averageProgressTrailingShortWindow ?? 0
  }

  var resolvedAverageProgressTrailingLongWindow: Double {
    statsBundle?.averageProgressTrailingLongWindow ?? 0
  }

  var resolvedBestWeekday: Int? {
    statsBundle?.bestWeekday
  }

  var cardData: ShareCardData {
    ShareCardData(
      calendar: calendar,
      year: year,
      dates: dates,
      your365Snapshot: your365Snapshot,
      isYour365FirstYear: calendar.isWithinFirstYear(today: Date()),
      stats: resolvedStats,
      completionRateTrailingLongWindow: resolvedCompletionRateTrailingLongWindow,
      averageProgressTrailingShortWindow: resolvedAverageProgressTrailingShortWindow,
      averageProgressTrailingLongWindow: resolvedAverageProgressTrailingLongWindow,
      bestWeekday: resolvedBestWeekday,
      currentPeriodCount: resolvedCurrentPeriodCount,
      trackingType: calendar.trackingType
    )
  }

  @ViewBuilder
  func cardView(for template: CalendarShareTemplate) -> some View {
    if template.isPremiumOnly && !isPremium {
      unlockedCardView(for: template)
        .blur(radius: 12)
        .overlay(premiumOverlay)
    } else {
      unlockedCardView(for: template)
    }
  }

  @ViewBuilder
  func unlockedCardView(for template: CalendarShareTemplate) -> some View {
    switch template {
    case .yearCard:
      YearCardShareView(
        calendar: calendar,
        year: year,
        dates: dates,
        stats: resolvedStats,
        completionRateTrailingLongWindow: resolvedCompletionRateTrailingLongWindow,
        currentPeriodCount: resolvedCurrentPeriodCount,
        trackingType: calendar.trackingType
      )
    case .minimalGrid:
      MinimalGridShareView(data: cardData)
    case .streakFocus:
      StreakFocusShareView(data: cardData)
    case .performance:
      PerformanceShareView(data: cardData)
    case .your365:
      Your365ShareView(data: cardData)
    }
  }

  var premiumOverlay: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Color.black.opacity(0.25))
      VStack(spacing: 8) {
        Image(systemName: "lock.fill")
          .font(.system(size: 20))
          .foregroundColor(.textPrimary)
        Text("Premium")
          .font(AppFont.mono(14))
          .foregroundColor(.textPrimary)
      }
    }
  }

  func computeFallbackStats(for calendar: CustomCalendar) -> CalendarStats {
    let activeDays = calendar.entries.values.filter { entry in
      switch calendar.trackingType {
      case .binary:
        return entry.completed
      case .counter, .multipleDaily:
        return entry.hasLoggedCount
      }
    }.count

    let totalCount = calendar.entries.values.reduce(0) { $0 + $1.count }
    let maxCount = calendar.entries.values.map { $0.count }.max() ?? 0

    let localCalendar = LocalDayCalendar.calendar
    let longestStreak = WidgetStreak.longestStreak(calendar: calendar, calendarSystem: localCalendar)
    let currentStreak = WidgetStreak
      .currentStreak(calendar: calendar, today: Date(), calendarSystem: localCalendar)
      .streak

    return CalendarStats(
      activeDays: activeDays,
      totalCount: totalCount,
      maxCount: maxCount,
      longestStreak: longestStreak,
      currentStreak: currentStreak
    )
  }

  var resolvedCurrentPeriodCount: Int {
    let currentYear = Calendar.current.component(.year, from: Date())
    guard year == currentYear else { return 0 }
    let today = Calendar.current.startOfDay(for: Date())
    return entry(for: calendar, date: today)?.count ?? 0
  }
}
