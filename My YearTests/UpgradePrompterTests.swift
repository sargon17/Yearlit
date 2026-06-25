import Foundation
import Testing

@testable import My_Year

@MainActor
struct UpgradePrompterTests {
  @Test func positiveEventPromptWaitsForConfiguredActivationCount() throws {
    let defaults = makeTestDefaults()
    defer { cleanupTestDefaults(defaults) }
    let analytics = makeAnalytics(defaults: defaults)
    let spy = RecordingAnalyticsClient()
    analytics.replaceClient(spy)
    let prompter = UpgradePrompter(
      defaults: defaults,
      analytics: analytics,
      isEligibleForPrompt: { true },
      daysSinceInstall: { 10 },
      now: { Date(timeIntervalSince1970: 1_000) },
      random: { 0 }
    )
    prompter.rules = .init(
      minPositiveEvents: 2, cooldownDays: 7, minDaysSinceInstallForTimedPrompt: 3, timedPromptChance: 1)

    prompter.recordAndConsiderPrompt(.createdCalendar)
    #expect(prompter.activePrompt == nil)

    prompter.recordAndConsiderPrompt(.completedCheckIn)

    let context = try #require(prompter.activePrompt)
    #expect(context.kind == .positiveEvent)
    #expect(context.trigger == .automaticPositiveEvent)
    #expect(context.positiveEvent == .completedCheckIn)
    #expect(context.totalPositiveEventCount == 2)
    #expect(spy.trackedEvents.map(\.event) == [.paywallPromptConsidered, .paywallPromptConsidered])
    #expect(spy.trackedEvents.last?.properties["result"] == .string("presented"))
  }

  @Test func promptCooldownBlocksImmediateRepeat() {
    let defaults = makeTestDefaults()
    defer { cleanupTestDefaults(defaults) }
    let analytics = makeAnalytics(defaults: defaults)
    let spy = RecordingAnalyticsClient()
    analytics.replaceClient(spy)
    var now = Date(timeIntervalSince1970: 1_000)
    let prompter = UpgradePrompter(
      defaults: defaults,
      analytics: analytics,
      isEligibleForPrompt: { true },
      daysSinceInstall: { 10 },
      now: { now },
      random: { 0 }
    )
    prompter.rules = .init(
      minPositiveEvents: 1, cooldownDays: 7, minDaysSinceInstallForTimedPrompt: 3, timedPromptChance: 1)

    prompter.recordAndConsiderPrompt(.createdCalendar)
    prompter.dismissActivePrompt()
    now = Date(timeIntervalSince1970: 2_000)
    prompter.recordAndConsiderPrompt(.completedCheckIn)

    #expect(prompter.activePrompt == nil)
    #expect(spy.trackedEvents.last?.properties["result"] == .string("cooldown"))
  }

  @Test func timedPromptUsesInstallAgeAndRandomGate() {
    let defaults = makeTestDefaults()
    defer { cleanupTestDefaults(defaults) }
    let analytics = makeAnalytics(defaults: defaults)
    let spy = RecordingAnalyticsClient()
    analytics.replaceClient(spy)
    let prompter = UpgradePrompter(
      defaults: defaults,
      analytics: analytics,
      isEligibleForPrompt: { true },
      daysSinceInstall: { 5 },
      now: { Date(timeIntervalSince1970: 1_000) },
      random: { 0.2 }
    )
    prompter.rules = .init(
      minPositiveEvents: 2, cooldownDays: 7, minDaysSinceInstallForTimedPrompt: 3, timedPromptChance: 0.5)

    prompter.considerTimedPrompt()

    #expect(prompter.activePrompt?.kind == .timedRandom)
    #expect(prompter.activePrompt?.trigger == .automaticTimed)
    #expect(spy.trackedEvents.last?.properties["result"] == .string("presented"))
  }

  private func makeAnalytics(defaults: UserDefaults) -> Analytics {
    Analytics(state: AnalyticsState(defaults: defaults))
  }

  private func makeTestDefaults() -> UserDefaults {
    let suiteName = "UpgradePrompterTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
  }

  private func cleanupTestDefaults(_ defaults: UserDefaults) {
    for key in defaults.dictionaryRepresentation().keys {
      defaults.removeObject(forKey: key)
    }
  }
}

@MainActor
private final class RecordingAnalyticsClient: AnalyticsClient {
  private(set) var trackedEvents: [(event: AnalyticsEvent, properties: [String: AnalyticsPropertyValue])] = []

  func track(_ event: AnalyticsEvent, properties: [String: AnalyticsPropertyValue]) {
    trackedEvents.append((event: event, properties: properties))
  }

  func identify(distinctId _: String, properties _: [String: AnalyticsPropertyValue]) {}

  func setPersonProperties(_: [String: AnalyticsPropertyValue]) {}
}
