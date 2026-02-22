import Foundation

final class ShowedUpMilestoneTracker {
    static let shared = ShowedUpMilestoneTracker()

    private let storageKey = "showedUpMilestoneTracker.v1"
    private var lastCelebratedByCalendar: [String: Int]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        lastCelebratedByCalendar = Self.load(from: defaults, key: storageKey)
    }

    func milestoneToCelebrate(calendarId: UUID, showedUpCount: Int) -> Int? {
        guard let milestone = ShowedUpMilestones.milestone(for: showedUpCount) else { return nil }
        let lastMilestone = lastCelebratedByCalendar[calendarId.uuidString] ?? 0
        guard milestone > lastMilestone else { return nil }
        return milestone
    }

    func markCelebrated(calendarId: UUID, milestone: Int) {
        lastCelebratedByCalendar[calendarId.uuidString] = milestone
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(lastCelebratedByCalendar) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private static func load(from defaults: UserDefaults, key: String) -> [String: Int] {
        guard let data = defaults.data(forKey: key),
              let stored = try? JSONDecoder().decode([String: Int].self, from: data)
        else {
            return [:]
        }
        return stored
    }
}
