import Foundation
import SharedModels

/// Gestisce lo stato di visualizzazione dell'onboarding.
/// Usa una chiave con versione così, se cambi onboarding, puoi forzare a rivederlo.
@MainActor
final class OnboardingManager: ObservableObject {
  static let currentVersion = 1

  @Published private(set) var hasSeenOnboarding: Bool

  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    hasSeenOnboarding = defaults.bool(forKey: AppStorageKeys.onboardingSeenV1)
  }

  func markAsSeen() {
    let wasUnseen = !hasSeenOnboarding
    defaults.set(true, forKey: AppStorageKeys.onboardingSeenV1)
    hasSeenOnboarding = true

    guard wasUnseen else { return }

    Analytics.shared.track(.onboardingCompleted)
  }

  #if DEBUG
    func reset() {
      defaults.set(false, forKey: AppStorageKeys.onboardingSeenV1)
      hasSeenOnboarding = false
    }
  #endif
}
