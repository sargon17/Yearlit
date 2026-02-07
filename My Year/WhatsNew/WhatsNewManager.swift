import Foundation

@MainActor
final class WhatsNewManager: ObservableObject {
  @Published private(set) var pendingRelease: WhatsNewRelease?

  private let storageKey = "whatsnew.lastSeenVersion"
  private let dataSource = WhatsNewNotesDataSource()
  private var lastEvaluatedVersion: String?

  init() {
    dataSource.load()
  }

  func evaluateIfNeeded(hasCalendars: Bool, isLoading: Bool) {
    guard !isLoading else { return }
    guard let currentVersion = Bundle.main.appShortVersion else { return }
    guard lastEvaluatedVersion != currentVersion else { return }
    lastEvaluatedVersion = currentVersion

    guard let current = AppVersion(currentVersion) else { return }
    let lastSeen = lastSeenVersion.flatMap(AppVersion.init)

    if !hasCalendars {
      setLastSeenVersion(currentVersion)
      return
    }

    guard let release = dataSource.latestRelease(after: lastSeen, upTo: current) else { return }
    pendingRelease = release
  }

  func takePendingRelease() -> WhatsNewRelease? {
    let release = pendingRelease
    pendingRelease = nil
    return release
  }

  func latestRelease() -> WhatsNewRelease? {
    guard let currentVersion = Bundle.main.appShortVersion else { return nil }
    guard let current = AppVersion(currentVersion) else { return nil }
    return dataSource.latestRelease(after: nil, upTo: current)
  }

  func markSeen(_ release: WhatsNewRelease) {
    setLastSeenVersion(release.version)
  }

  func resetLastSeenVersion() {
    UserDefaults.standard.removeObject(forKey: storageKey)
    pendingRelease = nil
    lastEvaluatedVersion = nil
  }

  private var lastSeenVersion: String? {
    UserDefaults.standard.string(forKey: storageKey)
  }

  private func setLastSeenVersion(_ version: String) {
    UserDefaults.standard.set(version, forKey: storageKey)
  }
}

final class WhatsNewNotesDataSource {
  private(set) var notes: WhatsNewReleaseNotes?
  private let resourceName = "whats_new"

  func load() {
    guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else { return }
    guard let data = try? Data(contentsOf: url) else { return }
    notes = try? JSONDecoder().decode(WhatsNewReleaseNotes.self, from: data)
  }

  func latestRelease(after lastSeen: AppVersion?, upTo current: AppVersion) -> WhatsNewRelease? {
    guard let releases = notes?.releases else { return nil }
    let eligible = releases.compactMap { release -> (AppVersion, WhatsNewRelease)? in
      guard let version = release.versionValue else { return nil }
      guard version <= current else { return nil }
      if let lastSeen, version <= lastSeen { return nil }
      return (version, release)
    }
    return
      eligible
      .sorted { $0.0 > $1.0 }
      .first?
      .1
  }
}
