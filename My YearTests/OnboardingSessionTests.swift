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
}
