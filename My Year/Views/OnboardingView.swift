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
      PreReviewGateView(
        onPositive: { coordinator.preReviewGateAnswered(.positive) },
        onSkip: { coordinator.preReviewGateAnswered(.negative) }
      )
    case .reviewRequest:
      ReviewRequestView(
        isRequestingReview: coordinator.isRequestingReview,
        onLeaveReview: coordinator.reviewRequestStarted,
        onNotNow: coordinator.reviewRequestSkipped
      )
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
    let snapshot = CustomCalendarStore.shared.snapshot
    let firstDotCalendar = coordinator.resolvedFirstCalendarForView(in: snapshot)
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
}
