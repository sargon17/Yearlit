import SharedModels
import SwiftUI

@MainActor
final class OnboardingCoordinator: ObservableObject {
  @Published private(set) var currentStep: OnboardingStep
  @Published var session: OnboardingSession
  @Published private(set) var isRequestingReview = false
  @Published private(set) var isRequestingNotifications = false

  private let onFinish: () -> Void
  private let analytics: OnboardingAnalyticsTracking
  private let reviewRequester: @MainActor () -> Void
  private let reviewPromptDelayNanoseconds: UInt64
  private let notificationRequester: (@escaping (Result<Bool, Error>) -> Void) -> Void
  private var firstDotCalendar: CustomCalendar?
  private var reviewRequestTask: Task<Void, Never>?
  private var trackedOnboardingActions: Set<OnboardingAction> = []

  init(
    onFinish: @escaping () -> Void,
    analytics: OnboardingAnalyticsTracking = Analytics.shared,
    reviewRequester: @escaping @MainActor () -> Void = { ReviewPrompter.shared.requestReviewNow() },
    reviewPromptDelayNanoseconds: UInt64 = 1_500_000_000,
    notificationRequester: @escaping (@escaping (Result<Bool, Error>) -> Void) -> Void = requestNotificationPermissions
  ) {
    self.onFinish = onFinish
    self.analytics = analytics
    self.reviewRequester = reviewRequester
    self.reviewPromptDelayNanoseconds = reviewPromptDelayNanoseconds
    self.notificationRequester = notificationRequester
    currentStep = .emotionalHook
    session = OnboardingSession()
    trackStepView(.emotionalHook)
  }

  func continueTapped() {
    route(from: currentStep)
  }

  func identityCommitmentChanged(_ commitment: IdentityCommitment) {
    session.toggleIdentityCommitment(commitment)
    session.selectedTinyHabitName = nil
  }

  func habitSelectionChanged(_ name: String) {
    session.selectedTinyHabitName = name
  }

  func tinyHabitContinueTapped() {
    guard session.selectedTinyHabitName != nil else { return }
    createTinyHabitCalendarIfNeeded()
    trackOnboardingAction(.tinyHabitCreated)
    transition(to: .firstDot)
  }

  func firstDotMarkDayOneTapped() {
    let store = CustomCalendarStore.shared
    guard let calendar = resolvedFirstCalendar(in: store.snapshot) else { return }
    let today = Date()
    let existingEntry = store.getEntry(calendarId: calendar.id, date: today)
    guard existingEntry?.completed != true else {
      session.didCompleteFirstDot = true
      trackOnboardingAction(.firstDotMarked)
      return
    }

    let entry = CalendarEntry(date: today, count: 1, completed: true)
    store.addEntry(calendarId: calendar.id, entry: entry)
    session.didCompleteFirstDot = true
    trackOnboardingAction(.firstDotMarked)
    Task {
      await hapticFeedback(.success)
    }
  }

  func firstDotContinueTapped() {
    transition(to: .preReviewGate)
  }

  func preReviewGateAnswered(_ answer: PreReviewGateAnswer?) {
    session.preReviewGateWasPositive = answer?.isPositive == true
    transition(to: session.preReviewGateWasPositive ? .reviewRequest : .notificationPermission)
  }

  func reviewRequestStarted() {
    guard !isRequestingReview else { return }
    isRequestingReview = true
    reviewRequestTask?.cancel()
    reviewRequestTask = Task { @MainActor [weak self] in
      guard let self else { return }
      self.reviewRequester()
      if self.reviewPromptDelayNanoseconds > 0 {
        try? await Task.sleep(nanoseconds: self.reviewPromptDelayNanoseconds)
      }
      guard !Task.isCancelled else { return }
      self.reviewRequestAnswered()
    }
  }

  func reviewRequestAnswered() {
    reviewRequestTask?.cancel()
    reviewRequestTask = nil
    isRequestingReview = false
    session.didRequestReview = true
    trackOnboardingAction(.reviewRequested)
    addPositiveEvent(.completedOnboarding)
    transition(to: .notificationPermission)
  }

  func notificationPermissionRequested() {
    guard !isRequestingNotifications else { return }
    isRequestingNotifications = true
    notificationRequester { [weak self] _ in
      Task { @MainActor in
        guard let self else { return }
        self.session.didRequestNotifications = true
        self.isRequestingNotifications = false
        self.trackOnboardingAction(.notificationsRequested)
        self.transition(to: .readyWidgets)
      }
    }
  }

  func notificationPermissionSkipped() {
    guard !isRequestingNotifications else { return }
    session.didRequestNotifications = false
    trackOnboardingAction(.notificationsSkipped)
    transition(to: .readyWidgets)
  }

  func reviewRequestSkipped() {
    reviewRequestTask?.cancel()
    reviewRequestTask = nil
    isRequestingReview = false
    session.didRequestReview = false
    trackOnboardingAction(.reviewSkipped)
    transition(to: .notificationPermission)
  }

  func readyWidgetsCompleted() {
    trackOnboardingAction(.readyContinued)
    trackOnboardingAction(.paywallBoundaryReached)
    transition(to: .paywall)
  }

  func paywallClosed() {
    trackOnboardingAction(.paywallClosed)
    onFinish()
  }

  private func createTinyHabitCalendarIfNeeded() {
    guard session.tinyHabitCalendarId == nil else { return }
    guard let selectedHabit = session.selectedTinyHabitName else { return }

    let store = CustomCalendarStore.shared
    let activeCalendars = store.snapshot.activeCalendars
    if let existingCalendar = activeCalendars.first {
      session.tinyHabitCalendarId = existingCalendar.id
      firstDotCalendar = existingCalendar
      return
    }

    let calendar = OnboardingFirstCalendarFactory.makeCalendar(title: selectedHabit, today: Date())

    session.tinyHabitCalendarId = calendar.id
    firstDotCalendar = calendar
    store.addCalendar(calendar)
    CalendarAnalyticsTracker.shared.trackCalendarCreated(
      calendar: calendar,
      isFirstCalendar: true
    )
  }

  private func resolvedFirstCalendar(in snapshot: CustomCalendarStoreSnapshot) -> CustomCalendar? {
    if let cachedCalendar = firstDotCalendar,
      let calendarId = session.tinyHabitCalendarId,
      cachedCalendar.id == calendarId
    {
      return cachedCalendar
    }

    let activeCalendars = snapshot.activeCalendars

    if let calendarId = session.tinyHabitCalendarId,
      let calendar = activeCalendars.first(where: { $0.id == calendarId })
    {
      firstDotCalendar = calendar
      return calendar
    }

    guard let fallbackCalendar = activeCalendars.first else {
      return nil
    }

    session.tinyHabitCalendarId = fallbackCalendar.id
    firstDotCalendar = fallbackCalendar
    return fallbackCalendar
  }

  func resolvedFirstCalendarForView(in snapshot: CustomCalendarStoreSnapshot) -> CustomCalendar? {
    resolvedFirstCalendar(in: snapshot)
  }

  func isFirstDotCompletedToday(calendar: CustomCalendar?, date: Date = Date()) -> Bool {
    guard let calendar else { return false }
    return calendar.entry(for: date)?.completed == true
  }

  private func route(from step: OnboardingStep) {
    switch step {
    case .emotionalHook:
      transition(to: .appExplanation)
    case .appExplanation:
      transition(to: .identityCommitment)
    case .identityCommitment:
      guard !session.selectedIdentityCommitments.isEmpty else { return }
      trackOnboardingAction(.identityCompleted)
      transition(to: .tinyHabitSelection)
    case .tinyHabitSelection:
      tinyHabitContinueTapped()
    case .firstDot:
      break
    case .preReviewGate:
      transition(to: session.preReviewGateWasPositive ? .reviewRequest : .notificationPermission)
    case .reviewRequest:
      reviewRequestStarted()
    case .notificationPermission:
      notificationPermissionRequested()
    case .readyWidgets:
      readyWidgetsCompleted()
    case .paywall:
      paywallClosed()
    }
  }

  private func transition(to step: OnboardingStep) {
    guard currentStep != step else { return }
    currentStep = step
    trackStepView(step)
  }

  private func trackStepView(_ step: OnboardingStep) {
    analytics.trackOnboardingStepViewed(stepId: step.rawValue)
  }

  private func trackOnboardingAction(_ action: OnboardingAction) {
    guard trackedOnboardingActions.insert(action).inserted else { return }
    analytics.trackOnboardingAction(action)
  }
}
