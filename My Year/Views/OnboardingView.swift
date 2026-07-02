import SharedModels
import SwiftUI

private struct OnboardingAccentKey: EnvironmentKey {
  static let defaultValue: Color = .brand
}

extension EnvironmentValues {
  var onboardingAccent: Color {
    get { self[OnboardingAccentKey.self] }
    set { self[OnboardingAccentKey.self] = newValue }
  }
}

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
    .ignoresSafeArea(.container)
    .environment(\.onboardingAccent, Color(coordinator.session.selectedHabitColor))
    .onChange(of: coordinator.currentStep) { _, _ in
      Task {
        await hapticFeedback(.soft)
      }
    }
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
    case .motivation:
      MotivationView(
        selectedMotivation: coordinator.session.selectedMotivation,
        onMotivationSelected: coordinator.motivationChanged,
        onNext: coordinator.motivationContinueTapped
      )
    case .identityCommitment:
      IdentityFirst(
        selectedCommitments: coordinator.session.selectedIdentityCommitments,
        onCommitmentTapped: coordinator.identityCommitmentChanged,
        canContinue: !coordinator.session.selectedIdentityCommitments.isEmpty,
        onNext: coordinator.continueTapped
      )
    case .name:
      NameStepView(
        name: $coordinator.session.displayName,
        onContinue: coordinator.nameContinueTapped,
        onSkip: coordinator.nameSkipped
      )
    case .tinyHabitSelection:
      TinyHabitSelectionView(
        habits: tinyHabitOptions,
        selectedHabit: coordinator.session.selectedTinyHabitName,
        selectedColor: selectedHabitColorBinding,
        onHabitSelected: coordinator.habitSelectionChanged,
        onContinue: coordinator.tinyHabitContinueTapped
      )
    case .firstDot:
      firstDotView
    case .whyThisWorks:
      WhyThisWorksView(onContinue: coordinator.whyThisWorksCompleted)
    case .notificationPermission:
      NotificationPermissionView(
        isRequestingNotifications: coordinator.isRequestingNotifications,
        onTurnOnReminders: coordinator.notificationPermissionRequested,
        onNotNow: coordinator.notificationPermissionSkipped
      )
    case .readyWidgets:
      ReadyWidgetsView(onContinue: coordinator.readyWidgetsCompleted)
    case .founderNote:
      FounderNoteView(
        motivation: coordinator.session.selectedMotivation,
        onContinue: coordinator.founderNoteCompleted
      )
    case .socialProof:
      SocialProofView(
        motivation: coordinator.session.selectedMotivation,
        onContinue: coordinator.socialProofCompleted
      )
    case .paywall:
      OnboardingPaywall(
        motivation: coordinator.session.selectedMotivation,
        analyticsProperties: coordinator.paywallAnalyticsProperties,
        onNext: coordinator.paywallClosed
      )
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
      motivation: coordinator.session.selectedMotivation,
      displayName: firstDotDisplayName,
      onMarkDayOne: coordinator.firstDotMarkDayOneTapped,
      onDayTapped: coordinator.firstDotDayTapped,
      onContinue: coordinator.firstDotContinueTapped
    )
  }

  private var resolvedFirstDotCalendar: CustomCalendar? {
    coordinator.resolvedFirstCalendarForView(in: CustomCalendarStore.shared.snapshot)
  }

  private var selectedHabitColorBinding: Binding<String> {
    Binding(
      get: { coordinator.session.selectedHabitColor },
      set: { coordinator.habitColorChanged($0) }
    )
  }

  private var firstDotDisplayName: String? {
    let name = coordinator.session.trimmedDisplayName
    return name.isEmpty ? nil : name
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
