import Foundation
import SwiftUI

enum UpgradePromptKind: String, Codable {
  case positiveEvent = "positive_event"
  case timedRandom = "timed_random"
}

struct UpgradePromptRules: Codable, Equatable {
  var minPositiveEvents: Int = 2
  var cooldownDays: Int = 7
  var minDaysSinceInstallForTimedPrompt: Int = 3
  var timedPromptChance: Double = 0.08
}

struct UpgradePromptContext: Identifiable, Equatable {
  let id = UUID()
  let kind: UpgradePromptKind
  let trigger: PaywallTrigger
  let positiveEvent: PositiveEvent?
  let promptCount: Int
  let totalPositiveEventCount: Int

  var analyticsProperties: [String: AnalyticsPropertyValue] {
    var properties: [String: AnalyticsPropertyValue] = [
      "paywall_prompt_kind": .string(kind.rawValue),
      "prompt_count": .int(promptCount),
      "total_positive_event_count": .int(totalPositiveEventCount)
    ]

    if let positiveEvent {
      properties["positive_event"] = .string(positiveEvent.rawValue)
    }

    return properties
  }
}

private struct UpgradePromptState: Codable {
  var totalPositiveEventCount: Int = 0
  var promptCount: Int = 0
  var lastPromptDate: Date?
}

@MainActor
final class UpgradePrompter: ObservableObject {
  static let shared = UpgradePrompter()

  var rules = UpgradePromptRules()
  @Published var activePrompt: UpgradePromptContext?

  private let defaults: UserDefaults
  private let analytics: Analytics
  private let isEligibleForPrompt: () -> Bool
  private let daysSinceInstall: () -> Int
  private let now: () -> Date
  private let random: () -> Double
  private let storageKey = "upgrade_prompter.state.v1"
  private var state = UpgradePromptState()

  init(
    defaults: UserDefaults = .standard,
    analytics: Analytics? = nil,
    isEligibleForPrompt: (() -> Bool)? = nil,
    daysSinceInstall: (() -> Int)? = nil,
    now: @escaping () -> Date = Date.init,
    random: @escaping () -> Double = { Double.random(in: 0..<1) }
  ) {
    self.defaults = defaults
    self.analytics = analytics ?? .shared
    self.isEligibleForPrompt =
      isEligibleForPrompt ?? {
        AnalyticsState.shared.premiumStatusKnown && !AnalyticsState.shared.isPremiumUser
      }
    self.daysSinceInstall = daysSinceInstall ?? { AnalyticsState.shared.daysSinceInstall }
    self.now = now
    self.random = random
    load()
  }

  func recordAndConsiderPrompt(_ event: PositiveEvent) {
    state.totalPositiveEventCount += 1
    save()
    considerPositiveEventPrompt(for: event)
  }

  func considerTimedPrompt() {
    guard promptBlocker() == nil else { return }
    guard daysSinceInstall() >= rules.minDaysSinceInstallForTimedPrompt else { return }
    guard random() < rules.timedPromptChance else { return }

    presentPrompt(kind: .timedRandom, trigger: .automaticTimed, positiveEvent: nil)
  }

  func dismissActivePrompt() {
    activePrompt = nil
  }

  private func considerPositiveEventPrompt(for event: PositiveEvent) {
    let baseProperties: [String: AnalyticsPropertyValue] = [
      "paywall_prompt_kind": .string(UpgradePromptKind.positiveEvent.rawValue),
      "paywall_trigger": .string(PaywallTrigger.automaticPositiveEvent.rawValue),
      "positive_event": .string(event.rawValue),
      "total_positive_event_count": .int(state.totalPositiveEventCount)
    ]

    if let blocker = promptBlocker() {
      analytics.trackPaywallPromptConsidered(
        trigger: .automaticPositiveEvent,
        result: blocker,
        properties: baseProperties
      )
      return
    }

    guard state.totalPositiveEventCount >= rules.minPositiveEvents else {
      analytics.trackPaywallPromptConsidered(
        trigger: .automaticPositiveEvent,
        result: "not_enough_positive_events",
        properties: baseProperties
      )
      return
    }

    presentPrompt(kind: .positiveEvent, trigger: .automaticPositiveEvent, positiveEvent: event)
  }

  private func promptBlocker() -> String? {
    guard activePrompt == nil else {
      return "already_active"
    }

    guard isEligibleForPrompt() else {
      return "not_eligible"
    }

    if let lastPromptDate = state.lastPromptDate {
      let days = Calendar.current.dateComponents([.day], from: lastPromptDate, to: now()).day ?? 0
      if days < rules.cooldownDays {
        return "cooldown"
      }
    }

    return nil
  }

  private func presentPrompt(
    kind: UpgradePromptKind,
    trigger: PaywallTrigger,
    positiveEvent: PositiveEvent?
  ) {
    state.promptCount += 1
    state.lastPromptDate = now()
    save()

    activePrompt = UpgradePromptContext(
      kind: kind,
      trigger: trigger,
      positiveEvent: positiveEvent,
      promptCount: state.promptCount,
      totalPositiveEventCount: state.totalPositiveEventCount
    )

    analytics.trackPaywallPromptConsidered(
      trigger: trigger,
      result: "presented",
      properties: activePrompt?.analyticsProperties ?? [:]
    )
  }

  private func load() {
    guard let data = defaults.data(forKey: storageKey) else { return }
    if let decoded = try? JSONDecoder().decode(UpgradePromptState.self, from: data) {
      state = decoded
    }
  }

  private func save() {
    if let data = try? JSONEncoder().encode(state) {
      defaults.set(data, forKey: storageKey)
    }
  }
}
