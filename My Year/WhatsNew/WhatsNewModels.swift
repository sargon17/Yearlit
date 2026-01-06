import Foundation

struct WhatsNewReleaseNotes: Decodable {
  let releases: [WhatsNewRelease]
}

struct WhatsNewRelease: Decodable, Identifiable {
  let version: String
  let title: String
  let slides: [WhatsNewSlide]

  var id: String { version }
  var versionValue: AppVersion? { AppVersion(version) }
}

struct WhatsNewSlide: Decodable, Identifiable {
  let id: String
  let type: WhatsNewSlideType
  let title: String
  let subtitle: String?
  let body: String?
  let items: [String]?
  let image: String?
  let systemImage: String?
}

enum WhatsNewSlideType: String, Decodable {
  case hero
  case list
  case image
  case text
}

struct AppVersion: Comparable, Hashable {
  let rawValue: String
  let components: [Int]

  init?(_ rawValue: String) {
    let parts = rawValue
      .split(separator: ".")
      .map { Int($0) ?? 0 }
    guard !parts.isEmpty else { return nil }
    self.rawValue = rawValue
    self.components = parts
  }

  static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
    let maxCount = max(lhs.components.count, rhs.components.count)
    for index in 0..<maxCount {
      let left = index < lhs.components.count ? lhs.components[index] : 0
      let right = index < rhs.components.count ? rhs.components[index] : 0
      if left != right { return left < right }
    }
    return false
  }
}

extension Bundle {
  var appShortVersion: String? {
    infoDictionary?["CFBundleShortVersionString"] as? String
  }
}

#if DEBUG
extension WhatsNewRelease {
  static var preview: WhatsNewRelease {
    WhatsNewRelease(
      version: "1.9",
      title: "What's New",
      slides: [
        WhatsNewSlide(
          id: "preview-hero",
          type: .hero,
          title: "Preview slide",
          subtitle: "A short subtitle goes here.",
          body: "Describe the change and why it matters.",
          items: nil,
          image: nil,
          systemImage: "sparkles"
        ),
        WhatsNewSlide(
          id: "preview-list",
          type: .list,
          title: "Preview list",
          subtitle: "Quick highlights in one place.",
          body: nil,
          items: [
            "One fast improvement",
            "Another cleaner flow",
            "A tiny but helpful detail"
          ],
          image: nil,
          systemImage: "checkmark.seal.fill"
        )
      ]
    )
  }
}
#endif
