import Foundation

@MainActor
final class WhatsNewManager: ObservableObject {
  @Published private(set) var activeRelease: WhatsNewRelease?
  @Published var isPresented: Bool = false

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
    activeRelease = release
    isPresented = true
  }

  func presentLatest() {
    guard let currentVersion = Bundle.main.appShortVersion else { return }
    guard let current = AppVersion(currentVersion) else { return }
    guard let release = dataSource.latestRelease(after: nil, upTo: current) else { return }
    activeRelease = release
    isPresented = true
  }

  func markSeen() {
    guard let release = activeRelease else { return }
    setLastSeenVersion(release.version)
    isPresented = false
    activeRelease = nil
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
    return eligible
      .sorted { $0.0 > $1.0 }
      .first?
      .1
  }
}
