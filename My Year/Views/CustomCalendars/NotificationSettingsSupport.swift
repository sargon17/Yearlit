import SharedModels
import SwiftUI

enum NotificationSettingsSupport {
    static func normalizedAdditionalReminderTimes(
        _ times: [ReminderTime],
        trackingType: TrackingType,
        maxAdditionalReminderTimes: Int
    ) -> [ReminderTime] {
        guard trackingType == .multipleDaily else {
            return []
        }

        var seen = Set<String>()
        let deduped = times.filter { time in
            let key = time.id
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }

        let sorted = deduped.sorted {
            if $0.hour != $1.hour { return $0.hour < $1.hour }
            return $0.minute < $1.minute
        }

        return Array(sorted.prefix(maxAdditionalReminderTimes))
    }

    static func nextAdditionalReminderTime(existing: [ReminderTime], reminderTime: Date) -> ReminderTime {
        let base = existing.last?.toDate() ?? reminderTime
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: base) ?? base
        return ReminderTime(from: next)
    }
}

extension View {
    func notificationSettingsSurface() -> some View {
        sameLevelBorder(radius: 6, isFlat: true)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.black.opacity(0.75), lineWidth: 2)
            )
    }
}
