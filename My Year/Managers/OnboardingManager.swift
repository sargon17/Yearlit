import SharedModels
import SwiftUI

/// Gestisce lo stato di visualizzazione dell'onboarding.
/// Usa una chiave con versione così, se cambi onboarding, puoi forzare a rivederlo.
final class OnboardingManager: ObservableObject {
    static let currentVersion = 1

    @AppStorage(AppStorageKeys.onboardingSeenV1) private var seenV1: Bool = false

    var hasSeenOnboarding: Bool {
        seenV1
    }

    func markAsSeen() {
        seenV1 = true
        persistDefaultTimelinePreferenceIfNeeded()
        objectWillChange.send()
    }

    func persistDefaultTimelinePreferenceIfNeeded() {
        guard hasSeenOnboarding, !TimelinePreferenceStore.hasStoredMode() else { return }
        TimelinePreferenceStore.setMode(.your365)
    }

    #if DEBUG
        func reset() {
            seenV1 = false
            objectWillChange.send()
        }
    #endif
}
