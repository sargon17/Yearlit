import Foundation
import SharedModels
import Testing

@testable import My_Year

@MainActor
struct OnboardingSessionTests {
  @Test func togglingIdentityCommitmentsPreservesOrder() {
    var session = OnboardingSession()

    session.toggleIdentityCommitment(.strengthTrainer)
    session.toggleIdentityCommitment(.reader)
    session.toggleIdentityCommitment(.strengthTrainer)
    session.toggleIdentityCommitment(.strengthTrainer)

    #expect(session.selectedIdentityCommitments == [.reader, .strengthTrainer])
  }

  @Test func coordinatorClearsTinyHabitWhenIdentityChanges() {
    let coordinator = OnboardingCoordinator(onFinish: {})

    coordinator.habitSelectionChanged("Read 2 pages")
    coordinator.identityCommitmentChanged(.reader)

    #expect(coordinator.session.selectedTinyHabitName == nil)
    #expect(coordinator.session.selectedIdentityCommitments == [.reader])
  }

  @Test func identitySelectionIsRequiredBeforeContinuing() {
    let coordinator = OnboardingCoordinator(onFinish: {})

    coordinator.continueTapped()
    coordinator.continueTapped()
    #expect(coordinator.currentStep == .motivation)

    coordinator.continueTapped()
    #expect(coordinator.currentStep == .motivation)

    coordinator.motivationChanged(.discipline)
    coordinator.continueTapped()
    #expect(coordinator.currentStep == .identityCommitment)

    coordinator.continueTapped()
    #expect(coordinator.currentStep == .identityCommitment)
  }

  @Test func tinyHabitStepDoesNotAdvanceWithoutSelection() {
    let coordinator = OnboardingCoordinator(onFinish: {})

    coordinator.continueTapped()
    coordinator.continueTapped()
    coordinator.motivationChanged(.discipline)
    coordinator.continueTapped()
    coordinator.identityCommitmentChanged(.strengthTrainer)
    coordinator.continueTapped()
    coordinator.nameSkipped()
    coordinator.tinyHabitContinueTapped()

    #expect(coordinator.currentStep == .tinyHabitSelection)
  }

  @Test func firstDotResolverAdoptsExistingActiveCalendarWhenSessionIdIsMissing() {
    let coordinator = OnboardingCoordinator(onFinish: {})
    let calendar = makeCalendar(name: "Read 2 pages")
    let snapshot = CustomCalendarStoreSnapshot(calendars: [calendar])

    let resolved = coordinator.resolvedFirstCalendarForView(in: snapshot)

    #expect(resolved?.id == calendar.id)
    #expect(coordinator.session.tinyHabitCalendarId == calendar.id)
  }

  @Test func firstDotResolverIgnoresArchivedSessionCalendarAndFallsBackToActiveOne() {
    let coordinator = OnboardingCoordinator(onFinish: {})
    let archivedCalendar = makeCalendar(name: "Archived", isArchived: true)
    let activeCalendar = makeCalendar(name: "Active")
    coordinator.session.tinyHabitCalendarId = archivedCalendar.id
    let snapshot = CustomCalendarStoreSnapshot(calendars: [archivedCalendar, activeCalendar])

    let resolved = coordinator.resolvedFirstCalendarForView(in: snapshot)

    #expect(resolved?.id == activeCalendar.id)
    #expect(coordinator.session.tinyHabitCalendarId == activeCalendar.id)
  }

  @Test func firstDotResolverReportsCompletedStateFromTodayEntry() {
    let coordinator = OnboardingCoordinator(onFinish: {})
    let today = Date()
    let calendar = makeCalendar(
      name: "Read 2 pages",
      entries: [
        DayKeyFormatter.shared.string(from: today): CalendarEntry(date: today, count: 1, completed: true)
      ]
    )

    #expect(coordinator.isFirstDotCompletedToday(calendar: calendar, date: today))
  }

  @Test func firstDotMarkDayOneIsIdempotentForCompletedEntries() {
    let coordinator = OnboardingCoordinator(onFinish: {})
    let store = CustomCalendarStore.shared
    let today = Date()

    coordinator.continueTapped()
    coordinator.continueTapped()
    coordinator.motivationChanged(.visibleProgress)
    coordinator.continueTapped()
    coordinator.identityCommitmentChanged(.reader)
    coordinator.continueTapped()
    coordinator.nameSkipped()
    coordinator.habitSelectionChanged("Read 2 pages")
    coordinator.tinyHabitContinueTapped()

    let calendarID = coordinator.session.tinyHabitCalendarId
    defer {
      if let calendarID {
        store.deleteCalendar(id: calendarID)
      }
    }

    coordinator.firstDotMarkDayOneTapped()
    coordinator.firstDotMarkDayOneTapped()

    let entry = calendarID.flatMap { store.getEntry(calendarId: $0, date: today) }
    #expect(entry?.count == 1)
    #expect(entry?.completed == true)
  }

  @Test func firstDotMarkDayOneSetsLocalCompletionState() {
    let coordinator = OnboardingCoordinator(onFinish: {})
    let store = CustomCalendarStore.shared
    let calendar = makeCalendar(name: "Read 2 pages")

    store.addCalendar(calendar)
    defer {
      store.deleteCalendar(id: calendar.id)
    }

    coordinator.session.tinyHabitCalendarId = calendar.id

    coordinator.firstDotMarkDayOneTapped()

    #expect(coordinator.session.didCompleteFirstDot)
  }

  @Test func firstDotCreatePathKeepsCalendarResolvableBeforeStoreRefresh() {
    let coordinator = OnboardingCoordinator(onFinish: {})
    let store = CustomCalendarStore.shared
    let originalCalendars = store.snapshot.activeCalendars

    for calendar in originalCalendars {
      store.deleteCalendar(id: calendar.id)
    }
    defer {
      for calendar in originalCalendars {
        store.addCalendar(calendar)
      }
    }

    coordinator.continueTapped()
    coordinator.continueTapped()
    coordinator.motivationChanged(.visibleProgress)
    coordinator.continueTapped()
    coordinator.identityCommitmentChanged(.reader)
    coordinator.continueTapped()
    coordinator.nameSkipped()
    coordinator.habitSelectionChanged("Read 2 pages")
    coordinator.tinyHabitContinueTapped()

    let resolved = coordinator.resolvedFirstCalendarForView(in: store.snapshot)

    #expect(coordinator.currentStep == .firstDot)
    #expect(coordinator.session.tinyHabitCalendarId != nil)
    #expect(resolved?.id == coordinator.session.tinyHabitCalendarId)
  }

  @Test func notificationSkipAdvancesWithoutRecordingDecline() {
    let coordinator = OnboardingCoordinator(onFinish: {})

    coordinator.notificationPermissionSkipped()

    #expect(!coordinator.session.didRequestNotifications)
    #expect(coordinator.currentStep == .readyWidgets)
  }

  @Test func notificationRequestTracksOnceAfterAsyncCallbackAdvancesFlow() async {
    let analytics = SpyAnalytics()
    let requester = NotificationRequesterStub()
    let coordinator = OnboardingCoordinator(
      onFinish: {},
      analytics: analytics,
      notificationRequester: requester.request
    )

    coordinator.notificationPermissionRequested()
    coordinator.notificationPermissionRequested()

    #expect(coordinator.isRequestingNotifications)
    #expect(requester.requestCount == 1)

    requester.complete(.success(true))
    await Task.yield()

    #expect(!coordinator.isRequestingNotifications)
    #expect(coordinator.session.didRequestNotifications)
    #expect(coordinator.currentStep == .readyWidgets)
    #expect(analytics.actions == [.notificationsRequested])
    #expect(
      analytics.events.map(\.event) == [
        .onboardingStepViewed,
        .onboardingActionPerformed,
        .notificationPermissionResult,
        .onboardingStepViewed
      ])

    requester.complete(.success(true))
    await Task.yield()

    #expect(requester.requestCount == 1)
    #expect(analytics.actions == [.notificationsRequested])
    #expect(coordinator.currentStep == .readyWidgets)
  }

  @Test func readyWidgetsAdvancesToFounderNote() {
    let coordinator = OnboardingCoordinator(onFinish: {})

    coordinator.readyWidgetsCompleted()

    #expect(coordinator.currentStep == .founderNote)
  }

  @Test func paywallClosedFiresFinishOnlyFromBoundary() {
    var didFinish = false
    let coordinator = OnboardingCoordinator(onFinish: {
      didFinish = true
    })

    coordinator.readyWidgetsCompleted()
    coordinator.founderNoteCompleted()
    coordinator.socialProofCompleted()

    #expect(!didFinish)

    coordinator.paywallClosed()

    #expect(didFinish)
  }

  @Test func onboardingCoordinatorTracksLifecycleStepsAndKeyActionsOnce() {
    let analytics = SpyAnalytics()
    var didFinish = false
    let coordinator = OnboardingCoordinator(
      onFinish: {
        didFinish = true
      }, analytics: analytics)

    #expect(analytics.events.count == 1)
    #expect(analytics.events.first?.event == .onboardingStepViewed)
    #expect(analytics.events.first?.properties["step_id"] == .string(OnboardingStep.emotionalHook.rawValue))

    coordinator.continueTapped()
    coordinator.continueTapped()
    coordinator.motivationChanged(.selfPromise)
    coordinator.continueTapped()
    coordinator.identityCommitmentChanged(.reader)
    coordinator.continueTapped()
    coordinator.nameSkipped()
    coordinator.habitSelectionChanged("Read 2 pages")
    coordinator.habitColorChanged("qs-blue")
    coordinator.tinyHabitContinueTapped()
    coordinator.firstDotMarkDayOneTapped()
    coordinator.firstDotMarkDayOneTapped()
    coordinator.firstDotContinueTapped()
    coordinator.whyThisWorksCompleted()
    coordinator.notificationPermissionSkipped()
    coordinator.notificationPermissionSkipped()
    coordinator.readyWidgetsCompleted()
    coordinator.readyWidgetsCompleted()
    coordinator.founderNoteCompleted()
    coordinator.socialProofCompleted()
    coordinator.paywallClosed()
    coordinator.paywallClosed()

    #expect(didFinish)
    #expect(
      analytics.events.map(\.event) == [
        .onboardingStepViewed,
        .onboardingStepViewed,
        .onboardingStepViewed,
        .onboardingActionPerformed,
        .onboardingMotivationSelected,
        .onboardingStepViewed,
        .onboardingActionPerformed,
        .onboardingStepViewed,
        .onboardingActionPerformed,
        .onboardingNameStepCompleted,
        .onboardingStepViewed,
        .onboardingActionPerformed,
        .onboardingHabitColorSelected,
        .onboardingActionPerformed,
        .onboardingStepViewed,
        .onboardingActionPerformed,
        .activationCompleted,
        .onboardingStepViewed,
        .onboardingTrustStepViewed,
        .onboardingActionPerformed,
        .onboardingStepViewed,
        .onboardingActionPerformed,
        .notificationPermissionResult,
        .onboardingStepViewed,
        .onboardingActionPerformed,
        .onboardingStepViewed,
        .onboardingTrustStepViewed,
        .onboardingActionPerformed,
        .onboardingStepViewed,
        .onboardingTrustStepViewed,
        .onboardingActionPerformed,
        .onboardingActionPerformed,
        .onboardingStepViewed,
        .onboardingActionPerformed
      ])
    #expect(
      analytics.actions == [
        .motivationSelected,
        .identityCompleted,
        .nameSkipped,
        .habitColorSelected,
        .tinyHabitCreated,
        .firstDotMarked,
        .whyThisWorksContinued,
        .notificationsSkipped,
        .readyContinued,
        .founderNoteContinued,
        .socialProofContinued,
        .paywallBoundaryReached,
        .paywallClosed
      ])
  }
}

extension OnboardingSessionTests {
  @Test fileprivate func onboardingAnalyticsDocsCoverAllowedValuesAndPrivacyBoundaries() throws {
    guard let document = try Self.readAnalyticsEventsDocumentIfAllowed() else { return }

    #expect(document.contains("`onboarding_step_viewed`"))
    #expect(document.contains("`onboarding_action_performed`"))
    #expect(document.contains("`step_id`"))
    #expect(document.contains("`action`"))

    for value in OnboardingStepCatalog.stepIDs {
      #expect(document.contains("`\(value)`"))
    }

    for value in OnboardingAction.allCases.map(\.rawValue) {
      #expect(document.contains("`\(value)`"))
    }

    for forbidden in [
      "identity commitment IDs",
      "tiny habit IDs",
      "calendar names",
      "habit names",
      "notification text"
    ] {
      #expect(document.localizedCaseInsensitiveContains(forbidden))
    }
  }

  @Test fileprivate func onboardingStepCatalogUsesLowercaseSnakeCaseRawValues() {
    #expect(
      OnboardingStep.allCases.map(\.rawValue) == [
        "emotional_hook",
        "app_explanation",
        "motivation",
        "identity_commitment",
        "name",
        "tiny_habit_selection",
        "first_dot",
        "why_this_works",
        "notification_permission",
        "ready_widgets",
        "founder_note",
        "social_proof",
        "paywall"
      ])
  }

  private static let analyticsEventsDocPath: String = {
    let fileURL = URL(fileURLWithPath: #filePath)
    let repoRoot =
      fileURL
      .deletingLastPathComponent()
      .deletingLastPathComponent()
    return repoRoot.appendingPathComponent("docs/analytics-events.md").path
  }()

  private static func readAnalyticsEventsDocumentIfAllowed() throws -> String? {
    do {
      return try String(contentsOfFile: analyticsEventsDocPath, encoding: .utf8)
    } catch CocoaError.fileReadNoPermission {
      return nil
    }
  }
}

private func makeCalendar(
  name: String,
  isArchived: Bool = false,
  entries: [String: CalendarEntry] = [:]
) -> CustomCalendar {
  CustomCalendar(
    name: name,
    color: "qs-amber",
    cadence: .daily,
    trackingType: .binary,
    trackingStartedAt: LocalDayCalendar.startOfDay(for: Date()),
    dailyTarget: 1,
    entries: entries,
    isArchived: isArchived,
    recurringReminderEnabled: false,
    reminderTime: nil,
    reminderWeekday: nil,
    unit: nil,
    defaultRecordValue: nil,
    currencySymbol: nil,
    reminderTimeZone: TimeZone.current.identifier,
    notificationPrivacyMode: .full,
    suppressWhenCompleted: true,
    additionalReminderTimes: [],
    streakProtectionEnabled: true,
    streakProtectionThreshold: 5
  )
}

private final class SpyAnalytics: OnboardingAnalyticsTracking {
  private(set) var events: [(event: AnalyticsEvent, properties: [String: AnalyticsPropertyValue])] = []
  private var hasCompletedActivation = false

  func trackOnboardingStepViewed(stepId: String, properties: [String: AnalyticsPropertyValue]) {
    let eventProperties = properties.merging(["step_id": .string(stepId)]) { _, new in new }
    events.append(
      (event: .onboardingStepViewed, properties: eventProperties)
    )
  }

  func trackOnboardingAction(_ action: OnboardingAction, properties: [String: AnalyticsPropertyValue]) {
    events.append(
      (
        event: .onboardingActionPerformed,
        properties: properties.merging(["action": .string(action.rawValue)]) { _, new in new }
      ))
  }

  func trackOnboardingEvent(_ event: AnalyticsEvent, properties: [String: AnalyticsPropertyValue]) {
    events.append((event: event, properties: properties))
  }

  func markActivationCompleted(source: ActivationSource, properties: [String: AnalyticsPropertyValue]) {
    guard !hasCompletedActivation else { return }
    hasCompletedActivation = true
    events.append(
      (
        event: .activationCompleted,
        properties: properties.merging(["activation_source": .string(source.rawValue)]) { _, new in new }
      ))
  }

  var actions: [OnboardingAction] {
    events.compactMap { event, properties in
      guard event == .onboardingActionPerformed,
        case .string(let action) = properties["action"]
      else {
        return nil
      }
      return OnboardingAction(rawValue: action)
    }
  }
}

private final class NotificationRequesterStub {
  private(set) var requestCount = 0
  private var completion: ((Result<Bool, Error>) -> Void)?

  func request(_ completion: @escaping (Result<Bool, Error>) -> Void) {
    requestCount += 1
    self.completion = completion
  }

  func complete(_ result: Result<Bool, Error>) {
    completion?(result)
  }
}
