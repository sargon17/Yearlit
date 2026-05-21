import SharedModels
import SwiftUI

struct OnboardingView: View {
  @StateObject private var coordinator: OnboardingCoordinator

  init(onDone: @escaping () -> Void) {
    _coordinator = StateObject(wrappedValue: OnboardingCoordinator(onFinish: onDone))
  }

  var body: some View {
    ZStack {
      Color(.systemGroupedBackground)
        .ignoresSafeArea()

      stepView(for: coordinator.currentStep)
    }
    .ignoresSafeArea()
  }

  @ViewBuilder
  private func stepView(for step: OnboardingStep) -> some View {
    switch step {
    case .emotionalHook:
      EmotionalHook(
        onNext: coordinator.continueTapped
      )
    case .appExplanation:
      AppPreview(onNext: coordinator.continueTapped)
    case .identityCommitment:
      IdentityFirst(
        selectedCommitments: coordinator.session.selectedIdentityCommitments,
        onCommitmentTapped: coordinator.identityCommitmentChanged,
        canContinue: !coordinator.session.selectedIdentityCommitments.isEmpty,
        onNext: coordinator.continueTapped
      )
    case .tinyHabitSelection:
      TinyHabitSelectionView(
        habits: tinyHabitOptions,
        selectedHabit: coordinator.session.selectedTinyHabitName,
        onHabitSelected: coordinator.habitSelectionChanged,
        onContinue: coordinator.tinyHabitContinueTapped
      )
    case .firstDot:
      firstDotView
    case .preReviewGate:
      preReviewGateView
    case .reviewRequest:
      reviewRequestView
    case .notificationPermission:
      NotificationPermissionView(
        isRequestingNotifications: coordinator.isRequestingNotifications,
        onTurnOnReminders: coordinator.notificationPermissionRequested,
        onNotNow: coordinator.notificationPermissionSkipped
      )
    case .readyWidgets:
      ReadyWidgetsView(onContinue: coordinator.readyWidgetsCompleted)
    case .paywall:
      OnboardingPaywall(onNext: coordinator.paywallClosed)
    }
  }

  private var tinyHabitOptions: [String] {
    coordinator.session.selectedIdentityCommitments.last.map {
      OnboardingHabitCatalog.habits(for: $0)
    } ?? []
  }

  private var firstDotView: some View {
    let firstDotCalendar = resolvedFirstDotCalendar
    let isCompletedToday = coordinator.isFirstDotCompletedToday(calendar: firstDotCalendar)

    return FirstDotView(
      calendar: firstDotCalendar,
      isCompletedToday: isCompletedToday || coordinator.session.didCompleteFirstDot,
      canMarkDayOne: firstDotCalendar != nil && !coordinator.session.didCompleteFirstDot,
      onMarkDayOne: coordinator.firstDotMarkDayOneTapped,
      onDayTapped: coordinator.firstDotDayTapped,
      onContinue: coordinator.firstDotContinueTapped
    )
  }

  private var preReviewGateView: some View {
    let firstDotCalendar = resolvedFirstDotCalendar

    return PreReviewGateView(
      calendar: firstDotCalendar,
      completedDates: completedDates(in: firstDotCalendar),
      onPositive: { coordinator.preReviewGateAnswered(.positive) },
      onSkip: { coordinator.preReviewGateAnswered(.negative) }
    )
  }

  private var reviewRequestView: some View {
    let firstDotCalendar = resolvedFirstDotCalendar

    return ReviewRequestView(
      calendar: firstDotCalendar,
      completedDates: completedDates(in: firstDotCalendar),
      isRequestingReview: coordinator.isRequestingReview,
      onLeaveReview: coordinator.reviewRequestStarted,
      onNotNow: coordinator.reviewRequestSkipped
    )
  }

  private var resolvedFirstDotCalendar: CustomCalendar? {
    coordinator.resolvedFirstCalendarForView(in: CustomCalendarStore.shared.snapshot)
  }

  private func completedDates(in calendar: CustomCalendar?) -> Set<Date> {
    guard let calendar else { return [] }

    var dates = Set(
      calendar.entries.values.compactMap { entry in
        entry.completed ? calendar.bucketDate(for: entry.date) : nil
      }
    )

    if coordinator.session.didCompleteFirstDot {
      dates.insert(calendar.bucketDate(for: Date()))
    }

    return dates
  }
}
