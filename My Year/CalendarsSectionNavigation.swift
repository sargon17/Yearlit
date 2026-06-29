import Foundation

extension CalendarsSection {
  func handleCalendarDeepLink(_ url: URL) {
    guard url.scheme == "my-year", url.host == "calendar" else { return }
    let idString = url.pathComponents.dropFirst().first
    guard let idString else { return }

    pendingCalendarId = idString
    store.loadCalendars(showLoadingIndicator: false)
    scrollToCalendarIfAvailable(idString)
  }

  func scrollToPendingCalendarIfAvailable() {
    guard let pendingCalendarId else { return }
    scrollToCalendarIfAvailable(pendingCalendarId)
  }

  func scrollToCalendarIfAvailable(_ id: String) {
    guard store.snapshot.activeCalendars.contains(where: { $0.id.uuidString == id }) else { return }
    pendingCalendarId = nil

    Task { @MainActor in
      await Task.yield()
      position.scrollTo(id: id)
    }
  }

  func trackRecapViewIfNeeded(for viewID: String?) {
    guard viewID == "recap", !hasTrackedRecapView else { return }
    hasTrackedRecapView = true
    Analytics.shared.track(.recapViewViewed)
  }

  func playSlideSettledHapticIfNeeded(for slideId: String) {
    guard lastHapticSlideId != slideId else { return }
    lastHapticSlideId = slideId

    Task {
      await hapticFeedback(.rigid)
    }
  }
}
