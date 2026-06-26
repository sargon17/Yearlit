import Garnish
import SharedModels
import SwiftUI

struct FirstDotView: View {
  let calendar: CustomCalendar?
  let isCompletedToday: Bool
  let canMarkDayOne: Bool
  let onMarkDayOne: () -> Void
  let onDayTapped: (Date) -> Void
  let onContinue: () -> Void

  @State private var completedDates: Set<Date> = []
  @State private var rippleTrigger = 0

  private var today: Date {
    Date()
  }

  private var todayBucket: Date? {
    calendar?.bucketDate(for: today)
  }

  private var showingProofState: Bool {
    guard let todayBucket else { return isCompletedToday }
    return isCompletedToday || completedDates.contains(todayBucket)
  }

  var body: some View {
    OnboardingStepContainer {
      if let calendar {
        OnboardingFirstDotCalendarGrid(
          calendar: calendar,
          today: today,
          completedDates: completedDates,
          rippleTrigger: rippleTrigger,
          onDayTapped: toggleDay
        ).background(.surfaceMuted)
      }
    } content: {
      VStack(alignment: .leading, spacing: 8) {
        OnboardingView.Title(showingProofState ? "Proof added." : "Your first dot is waiting.")
        OnboardingView.Caption(showingProofState ? "One day down." : "You chose who you’re becoming.")
        OnboardingView.Caption(
          showingProofState ? "Keep the promise tomorrow." : "Mark today as the first proof.")
      }
    } actions: {
      if showingProofState {
        OnboardingView.ForwardButton(title: "Continue", onTap: onContinue)
      } else {
        OnboardingView.ForwardButton(
          title: "Mark Day 1",
          onTap: markToday,
          style: !canMarkDayOne || calendar == nil ? .disabled : .primary
        )
      }
    }
    .onChange(of: isCompletedToday) { _, _ in
      syncCompletedDatesFromCalendar()
    }
    .onAppear {
      syncCompletedDatesFromCalendar()
    }
  }

  private func markToday() {
    guard let todayBucket else { return }
    completedDates.insert(todayBucket)
    triggerRippleFeedback()
    onMarkDayOne()
  }

  private func toggleDay(_ date: Date) {
    guard let calendar else { return }
    let bucketDate = calendar.bucketDate(for: date)

    if completedDates.contains(bucketDate) {
      completedDates.remove(bucketDate)
    } else {
      completedDates.insert(bucketDate)
      if bucketDate == todayBucket {
        triggerRippleFeedback()
      }
    }

    onDayTapped(date)
  }

  private func triggerRippleFeedback() {
    rippleTrigger += 1

    Task {
      await checkInRippleHapticFeedback()
    }
  }

  private func syncCompletedDatesFromCalendar() {
    guard let calendar else {
      completedDates = []
      return
    }

    completedDates = Set(
      calendar.entries.values.compactMap { entry in
        entry.completed ? calendar.bucketDate(for: entry.date) : nil
      }
    )

    if isCompletedToday, let todayBucket {
      completedDates.insert(todayBucket)
    }
  }
}
