import Foundation

final class ShowedUpMilestoneTracker {
    static let shared = ShowedUpMilestoneTracker()

    private let persistenceKey = "showedUpMilestoneTracker.v2"
    private let legacyPersistenceKey = "showedUpMilestoneTracker.v1"
    private var lastCelebratedByScope: [String: Int]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let legacyState = Self.load(from: defaults, key: legacyPersistenceKey)
        let migratedLegacyState = Dictionary(uniqueKeysWithValues: legacyState.map { key, value in
                ("\(ShowedUpMilestoneKind.allTime.rawValue)|all|\(key)", value)
        })
        let currentState = Self.load(from: defaults, key: persistenceKey)

        lastCelebratedByScope = migratedLegacyState.merging(currentState) { _, current in current }

        if !lastCelebratedByScope.isEmpty {
            save()
        }
    }

    func milestoneToCelebrate(
        calendarId: UUID,
        showedUpCount: Int,
        kind: ShowedUpMilestoneKind,
        periodKey: String
    ) -> Int? {
        guard let milestone = ShowedUpMilestones.latestMilestone(for: showedUpCount, kind: kind) else { return nil }
        let lastMilestone = lastCelebratedByScope[
            scopedKey(calendarId: calendarId, kind: kind, periodKey: periodKey)
        ] ?? 0
        guard milestone > lastMilestone else { return nil }
        return milestone
    }

    func markCelebrated(
        calendarId: UUID,
        milestone: Int,
        kind: ShowedUpMilestoneKind,
        periodKey: String
    ) {
        markRemembered(calendarId: calendarId, milestone: milestone, kind: kind, periodKey: periodKey)
    }

    func markRemembered(
        calendarId: UUID,
        milestone: Int,
        kind: ShowedUpMilestoneKind,
        periodKey: String
    ) {
        lastCelebratedByScope[scopedKey(calendarId: calendarId, kind: kind, periodKey: periodKey)] = milestone
        save()
    }

    private func scopedKey(calendarId: UUID, kind: ShowedUpMilestoneKind, periodKey: String) -> String {
        "\(kind.rawValue)|\(periodKey)|\(calendarId.uuidString)"
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(lastCelebratedByScope) else { return }
        defaults.set(data, forKey: persistenceKey)
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
