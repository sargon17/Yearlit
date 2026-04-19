import SharedModels
import SwiftUI

func stableCacheFingerprint(_ values: [String]) -> String {
    var hash: UInt64 = 14_695_981_039_346_656_037

    for value in values {
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        hash ^= 255
        hash &*= 1_099_511_628_211
    }

    return String(hash, radix: 16)
}

func calendarEntriesFingerprint(_ calendar: CustomCalendar) -> String {
    let bucketedEntries = buildEntriesByCalendarByBucket(calendars: [calendar])[calendar.id] ?? [:]

    return stableCacheFingerprint(
        [
            calendar.id.uuidString,
            calendar.cadence.rawValue,
            calendar.trackingType.rawValue,
            String(calendar.dailyTarget),
            calendar.color,
        ]
            + bucketedEntries
                .sorted { $0.key < $1.key }
                .map { bucketDate, entry in
                    "\(dayKey(for: bucketDate))|\(entry.count)|\(entry.completed ? 1 : 0)"
                }
    )
}

func calendarsEntriesFingerprint(_ calendars: [CustomCalendar]) -> String {
    stableCacheFingerprint(
        calendars
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map { calendar in
                "\(calendar.id.uuidString)|\(calendar.cadence.rawValue)|\(calendarEntriesFingerprint(calendar))"
            }
    )
}
