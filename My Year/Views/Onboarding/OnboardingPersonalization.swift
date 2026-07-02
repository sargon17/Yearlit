import SwiftUI

enum OnboardingMotivation: String, CaseIterable, Identifiable {
  case consistency = "feel_consistent_again"
  case stopRestarting = "stop_starting_over"
  case discipline = "build_discipline"
  case health = "protect_my_health"
  case visibleProgress = "make_progress_visible"
  case selfPromise = "keep_a_promise_to_myself"

  var id: String { rawValue }

  var title: LocalizedStringKey {
    switch self {
    case .consistency:
      "Feel consistent again"
    case .stopRestarting:
      "Stop starting over"
    case .discipline:
      "Build discipline"
    case .health:
      "Protect my health"
    case .visibleProgress:
      "Make progress visible"
    case .selfPromise:
      "Keep a promise to myself"
    }
  }
}

enum OnboardingTrustStep: String {
  case whyThisWorks = "why_this_works"
  case founderNote = "founder_note"
  case socialProof = "social_proof"
}

enum OnboardingCopy {
  static let flowID = "full_next_release"
  static let appStoreRating = "4.7"
  static let habitsTrackedStat = "4,000+"
  static let dailyCheckInsStat = "10,000+"

  static func firstDotProofLine(for motivation: OnboardingMotivation?) -> LocalizedStringKey {
    switch motivation {
    case .consistency:
      "This is consistency returning."
    case .stopRestarting:
      "You do not need a perfect restart. You need today."
    case .discipline:
      "Discipline starts with one kept action."
    case .health:
      "Small health promises compound when they stay visible."
    case .visibleProgress:
      "Now your progress has a place to show up."
    case .selfPromise:
      "You kept the first promise."
    case nil:
      "Keep the promise tomorrow."
    }
  }

  static func founderMiddleLine(for motivation: OnboardingMotivation?) -> LocalizedStringKey {
    switch motivation {
    case .consistency:
      "It is for rebuilding trust with yourself, one visible day at a time."
    case .stopRestarting:
      "It is for continuing after imperfect days instead of starting from zero again."
    case .discipline:
      "It is for making discipline visible before it feels automatic."
    case .health:
      "It is for protecting the small actions your future self will thank you for."
    case .visibleProgress:
      "It is for turning quiet effort into something you can actually see."
    case .selfPromise:
      "It is for keeping one small promise long enough that it becomes part of you."
    case nil:
      "It is about having a place to come back to."
    }
  }

  static func socialProofTitle(for motivation: OnboardingMotivation?) -> LocalizedStringKey {
    switch motivation {
    case .consistency:
      "People are rebuilding consistency"
    case .stopRestarting:
      "You are not the only one starting again"
    case .discipline:
      "People are building discipline one dot at a time"
    case .health:
      "Small health habits are easier when they stay visible"
    case .visibleProgress:
      "Progress feels different when you can see it"
    case .selfPromise:
      "You are not keeping this promise alone"
    case nil:
      "You are not starting alone"
    }
  }

  static func paywallTitle(for motivation: OnboardingMotivation?) -> LocalizedStringKey {
    switch motivation {
    case .consistency:
      "Protect the consistency you just restarted"
    case .stopRestarting:
      "Keep going without starting over"
    case .discipline:
      "Make discipline easier to return to"
    case .health:
      "Keep your health promise visible"
    case .visibleProgress:
      "Make your progress impossible to ignore"
    case .selfPromise:
      "Protect the promise you just kept"
    case nil:
      "Protect the year you just started."
    }
  }

  static func paywallSubtitle(for motivation: OnboardingMotivation?) -> LocalizedStringKey {
    switch motivation {
    case .consistency:
      "Pro helps you keep your habit visible, spot your pattern, and come back tomorrow."
    case .stopRestarting:
      "Pro helps you recover faster, keep your history, and continue after imperfect days."
    case .discipline:
      "Pro helps you make discipline visible with widgets, stats, and more habits to track."
    case .health:
      "Pro helps you keep health habits in sight, track patterns, and protect your routine."
    case .visibleProgress:
      "Pro gives you widgets, stats, and calendars that make your effort visible."
    case .selfPromise:
      "Pro helps you keep your promise visible, track every commitment, and return tomorrow."
    case nil:
      "Pro helps you keep it visible, track the pattern, and come back tomorrow."
    }
  }
}
