import Foundation
import SharedModels

struct MilestoneCelebration {
  let calendar: CustomCalendar
  let milestone: Int
  let currentStreak: Int
  let kind: MilestoneKind
  let dates: [Date]
  let isPreview: Bool
}

struct MilestoneCelebrationService {
  func celebrationIfNeeded(
    calendar: CustomCalendar,
    calendarId: UUID,
    gridDates: [Date],
    referenceDate: Date = Date()
  ) -> MilestoneCelebration? {
    let currentStreak = currentStreak(for: calendar)

    if let milestone = StreakMilestoneTracker.shared.milestoneToCelebrate(
      calendarId: calendarId,
      streak: currentStreak
    ) {
      StreakMilestoneTracker.shared.markCelebrated(calendarId: calendarId, milestone: milestone)
      return MilestoneCelebration(
        calendar: calendar,
        milestone: milestone,
        currentStreak: currentStreak,
        kind: .streak,
        dates: gridDates,
        isPreview: false
      )
    }

    if calendar.cadence == .daily {
      for kind in [ShowedUpMilestoneKind.currentMonth, .currentYear] {
        if let celebration = showedUpCelebrationIfNeeded(
          calendar: calendar,
          calendarId: calendarId,
          currentStreak: currentStreak,
          kind: kind,
          referenceDate: referenceDate,
          gridDates: gridDates
        ) {
          return celebration
        }
      }
    }

    return showedUpCelebrationIfNeeded(
      calendar: calendar,
      calendarId: calendarId,
      currentStreak: currentStreak,
      kind: .allTime,
      referenceDate: referenceDate,
      gridDates: gridDates
    )
  }

  func debugPreview(
    kind: MilestoneKind,
    calendar: CustomCalendar,
    gridDates: [Date],
    referenceDate: Date = Date()
  ) -> MilestoneCelebration? {
    let milestone: Int?
    let dates: [Date]

    switch kind {
    case .streak:
      milestone = StreakMilestones.nextMilestone(after: currentStreak(for: calendar))
      dates = gridDates
    case .showedUp:
      milestone = ShowedUpMilestones.nextMilestone(
        after: ShowedUpMilestones.showedUpCount(for: calendar, kind: .allTime, today: referenceDate),
        kind: .allTime
      )
      dates = milestoneDates(for: .allTime, gridDates: gridDates, referenceDate: referenceDate)
    case .showedUpMonth:
      milestone = ShowedUpMilestones.nextMilestone(
        after: ShowedUpMilestones.showedUpCount(for: calendar, kind: .currentMonth, today: referenceDate),
        kind: .currentMonth
      )
      dates = milestoneDates(for: .currentMonth, gridDates: gridDates, referenceDate: referenceDate)
    case .showedUpYear:
      milestone = ShowedUpMilestones.nextMilestone(
        after: ShowedUpMilestones.showedUpCount(for: calendar, kind: .currentYear, today: referenceDate),
        kind: .currentYear
      )
      dates = milestoneDates(for: .currentYear, gridDates: gridDates, referenceDate: referenceDate)
    }

    guard let milestone else { return nil }
    return MilestoneCelebration(
      calendar: calendar,
      milestone: milestone,
      currentStreak: currentStreak(for: calendar),
      kind: kind,
      dates: dates,
      isPreview: true
    )
  }

  func currentStreak(for calendar: CustomCalendar) -> Int {
    WidgetStreak.currentStreak(calendar: calendar).streak
  }

  func showedUpCount(for calendar: CustomCalendar) -> Int {
    ShowedUpMilestones.showedUpCount(for: calendar, kind: .allTime)
  }

  private func showedUpCelebrationIfNeeded(
    calendar: CustomCalendar,
    calendarId: UUID,
    currentStreak: Int,
    kind: ShowedUpMilestoneKind,
    referenceDate: Date,
    gridDates: [Date]
  ) -> MilestoneCelebration? {
    let periodKey = ShowedUpMilestones.periodKey(for: kind, today: referenceDate)
    let showedUpCount = ShowedUpMilestones.showedUpCount(for: calendar, kind: kind, today: referenceDate)

    guard
      let milestone = ShowedUpMilestoneTracker.shared.milestoneToCelebrate(
        calendarId: calendarId,
        showedUpCount: showedUpCount,
        kind: kind,
        periodKey: periodKey
      )
    else { return nil }

    ShowedUpMilestoneTracker.shared.markCelebrated(
      calendarId: calendarId,
      milestone: milestone,
      kind: kind,
      periodKey: periodKey
    )

    return MilestoneCelebration(
      calendar: calendar,
      milestone: milestone,
      currentStreak: currentStreak,
      kind: milestoneKind(for: kind),
      dates: milestoneDates(for: kind, gridDates: gridDates, referenceDate: referenceDate),
      isPreview: false
    )
  }

  private func milestoneKind(for kind: ShowedUpMilestoneKind) -> MilestoneKind {
    switch kind {
    case .allTime:
      .showedUp
    case .currentMonth:
      .showedUpMonth
    case .currentYear:
      .showedUpYear
    }
  }

  private func milestoneDates(for kind: ShowedUpMilestoneKind, gridDates: [Date], referenceDate: Date) -> [Date] {
    switch kind {
    case .allTime:
      return gridDates
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
