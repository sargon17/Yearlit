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

    @Test func notificationSkipAdvancesWithoutRecordingDecline() {
        let coordinator = OnboardingCoordinator(onFinish: {})

        coordinator.notificationPermissionSkipped()

        #expect(!coordinator.session.didRequestNotifications)
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
}
