import Foundation
import SwiftData

@available(iOS 17.0, macOS 14.0, *)
public enum DataBackupReason: String, Codable, Sendable {
    case automatic
    case beforeMigration
    case beforeBulkChange
    case beforeRestore

    public var title: String {
        switch self {
        case .automatic:
            return "Automatic"
        case .beforeMigration:
            return "Before migration"
        case .beforeBulkChange:
            return "Before bulk change"
        case .beforeRestore:
            return "Before restore"
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
public struct DataBackupCounts: Codable, Equatable, Sendable {
    public let calendars: Int
    public let checkIns: Int
    public let moodEntries: Int
    public let journalNotes: Int
    public let habitStacks: Int
}

@available(iOS 17.0, macOS 14.0, *)
public struct DataBackupMetadata: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let fileName: String
    public let schemaVersion: Int
    public let createdAt: Date
    public let reason: DataBackupReason
    public let appVersion: String
    public let buildNumber: String
    public let fingerprint: String
    public let counts: DataBackupCounts
}

@available(iOS 17.0, macOS 14.0, *)
public enum DataBackupError: LocalizedError {
    case appGroupUnavailable
    case backupNotFound
    case unsupportedSchemaVersion(Int)
    case invalidBackup

    public var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            return "Backup storage is unavailable."
        case .backupNotFound:
            return "Backup not found."
        case let .unsupportedSchemaVersion(version):
            return "Backup version \(version) is not supported."
        case .invalidBackup:
            return "Backup is invalid."
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
public final class DataBackupService {
    public static let shared = DataBackupService()

    private static let schemaVersion = 1
    private static let automaticBackupDateKey = "DataBackup.lastAutomaticBackupDate"
    private static let automaticBackupFingerprintKey = "DataBackup.lastAutomaticBackupFingerprint"
    private static let automaticRetentionDays = 90
    private static let protectiveRetentionCount = 20

    private let container: ModelContainer
    private let defaults: UserDefaults
    private let directoryURL: URL?
    private let now: () -> Date

    public static func defaultDirectoryURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: SharedAppGroup.id)?
            .appendingPathComponent("DataBackups", isDirectory: true)
    }

    public init(
        container: ModelContainer = SwiftDataManager.container,
        directoryURL: URL? = DataBackupService.defaultDirectoryURL(),
        defaults: UserDefaults = UserDefaults(suiteName: SharedAppGroup.id) ?? .standard,
        now: @escaping () -> Date = Date.init
    ) {
        self.container = container
        self.directoryURL = directoryURL
        self.defaults = defaults
        self.now = now
    }

    @discardableResult
    public func createAutomaticBackupIfNeeded() throws -> DataBackupMetadata? {
        let content = try currentContent()
        let fingerprint = try makeFingerprint(for: content)
        let hasAutomaticBackup = try hasValidAutomaticBackup()
        guard !hasAutomaticBackup || fingerprint != defaults.string(forKey: Self.automaticBackupFingerprintKey) else { return nil }

        let today = DayKeyFormatter.shared.string(from: LocalDayCalendar.startOfDay(for: now()))
        if hasAutomaticBackup, let lastDate = defaults.object(forKey: Self.automaticBackupDateKey) as? Date {
            let lastDay = DayKeyFormatter.shared.string(from: LocalDayCalendar.startOfDay(for: lastDate))
            guard lastDay != today else { return nil }
        }

        let metadata = try writeBackup(reason: .automatic, content: content, fingerprint: fingerprint)
        defaults.set(now(), forKey: Self.automaticBackupDateKey)
        defaults.set(fingerprint, forKey: Self.automaticBackupFingerprintKey)
        return metadata
    }

    @discardableResult
    public func createProtectiveBackup(reason: DataBackupReason) throws -> DataBackupMetadata {
        let content = try currentContent()
        let fingerprint = try makeFingerprint(for: content)
        return try writeBackup(reason: reason, content: content, fingerprint: fingerprint)
    }

    private func hasValidAutomaticBackup() throws -> Bool {
        try backupFileURLs().contains { url in
            (try? readValidatedBackup(at: url).metadata.reason) == .automatic
        }
    }

    public func availableBackups() -> [DataBackupMetadata] {
        (try? backupFileURLs())?
            .compactMap { try? readValidatedBackup(at: $0).metadata }
            .sorted { $0.createdAt > $1.createdAt } ?? []
    }

    public func restoreBackup(id: UUID) throws {
        guard let metadata = availableBackups().first(where: { $0.id == id }) else {
            throw DataBackupError.backupNotFound
        }
        let backup = try readValidatedBackup(at: backupDirectoryURL().appendingPathComponent(metadata.fileName))

        try createProtectiveBackup(reason: .beforeRestore)
        try replaceCurrentData(with: backup.content)
        WidgetReload.scheduleHabitWidgetsReload(debounce: 0)
        WidgetReload.scheduleYearWidgetReload(debounce: 0)
    }

    private func writeBackup(
        reason: DataBackupReason,
        content: DataBackupContent,
        fingerprint: String
    ) throws -> DataBackupMetadata {
        try ensureDirectory()
        let id = UUID()
        let fileName = "\(isoFileStamp(now()))-\(id.uuidString).json"
        let metadata = DataBackupMetadata(
            id: id,
            fileName: fileName,
            schemaVersion: Self.schemaVersion,
            createdAt: now(),
            reason: reason,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
            fingerprint: fingerprint,
            counts: content.counts
        )
        let backup = DataBackupFile(metadata: metadata, content: content)
        let data = try encoder().encode(backup)
        try data.write(to: backupDirectoryURL().appendingPathComponent(fileName), options: [.atomic])
        try pruneBackups()
        return metadata
    }

    private func currentContent() throws -> DataBackupContent {
        let context = makeContext()
        let calendars = try fetchCalendars(in: context)
        let valuations = try fetchValuations(in: context)
        let stacks = try fetchHabitStacks(in: context)
        return DataBackupContent(calendars: calendars, valuations: valuations, habitStacks: stacks)
    }

    private func replaceCurrentData(with content: DataBackupContent) throws {
        let context = makeContext()
        try deleteAll(HabitCalendarEntity.self, in: context)
        try deleteAll(CalendarEntryEntity.self, in: context)
        try deleteAll(DayValuationEntity.self, in: context)
        try deleteAll(HabitStackEntity.self, in: context)
        try deleteAll(HabitStackStepEntity.self, in: context)

        for calendar in content.calendars {
            let entity = HabitCalendarEntity.make(from: calendar)
            context.insert(entity)
            for (dayKey, entry) in calendar.entries {
                context.insert(
                    CalendarEntryEntity(
                        compositeKey: CalendarEntryEntity.makeCompositeKey(calendarId: calendar.id, dayKey: dayKey),
                        calendarId: calendar.id,
                        dayKey: dayKey,
                        date: entry.date,
                        count: entry.count,
                        completed: entry.completed
                    )
                )
            }
        }

        for valuation in content.valuations {
            context.insert(
                DayValuationEntity(
                    dayKey: valuation.id,
                    timestamp: valuation.timestamp,
                    moodRawValue: valuation.mood.rawValue,
                    note: valuation.note
                )
            )
        }

        for stack in content.habitStacks {
            context.insert(HabitStackEntity.make(from: stack))
            for step in stack.steps {
                context.insert(HabitStackStepEntity.make(from: step, stackId: stack.id))
            }
        }

        if context.hasChanges {
            try context.save()
        }
    }

    private func fetchCalendars(in context: ModelContext) throws -> [CustomCalendar] {
        let calendars = try context.fetch(
            FetchDescriptor<HabitCalendarEntity>(sortBy: [SortDescriptor(\HabitCalendarEntity.order)])
        )
        let entries = try context.fetch(FetchDescriptor<CalendarEntryEntity>())
        let entriesByCalendar = Dictionary(grouping: entries, by: { $0.calendarId })
        return CustomCalendarStore.normalizedCalendarOrder(
            calendars.map { entity in
                let entryModels = entriesByCalendar[entity.id, default: []].reduce(into: [String: CalendarEntry]()) {
                    result, entry in
                    result[entry.dayKey] = entry.toCalendarEntry()
                }
                return entity.toCustomCalendar(entries: entryModels)
            }
        )
    }

    private func fetchValuations(in context: ModelContext) throws -> [DayValuation] {
        try context.fetch(FetchDescriptor<DayValuationEntity>(sortBy: [SortDescriptor(\DayValuationEntity.dayKey)]))
            .map { $0.toDayValuation() }
    }

    private func fetchHabitStacks(in context: ModelContext) throws -> [HabitStack] {
        let stacks = try context.fetch(
            FetchDescriptor<HabitStackEntity>(
                sortBy: [SortDescriptor(\HabitStackEntity.order), SortDescriptor(\HabitStackEntity.createdAt)]
            )
        )
        let steps = try context.fetch(
            FetchDescriptor<HabitStackStepEntity>(
                sortBy: [SortDescriptor(\HabitStackStepEntity.stackId), SortDescriptor(\HabitStackStepEntity.order)]
            )
        )
        let stepsByStack = Dictionary(grouping: steps, by: { $0.stackId })
        return stacks.map { stack in
            stack.toHabitStack(steps: stepsByStack[stack.id, default: []].map { $0.toHabitStackStep() })
        }
    }

    private func readBackup(at url: URL) throws -> DataBackupFile {
        let backup = try decoder().decode(DataBackupFile.self, from: Data(contentsOf: url))
        guard backup.metadata.fileName == url.lastPathComponent else { throw DataBackupError.invalidBackup }
        return backup
    }

    private func readValidatedBackup(at url: URL) throws -> DataBackupFile {
        let backup = try readBackup(at: url)
        guard backup.metadata.schemaVersion <= Self.schemaVersion else {
            throw DataBackupError.unsupportedSchemaVersion(backup.metadata.schemaVersion)
        }
        guard backup.metadata.fingerprint == (try makeFingerprint(for: backup.content)),
              backup.metadata.counts == backup.content.counts
        else {
            throw DataBackupError.invalidBackup
        }
        return backup
    }

    private func backupFileURLs() throws -> [URL] {
        let directoryURL = try backupDirectoryURL()
        guard FileManager.default.fileExists(atPath: directoryURL.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension == "json" }
    }

    private func pruneBackups() throws {
        let automaticCutoff = now().addingTimeInterval(-TimeInterval(Self.automaticRetentionDays * 24 * 60 * 60))
        let fileURLs = try backupFileURLs()
        let backups = fileURLs
            .compactMap { url -> (url: URL, metadata: DataBackupMetadata)? in
                guard let metadata = try? readValidatedBackup(at: url).metadata else { return nil }
                return (url, metadata)
            }
            .sorted { $0.metadata.createdAt > $1.metadata.createdAt }

        let automaticBackups = backups.filter { $0.metadata.reason == .automatic }
        let protectiveBackups = backups.filter { $0.metadata.reason != .automatic }
        let keep = Set(
            automaticBackups
                .filter { $0.metadata.createdAt >= automaticCutoff }
                .map(\.metadata.id)
                + protectiveBackups
                .prefix(Self.protectiveRetentionCount)
                .map(\.metadata.id)
        )
        let keptURLs = Set(backups.filter { keep.contains($0.metadata.id) }.map(\.url))

        for url in fileURLs where !keptURLs.contains(url) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func makeFingerprint(for content: DataBackupContent) throws -> String {
        let data = try encoder().encode(content)
        return data.reduce(into: UInt64(1_469_598_103_934_665_603)) { hash, byte in
            hash = (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
        .description
    }

    private func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: backupDirectoryURL(), withIntermediateDirectories: true)
    }

    private func backupDirectoryURL() throws -> URL {
        guard let directoryURL else { throw DataBackupError.appGroupUnavailable }
        return directoryURL
    }

    private func makeContext() -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    private func deleteAll<T: PersistentModel>(_: T.Type, in context: ModelContext) throws {
        for entity in try context.fetch(FetchDescriptor<T>()) {
            context.delete(entity)
        }
    }

    private func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func isoFileStamp(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date).replacingOccurrences(of: ":", with: "-")
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct DataBackupFile: Codable {
    let metadata: DataBackupMetadata
    let content: DataBackupContent
}

@available(iOS 17.0, macOS 14.0, *)
private struct DataBackupContent: Codable {
    let calendars: [CustomCalendar]
    let valuations: [DayValuation]
    let habitStacks: [HabitStack]

    var counts: DataBackupCounts {
        DataBackupCounts(
            calendars: calendars.count,
            checkIns: calendars.reduce(0) { $0 + $1.entries.count },
            moodEntries: valuations.count,
            journalNotes: valuations.filter { $0.note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }.count,
            habitStacks: habitStacks.count
        )
    }
}
