import Garnish
import SharedModels
import SwiftUI

struct ReviewRequestView: View {
  let calendar: CustomCalendar?
  let completedDates: Set<Date>
  let isRequestingReview: Bool
  let onLeaveReview: () -> Void
  let onNotNow: () -> Void

  private var today: Date {
    Date()
  }

  var body: some View {
    OnboardingStepContainer {
      if let calendar {
        OnboardingFirstDotCalendarGrid(
          calendar: calendar,
          today: today,
          completedDates: completedDates,
          allowsPastAndTodayTaps: false
        )
        .background(.surfaceMuted)
      }
    } content: {
      VStack(alignment: .leading) {
        OnboardingView.Title("A small favor?")
        OnboardingView.Caption("I’m building Yearlit solo.")
        OnboardingView.Caption("If this helps you keep a promise to yourself, your review helps me keep building it.")
        OnboardingView.Caption("No pressure you can always do it later.")
      }
    } actions: {
      VStack(spacing: 2) {
        OnboardingView.ForwardButton(
          title: isRequestingReview ? "Opening…" : "Leave a review",
          onTap: onLeaveReview,
          style: isRequestingReview ? .disabled : .primary
        )
        OnboardingView.ForwardButton(
          title: "Not now",
          onTap: onNotNow,
          style: isRequestingReview ? .disabled : .secondary)
      }
    }
  }
}
