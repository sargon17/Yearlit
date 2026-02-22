import SwiftUI

/// Gestisce lo stato di visualizzazione dell'onboarding.
/// Usa una chiave con versione così, se cambi onboarding, puoi forzare a rivederlo.
final class OnboardingManager: ObservableObject {
    static let currentVersion = 1
    private let key = "onboarding.seen.v\(currentVersion)"

    @AppStorage("onboarding.seen.v1") private var seenV1: Bool = false

    var hasSeenOnboarding: Bool {
        seenV1
    }

    func markAsSeen() {
        seenV1 = true
        objectWillChange.send()
    }

    #if DEBUG
        func reset() {
            seenV1 = false
            objectWillChange.send()
        }
    #endif
}
