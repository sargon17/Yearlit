import Foundation
import StoreKit
import SwiftUI
import UIKit

enum PositiveEvent: String, Codable, CaseIterable {
  case finishedPurchase
  case reachedMilestone
  case createdCalendar
  case reachedThreeCompletedDays
  case completedCheckIn
}

enum ReviewPromptTrigger: String, Codable {
  case automatic
  case debug
}

struct ReviewPromptContext: Identifiable, Equatable {
  let id = UUID()
  let event: PositiveEvent
  let trigger: ReviewPromptTrigger
}

@MainActor
final class ReviewPrompter: ObservableObject {
  static let shared = ReviewPrompter()
  private init() {
    load()
  }

  // MARK: - Public API

  var rules = ReviewRules()
  @Published var activePrompt: ReviewPromptContext?

  func record(_: PositiveEvent) {
    state.totalEventCount += 1
    save()
  }

  func recordAndConsiderPrompt(_ event: PositiveEvent) {
    record(event)
    considerSatisfactionPrompt(for: event)
  }

  func considerSatisfactionPrompt(for event: PositiveEvent) {
    guard shouldPromptNow() else { return }
    activePrompt = ReviewPromptContext(event: event, trigger: .automatic)
    markSatisfactionPromptShown()
  }

  #if DEBUG
    func presentDebugPrompt() {
      activePrompt = ReviewPromptContext(event: .completedCheckIn, trigger: .debug)
      trackPromptViewed(context: activePrompt)
    }
  #endif

  func requestReviewNow(
    from viewController: UIViewController? = nil,
    context: ReviewPromptContext? = nil
  ) {
    requestReview(in: viewController ?? topMostViewController())
    markReviewRequested()
    Analytics.shared.track(
      .appStoreReviewRequested,
      properties: reviewRequestProperties(context: context)
    )
  }

  func dismissActivePrompt() {
    activePrompt = nil
  }

  // MARK: - Internals

  private let storageKey = "review_prompter.state.v1"
  private var state = ReviewState()

  private func shouldPromptNow() -> Bool {
    guard activePrompt == nil else { return false }
    guard state.totalEventCount >= rules.minEvents else { return false }

    if let last = state.lastSatisfactionPromptDate {
      let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? .max
      if days < rules.cooldownDays { return false }
    }

    if rules.oncePerVersion {
      let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
      if let version = currentVersion, state.lastPromptedVersion == version {
        return false
      }
    }

    return true
  }

  private func requestReview(in viewController: UIViewController?) {
    if #available(iOS 14.0, *), let scene = reviewScene(from: viewController) {
      if #available(iOS 18.0, *) {
        AppStore.requestReview(in: scene)
      } else {
        SKStoreReviewController.requestReview(in: scene)
      }
      return
    }

    if #unavailable(iOS 14.0) {
      SKStoreReviewController.requestReview()
    }
  }

  @available(iOS 14.0, *)
  private func reviewScene(from viewController: UIViewController?) -> UIWindowScene? {
    if let scene = viewController?.view.window?.windowScene,
      scene.activationState == .foregroundActive {
      return scene
    }

    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first(where: { $0.activationState == .foregroundActive })
  }

  private func markSatisfactionPromptShown() {
    state.satisfactionPromptCount += 1
    state.lastSatisfactionPromptDate = Date()
    if rules.oncePerVersion {
      state.lastPromptedVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    save()
    trackPromptViewed(context: activePrompt)
  }

  private func markReviewRequested() {
    state.lastReviewRequestDate = Date()
    save()
  }

  private func trackPromptViewed(context: ReviewPromptContext?) {
    guard let context else { return }

    Analytics.shared.track(
      .reviewSatisfactionPromptViewed,
      properties: [
        "positive_event": .string(context.event.rawValue),
        "trigger": .string(context.trigger.rawValue),
        "prompt_count": .int(state.satisfactionPromptCount),
        "total_positive_event_count": .int(state.totalEventCount)
      ]
    )
  }

  private func reviewRequestProperties(context: ReviewPromptContext?) -> [String: AnalyticsPropertyValue] {
    guard let context else { return [:] }
    return [
      "positive_event": .string(context.event.rawValue),
      "trigger": .string(context.trigger.rawValue)
    ]
  }

  // MARK: - Persistence

  private func load() {
    guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
    if let decoded = try? JSONDecoder().decode(ReviewState.self, from: data) {
      state = decoded
    }
  }

  private func save() {
    if let data = try? JSONEncoder().encode(state) {
      UserDefaults.standard.set(data, forKey: storageKey)
    }
  }
}
