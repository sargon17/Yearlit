import Foundation
import SharedModels

struct CustomCalendarMilestonePresentation {
  let milestone: Int
  let currentStreak: Int
  let kind: MilestoneKind
  let dates: [Date]
  let showedUpPeriodKey: String?
}

struct CustomCalendarMilestoneContext {
  let calendar: CustomCalendar
  let currentStreak: Int
  let visibleGridDates: [Date]
  let calendarYearGridDates: [Date]
  let referenceDate: Date
  let policy: MilestoneCelebrationPolicy
}

enum CustomCalendarMilestoneResolver {
  static func presentation(
    for context: CustomCalendarMilestoneContext
  ) -> CustomCalendarMilestonePresentation? {
    if let presentation = streakPresentation(
      calendar: context.calendar,
      currentStreak: context.currentStreak,
      visibleGridDates: context.visibleGridDates,
      policy: context.policy
    ) {
      return presentation
    }

    if context.calendar.cadence == .daily {
      for kind in [ShowedUpMilestoneKind.currentMonth, .currentYear] {
        if let presentation = showedUpPresentation(
          context: ShowedUpPresentationContext(
            calendar: context.calendar,
            currentStreak: context.currentStreak,
            kind: kind,
            dates: dates(
              for: kind,
              referenceDate: context.referenceDate,
              calendarYearGridDates: context.calendarYearGridDates
            ),
            referenceDate: context.referenceDate,
            policy: context.policy
          )
        ) {
          return presentation
        }
      }
    }

    return showedUpPresentation(
      context: ShowedUpPresentationContext(
        calendar: context.calendar,
        currentStreak: context.currentStreak,
        kind: .allTime,
        dates: context.calendarYearGridDates,
        referenceDate: context.referenceDate,
        policy: context.policy
      )
    )
  }

  static func rememberMilestonesSilently(
    for calendar: CustomCalendar,
    replacingEntries entries: [String: CalendarEntry],
    from start: Date,
    through end: Date,
    policy: MilestoneCelebrationPolicy,
    referenceDate: Date = Date()
  ) {
    var syncedCalendar = calendar
    syncedCalendar.entries = calendar.entries.filter { _, entry in
      entry.date < start || entry.date > end
    }
    syncedCalendar.entries.merge(entries) { _, new in new }

    let currentStreak = WidgetStreak.currentStreak(calendar: syncedCalendar).streak
    _ = policy.decisionForStreakMilestone(calendarId: calendar.id, streak: currentStreak)

    if syncedCalendar.cadence == .daily {
      for kind in [ShowedUpMilestoneKind.currentMonth, .currentYear, .allTime] {
        let showedUpCount = ShowedUpMilestones.showedUpCount(
          for: syncedCalendar,
          kind: kind,
          today: referenceDate
        )
        _ = policy.decisionForShowedUpMilestone(
          calendarId: calendar.id,
          showedUpCount: showedUpCount,
          kind: kind,
          periodKey: ShowedUpMilestones.periodKey(for: kind, today: referenceDate)
        )
      }
    }
  }

  private static func streakPresentation(
    calendar: CustomCalendar,
    currentStreak: Int,
    visibleGridDates: [Date],
    policy: MilestoneCelebrationPolicy
  ) -> CustomCalendarMilestonePresentation? {
    guard
      let decision = policy.decisionForStreakMilestone(
        calendarId: calendar.id,
        streak: currentStreak
      ),
      decision.shouldPresent
    else { return nil }

    return CustomCalendarMilestonePresentation(
      milestone: decision.milestone,
      currentStreak: currentStreak,
      kind: .streak,
      dates: visibleGridDates,
      showedUpPeriodKey: nil
    )
  }

  private static func showedUpPresentation(
    context: ShowedUpPresentationContext
  ) -> CustomCalendarMilestonePresentation? {
    let periodKey = ShowedUpMilestones.periodKey(for: context.kind, today: context.referenceDate)
    let showedUpCount = ShowedUpMilestones.showedUpCount(
      for: context.calendar,
      kind: context.kind,
      today: context.referenceDate
    )

    guard
      let decision = context.policy.decisionForShowedUpMilestone(
        calendarId: context.calendar.id,
        showedUpCount: showedUpCount,
        kind: context.kind,
        periodKey: periodKey
      ),
      decision.shouldPresent
    else { return nil }

    return CustomCalendarMilestonePresentation(
      milestone: decision.milestone,
      currentStreak: context.currentStreak,
      kind: milestoneKind(for: context.kind),
      dates: context.dates,
      showedUpPeriodKey: periodKey
    )
  }

  private static func milestoneKind(for kind: ShowedUpMilestoneKind) -> MilestoneKind {
    switch kind {
    case .allTime:
      .showedUp
    case .currentMonth:
      .showedUpMonth
    case .currentYear:
      .showedUpYear
    }
  }

  private static func dates(
    for kind: ShowedUpMilestoneKind,
    referenceDate: Date,
    calendarYearGridDates: [Date]
  ) -> [Date] {
    switch kind {
    case .allTime:
      return calendarYearGridDates
    case .currentMonth:
      let referenceYear = LocalDayCalendar.calendar.component(.year, from: referenceDate)
      return getYearDatesArray(for: referenceYear).filter {
        LocalDayCalendar.calendar.isDate($0, equalTo: referenceDate, toGranularity: .month)
      }
    case .currentYear:
      let referenceYear = LocalDayCalendar.calendar.component(.year, from: referenceDate)
      return getYearDatesArray(for: referenceYear)
    }
  }
}

private struct ShowedUpPresentationContext {
  let calendar: CustomCalendar
  let currentStreak: Int
  let kind: ShowedUpMilestoneKind
  let dates: [Date]
  let referenceDate: Date
  let policy: MilestoneCelebrationPolicy
}
