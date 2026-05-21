@testable import My_Year
import Testing

@MainActor
struct OnboardingSessionTests {
    @Test func togglingIdentityCommitmentsPreservesOrder() {
        var session = OnboardingSession()

        session.toggleIdentityCommitment(.runner)
        session.toggleIdentityCommitment(.reader)
        session.toggleIdentityCommitment(.runner)
        session.toggleIdentityCommitment(.runner)

        #expect(session.selectedIdentityCommitments == [.reader, .runner])
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
        #expect(coordinator.currentStep == .identityCommitment)

        coordinator.continueTapped()
        #expect(coordinator.currentStep == .identityCommitment)
    }

    @Test func tinyHabitStepDoesNotAdvanceWithoutSelection() {
        let coordinator = OnboardingCoordinator(onFinish: {})

        coordinator.continueTapped()
        coordinator.continueTapped()
        coordinator.identityCommitmentChanged(.runner)
        coordinator.continueTapped()
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
        let calendar = makeCalendar(name: "Read 2 pages")
        let today = Date()

        store.addCalendar(calendar)
        defer {
            store.deleteCalendar(id: calendar.id)
        }

        coordinator.session.tinyHabitCalendarId = calendar.id

        coordinator.firstDotMarkDayOneTapped()
        coordinator.firstDotMarkDayOneTapped()

        let entry = store.getEntry(calendarId: calendar.id, date: today)
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
        coordinator.identityCommitmentChanged(.reader)
        coordinator.continueTapped()
        coordinator.habitSelectionChanged("Read 2 pages")
        coordinator.tinyHabitContinueTapped()

        let resolved = coordinator.resolvedFirstCalendarForView(in: store.snapshot)

        #expect(coordinator.currentStep == .firstDot)
        #expect(coordinator.session.tinyHabitCalendarId != nil)
        #expect(resolved?.id == coordinator.session.tinyHabitCalendarId)
    }

    @Test func positivePreReviewGateRoutesToReviewRequest() {
        let coordinator = OnboardingCoordinator(onFinish: {})

        coordinator.preReviewGateAnswered(.positive)

        #expect(coordinator.session.preReviewGateWasPositive)
        #expect(coordinator.currentStep == .reviewRequest)
    }

    @Test func nonPositivePreReviewGateRoutesToNotifications() {
        let coordinator = OnboardingCoordinator(onFinish: {})

        coordinator.preReviewGateAnswered(.neutral)

        #expect(!coordinator.session.preReviewGateWasPositive)
        #expect(coordinator.currentStep == .notificationPermission)
    }

    @Test func skippedPreReviewGateRoutesToNotifications() {
        let coordinator = OnboardingCoordinator(onFinish: {})

        coordinator.preReviewGateAnswered(.skip)

        #expect(!coordinator.session.preReviewGateWasPositive)
        #expect(coordinator.currentStep == .notificationPermission)
    }

    @Test func reviewNotNowAdvancesWithoutMarkingReviewRequested() {
        let coordinator = OnboardingCoordinator(onFinish: {})

        coordinator.reviewRequestSkipped()

        #expect(!coordinator.session.didRequestReview)
        #expect(coordinator.currentStep == .notificationPermission)
    }

    @Test func reviewRequestWaitsBeforeAdvancing() async {
        var requestCount = 0
        let coordinator = OnboardingCoordinator(
            onFinish: {},
            reviewRequester: { requestCount += 1 },
            reviewPromptDelayNanoseconds: 1_000_000
        )

        coordinator.reviewRequestStarted()

        #expect(requestCount == 1)
        #expect(coordinator.isRequestingReview)
        #expect(coordinator.currentStep == .emotionalHook)

        try? await Task.sleep(nanoseconds: 2_000_000)

        #expect(!coordinator.isRequestingReview)
        #expect(coordinator.session.didRequestReview)
        #expect(coordinator.currentStep == .notificationPermission)
    }

    @Test func reviewSkipTracksSkippedActionOnce() {
        let analytics = SpyAnalytics()
        let coordinator = OnboardingCoordinator(onFinish: {}, analytics: analytics)

        coordinator.reviewRequestSkipped()
        coordinator.reviewRequestSkipped()

        #expect(analytics.actions == [.reviewSkipped])
        #expect(analytics.events.map(\.event) == [
            .onboardingStepViewed,
            .onboardingActionPerformed,
            .onboardingStepViewed
        ])
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
        #expect(analytics.events.map(\.event) == [
            .onboardingStepViewed,
            .onboardingActionPerformed,
            .onboardingStepViewed
        ])

        requester.complete(.success(true))
        await Task.yield()

        #expect(requester.requestCount == 1)
        #expect(analytics.actions == [.notificationsRequested])
        #expect(coordinator.currentStep == .readyWidgets)
    }

    @Test func readyWidgetsAdvancesToPaywall() {
        let coordinator = OnboardingCoordinator(onFinish: {})

        coordinator.readyWidgetsCompleted()

        #expect(coordinator.currentStep == .paywall)
    }

    @Test func paywallClosedFiresFinishOnlyFromBoundary() {
        var didFinish = false
        let coordinator = OnboardingCoordinator(onFinish: {
            didFinish = true
        })

        coordinator.readyWidgetsCompleted()

        #expect(!didFinish)

        coordinator.paywallClosed()

        #expect(didFinish)
    }

    @Test func onboardingCoordinatorTracksLifecycleStepsAndKeyActionsOnce() {
        let analytics = SpyAnalytics()
        var didFinish = false
        let coordinator = OnboardingCoordinator(onFinish: {
            didFinish = true
        }, analytics: analytics)

        #expect(analytics.events == [
            (event: .onboardingStepViewed, properties: ["step_id": .string(OnboardingStep.emotionalHook.rawValue)])
        ])

        coordinator.continueTapped()
        coordinator.continueTapped()
        coordinator.identityCommitmentChanged(.reader)
        coordinator.continueTapped()
        coordinator.habitSelectionChanged("Read 2 pages")
        coordinator.tinyHabitContinueTapped()
        coordinator.firstDotMarkDayOneTapped()
        coordinator.firstDotMarkDayOneTapped()
        coordinator.firstDotContinueTapped()
        coordinator.preReviewGateAnswered(.positive)
        coordinator.reviewRequestAnswered()
        coordinator.reviewRequestAnswered()
        coordinator.notificationPermissionSkipped()
        coordinator.notificationPermissionSkipped()
        coordinator.readyWidgetsCompleted()
        coordinator.readyWidgetsCompleted()
        coordinator.paywallClosed()
        coordinator.paywallClosed()

        #expect(didFinish)
        #expect(analytics.events.map(\.event) == [
            .onboardingStepViewed,
            .onboardingStepViewed,
            .onboardingStepViewed,
            .onboardingActionPerformed,
            .onboardingStepViewed,
            .onboardingActionPerformed,
            .onboardingStepViewed,
            .onboardingActionPerformed,
            .onboardingStepViewed,
            .onboardingActionPerformed,
            .onboardingStepViewed,
            .onboardingActionPerformed,
            .onboardingStepViewed,
            .onboardingActionPerformed,
            .onboardingStepViewed,
            .onboardingActionPerformed
        ])
        #expect(analytics.actions == [
            .identityCompleted,
            .tinyHabitCreated,
            .firstDotMarked,
            .reviewRequested,
            .notificationsSkipped,
            .readyContinued,
            .paywallBoundaryReached,
            .paywallClosed
        ])
    }

    @Test func onboardingAnalyticsDocsCoverAllowedValuesAndPrivacyBoundaries() throws {
        let document = try String(contentsOfFile: Self.analyticsEventsDocPath, encoding: .utf8)

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

    @Test func onboardingStepCatalogUsesLowercaseSnakeCaseRawValues() {
        #expect(OnboardingStep.allCases.map(\.rawValue) == [
            "emotional_hook",
            "app_explanation",
            "identity_commitment",
            "tiny_habit_selection",
            "first_dot",
            "pre_review_gate",
            "review_request",
            "notification_permission",
            "ready_widgets",
            "paywall"
        ])
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

        func trackOnboardingStepViewed(stepId: String) {
            events.append((event: .onboardingStepViewed, properties: ["step_id": .string(stepId)]))
        }

        func trackOnboardingAction(_ action: OnboardingAction) {
            events.append((event: .onboardingActionPerformed, properties: ["action": .string(action.rawValue)]))
        }

        var actions: [OnboardingAction] {
            events.compactMap { event, properties in
                guard event == .onboardingActionPerformed,
                    case let .string(action) = properties["action"]
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
}
