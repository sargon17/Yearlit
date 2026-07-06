import SharedModels
import SwiftUI

@MainActor
final class OnboardingCoordinator: ObservableObject {
  typealias NotificationPermissionRequester = (@escaping (Result<Bool, Error>) -> Void) -> Void

  @Published private(set) var currentStep: OnboardingStep
  @Published var session: OnboardingSession
  @Published private(set) var isRequestingNotifications = false

  private let onFinish: () -> Void
  private let analytics: OnboardingAnalyticsTracking
  private let notificationRequester: NotificationPermissionRequester
  private var firstDotCalendar: CustomCalendar?
  private var trackedOnboardingActions: Set<OnboardingAction> = []
  private var hasTrackedNotificationPermissionResult = false
  private let onboardingStartedAt = Date()
  private var currentStepStartedAt = Date()

  init(
    onFinish: @escaping () -> Void,
    analytics: OnboardingAnalyticsTracking? = nil,
    notificationRequester: @escaping NotificationPermissionRequester = requestNotificationPermissions
  ) {
    self.onFinish = onFinish
    self.analytics = analytics ?? Analytics.shared
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

  func motivationChanged(_ motivation: OnboardingMotivation) {
    session.selectedMotivation = motivation
    trackOnboardingAction(.motivationSelected)
    analytics.trackOnboardingEvent(
      .onboardingMotivationSelected,
      properties: onboardingProperties().merging([
        "onboarding_motivation": .string(motivation.rawValue)
      ]) { _, new in new }
    )
  }

  func motivationContinueTapped() {
    guard session.selectedMotivation != nil else { return }
    transition(to: .identityCommitment)
  }

  func nameContinueTapped() {
    completeNameStep(didSkip: false)
  }

  func nameSkipped() {
    session.displayName = ""
    completeNameStep(didSkip: true)
  }

  func habitSelectionChanged(_ name: String) {
    session.selectedTinyHabitName = name
  }

  func habitColorChanged(_ color: String) {
    guard session.selectedHabitColor != color else { return }
    session.selectedHabitColor = color
    trackOnboardingAction(.habitColorSelected)
    analytics.trackOnboardingEvent(
      .onboardingHabitColorSelected,
      properties: onboardingProperties().merging([
        "habit_color_id": .string(color)
      ]) { _, new in new }
    )
  }

  func tinyHabitContinueTapped() {
    guard session.selectedTinyHabitName != nil else { return }
    createTinyHabitCalendarIfNeeded()
    trackOnboardingAction(.tinyHabitCreated)
    transition(to: .firstDot)
  }

  func firstDotMarkDayOneTapped() {
    setFirstDotDay(Date(), completed: true)
  }

  func firstDotDayTapped(_ date: Date) {
    let store = CustomCalendarStore.shared
    guard let calendar = resolvedFirstCalendar(in: store.snapshot) else { return }
    let todayBucket = calendar.bucketDate(for: Date())
    let dateBucket = calendar.bucketDate(for: date)
    guard dateBucket <= todayBucket else { return }

    let isCompleted = store.getEntry(calendarId: calendar.id, date: date)?.completed == true
    setFirstDotDay(date, completed: !isCompleted)
  }

  func firstDotContinueTapped() {
    let store = CustomCalendarStore.shared
    guard let calendar = resolvedFirstCalendar(in: store.snapshot) else { return }
    guard session.didCompleteFirstDot || isFirstDotCompletedToday(calendar: calendar) else { return }
    transition(to: .whyThisWorks)
  }

  private func setFirstDotDay(_ date: Date, completed: Bool) {
    let store = CustomCalendarStore.shared
    guard let calendar = resolvedFirstCalendar(in: store.snapshot) else { return }

    if completed {
      let entry = CalendarEntry(date: date, count: 1, completed: true)
      store.addEntry(calendarId: calendar.id, entry: entry)
    } else {
      store.deleteEntry(calendarId: calendar.id, date: date)
    }

    if calendar.bucketDate(for: date) == calendar.bucketDate(for: Date()) {
      session.didCompleteFirstDot = completed
      if completed {
        trackOnboardingAction(.firstDotMarked)
        analytics.markActivationCompleted(
          source: .onboardingFirstDot,
          properties: onboardingProperties().merging([
            "seconds_to_first_dot": .int(secondsSince(onboardingStartedAt)),
            "steps_to_first_dot": .int(stepIndex(for: .firstDot) + 1)
          ]) { _, new in new }
        )
      }
    }

    Task {
      await hapticFeedback(completed ? .success : .light)
    }
  }

  func notificationPermissionRequested() {
    guard !isRequestingNotifications else { return }
    isRequestingNotifications = true
    notificationRequester { [weak self] result in
      Task { @MainActor in
        guard let self else { return }
        self.session.didRequestNotifications = true
        self.isRequestingNotifications = false
        self.trackOnboardingAction(.notificationsRequested)
        self.trackNotificationPermissionResult(Self.notificationResultValue(from: result))
        self.transition(to: .readyWidgets)
      }
    }
  }

  func notificationPermissionSkipped() {
    guard !isRequestingNotifications else { return }
    session.didRequestNotifications = false
    trackOnboardingAction(.notificationsSkipped)
    trackNotificationPermissionResult("skipped")
    transition(to: .readyWidgets)
  }

  func whyThisWorksCompleted() {
    trackOnboardingAction(.whyThisWorksContinued)
    transition(to: .notificationPermission)
  }

  func readyWidgetsCompleted() {
    trackOnboardingAction(.readyContinued)
    transition(to: .founderNote)
  }

  func founderNoteCompleted() {
    trackOnboardingAction(.founderNoteContinued)
    transition(to: .socialProof)
  }

  func socialProofCompleted() {
    trackOnboardingAction(.socialProofContinued)
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
    let calendar = OnboardingFirstCalendarFactory.makeCalendar(
      title: selectedHabit,
      color: session.selectedHabitColor,
      today: Date()
    )

    session.tinyHabitCalendarId = calendar.id
    firstDotCalendar = calendar
    store.addCalendar(calendar)
    CalendarAnalyticsTracker.shared.trackCalendarCreated(
      calendar: calendar,
      isFirstCalendar: true,
      properties: onboardingProperties().merging([
        "source": .string("onboarding"),
        "habit_color_id": .string(session.selectedHabitColor)
      ]) { _, new in new }
    )
  }

  private func resolvedFirstCalendar(in snapshot: CustomCalendarStoreSnapshot) -> CustomCalendar? {
    let sessionCalendarId = session.tinyHabitCalendarId

    if let cachedCalendar = firstDotCalendar, cachedCalendar.id == sessionCalendarId {
      return cachedCalendar
    }

    let activeCalendars = snapshot.activeCalendars

    if let calendarId = sessionCalendarId {
      if let calendar = activeCalendars.first(where: { $0.id == calendarId }) {
        firstDotCalendar = calendar
        return calendar
      }
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
      transition(to: .motivation)
    case .motivation:
      motivationContinueTapped()
    case .identityCommitment:
      guard !session.selectedIdentityCommitments.isEmpty else { return }
      trackOnboardingAction(.identityCompleted)
      transition(to: .name)
    case .name:
      nameContinueTapped()
    case .whyThisWorks:
      whyThisWorksCompleted()
    case .founderNote:
      founderNoteCompleted()
    case .socialProof:
      socialProofCompleted()
    case .tinyHabitSelection:
      tinyHabitContinueTapped()
    case .firstDot:
      break
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
    currentStepStartedAt = Date()
    trackStepView(step)
    trackTrustStepViewIfNeeded(step)
  }

  private func trackStepView(_ step: OnboardingStep) {
    analytics.trackOnboardingStepViewed(stepId: step.rawValue, properties: onboardingProperties(for: step))
  }

  private func trackOnboardingAction(_ action: OnboardingAction) {
    guard trackedOnboardingActions.insert(action).inserted else { return }
    analytics.trackOnboardingAction(action, properties: onboardingProperties())
  }
}

extension OnboardingCoordinator {
  private func completeNameStep(didSkip: Bool) {
    let hasName = session.hasDisplayName && !didSkip
    trackOnboardingAction(hasName ? .nameProvided : .nameSkipped)
    analytics.trackOnboardingEvent(
      .onboardingNameStepCompleted,
      properties: onboardingProperties().merging([
        "name_provided": .bool(hasName),
        "action": .string(hasName ? "continue" : "skip")
      ]) { _, new in new }
    )
    transition(to: .tinyHabitSelection)
  }

  private func trackTrustStepViewIfNeeded(_ step: OnboardingStep) {
    switch step {
    case .whyThisWorks:
      trackTrustStep(.whyThisWorks)
    case .founderNote:
      trackTrustStep(.founderNote)
    case .socialProof:
      trackTrustStep(.socialProof)
    default:
      break
    }
  }

  private func trackTrustStep(_ step: OnboardingTrustStep) {
    var properties = onboardingProperties().merging([
      "trust_step_type": .string(step.rawValue)
    ]) { _, new in new }

    if step == .socialProof {
      properties["social_proof_rating_shown"] = .string(OnboardingCopy.appStoreRating)
    }

    analytics.trackOnboardingEvent(.onboardingTrustStepViewed, properties: properties)
  }

  private func trackNotificationPermissionResult(_ result: String) {
    guard !hasTrackedNotificationPermissionResult else { return }
    hasTrackedNotificationPermissionResult = true

    analytics.trackOnboardingEvent(
      .notificationPermissionResult,
      properties: onboardingProperties().merging([
        "permission_result": .string(result)
      ]) { _, new in new }
    )
  }

  var paywallAnalyticsProperties: [String: AnalyticsPropertyValue] {
    onboardingProperties().merging([
      "founder_note_seen": .bool(true),
      "social_proof_seen": .bool(true),
      "completed_full_pre_paywall_flow": .bool(currentStep == .paywall),
      "seconds_to_paywall": .int(secondsSince(onboardingStartedAt))
    ]) { _, new in new }
  }

  private func onboardingProperties(for step: OnboardingStep? = nil) -> [String: AnalyticsPropertyValue] {
    var properties: [String: AnalyticsPropertyValue] = [
      "onboarding_flow": .string(OnboardingCopy.flowID),
      "total_steps": .int(OnboardingStep.allCases.count),
      "seconds_since_onboarding_start": .int(secondsSince(onboardingStartedAt)),
      "seconds_on_step": .int(secondsSince(currentStepStartedAt))
    ]

    let resolvedStep = step ?? currentStep
    properties["step_index"] = .int(stepIndex(for: resolvedStep))

    if let selectedMotivation = session.selectedMotivation {
      properties["onboarding_motivation"] = .string(selectedMotivation.rawValue)
    }

    return properties
  }

  private func stepIndex(for step: OnboardingStep) -> Int {
    OnboardingStep.allCases.firstIndex(of: step) ?? 0
  }

  private func secondsSince(_ date: Date) -> Int {
    max(0, Int(Date().timeIntervalSince(date).rounded()))
  }

  private static func notificationResultValue(from result: Result<Bool, Error>) -> String {
    switch result {
    case .success(true):
      "granted"
    case .success(false):
      "denied"
    case .failure:
      "error"
    }
  }
}
