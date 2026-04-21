import Foundation
import SafariServices
import StoreKit
import UIKit

/// Describe the kinds of positive interactions that justify a prompt.
/// Customize for your app’s funnel.
enum PositiveEvent: String, Codable, CaseIterable {
    case completedOnboarding
    case finishedPurchase
    case reachedMilestone
    case createdCalendar
    case reachedThreeCompletedDays
}

/// Configuration for when to prompt.
struct ReviewRules: Codable, Equatable {
    /// Minimum positive events before we ever prompt.
    var minEvents: Int = 3
    /// Cooldown between prompts.
    var cooldownDays: Int = 30
    /// Optional: only one prompt per app version.
    var oncePerVersion: Bool = true
}

/// Persisted state.
private struct ReviewState: Codable {
    var totalEventCount: Int = 0
    var lastPromptDate: Date? = nil
    var lastPromptedVersion: String? = nil
}

/// Main prompter 🔨🤖🔧
final class ReviewPrompter {
    static let shared = ReviewPrompter()
    private init() {
        load()
    }

    // MARK: - Public API

    var rules = ReviewRules()

    /// Call this whenever a “good” thing happens in your app.
    func record(_: PositiveEvent) {
        state.totalEventCount += 1
        save()
    }

    /// Ask the prompter to consider showing a prompt **now** (e.g., after a flow completes).
    /// This won’t show anything if rules aren’t met or the system refuses.
    func considerPrompt(from viewController: UIViewController? = nil, fallbackAppID: String? = nil) {
        guard shouldPromptNow() else { return }
        isPromptInFlight = true
        Task { @MainActor in
            defer { self.isPromptInFlight = false }
            actuallyPrompt(from: viewController, fallbackAppID: fallbackAppID)
        }
    }

    // SwiftUI convenience.
    #if canImport(SwiftUI)
        func considerPromptSwiftUI(fallbackAppID: String? = nil) {
            Task { @MainActor in
                considerPrompt(from: topMostViewController(), fallbackAppID: fallbackAppID)
            }
        }
    #endif

    // MARK: - Internals

    private let storageKey = "review_prompter.state.v1"
    private var state = ReviewState()
    private var isPromptInFlight = false

    private func shouldPromptNow() -> Bool {
        guard !isPromptInFlight else { return false }

        // Enough positive signals?
        guard state.totalEventCount >= rules.minEvents else { return false }

        // Cooldown?
        if let last = state.lastPromptDate {
            let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? .max
            if days < rules.cooldownDays { return false }
        }

        // Per-version gate?
        if rules.oncePerVersion {
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            if let v = currentVersion, state.lastPromptedVersion == v {
                return false
            }
        }

        // Also respect Apple’s *own* internal limits: even if we call requestReview,
        // iOS may ignore it. That’s okay; we’ll update our own state only when we ask.
        return true
    }

    @MainActor
    private func actuallyPrompt(from viewController: UIViewController?, fallbackAppID: String?) {
        if #available(iOS 14.0, *), let scene = reviewScene(from: viewController) {
            if #available(iOS 18.0, *) {
                AppStore.requestReview(in: scene)
            } else {
                SKStoreReviewController.requestReview(in: scene)
            }
            markPromptUsed()
            return
        }

        if #unavailable(iOS 14.0) {
            SKStoreReviewController.requestReview()
            markPromptUsed()
            return
        }

        // No active scene means the in-app prompt cannot be shown reliably.
        guard let appID = fallbackAppID else { return }
        markPromptUsed()

        // Optional: If you **really** want a guaranteed route to a review UI
        // (e.g., if you know Apple may ignore frequent requests),
        // you can deep‑link after a small delay. Use with care to avoid being pushy.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.openWriteReviewPage(appID: appID, from: viewController)
        }
    }

    @available(iOS 14.0, *)
    private func reviewScene(from viewController: UIViewController?) -> UIWindowScene? {
        if let scene = viewController?.view.window?.windowScene,
           scene.activationState == .foregroundActive
        {
            return scene
        }

        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
    }

    private func markPromptUsed() {
        state.lastPromptDate = Date()
        if rules.oncePerVersion {
            state.lastPromptedVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        }
        save()
    }

    private func openWriteReviewPage(appID: String, from vc: UIViewController?) {
        // Apple’s documented pattern to jump to the “Write a Review” screen.
        let urlString = "https://apps.apple.com/app/id\(appID)?action=write-review"
        guard let url = URL(string: urlString) else { return }
        if let vc = vc {
            _ = SFSafePresenter.present(url, from: vc)
            // If you don’t want to pull in SFSafariViewController helper,
            // you can just call UIApplication.shared.open(url).
        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
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

// MARK: - Tiny helper to safely find a top VC & present URLs

@MainActor
private func topMostViewController(
    base: UIViewController? = nil
) -> UIViewController? {
    let resolvedBase = base ?? UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController

    if let nav = resolvedBase as? UINavigationController {
        return topMostViewController(base: nav.visibleViewController)
    }
    if let tab = resolvedBase as? UITabBarController, let selected = tab.selectedViewController {
        return topMostViewController(base: selected)
    }
    if let presented = resolvedBase?.presentedViewController {
        return topMostViewController(base: presented)
    }
    return resolvedBase
}

private enum SFSafePresenter {
    @discardableResult
    static func present(_ url: URL, from vc: UIViewController) -> SFSafariViewController {
        let safari = SFSafariViewController(url: url)
        vc.present(safari, animated: true, completion: nil)
        return safari
    }
}

private extension UIWindowScene {
    var keyWindow: UIWindow? {
        return windows.first(where: { $0.isKeyWindow })
    }
}
