import Foundation
import SwiftData

@available(iOS 17.0, macOS 14.0, *)
@MainActor
extension CustomCalendarStore {
  func fetchCalendarEntity(id: UUID, in context: ModelContext) -> HabitCalendarEntity? {
    fetchCalendarEntities(id: id, in: context).first
  }

  func fetchCalendarEntities(id: UUID, in context: ModelContext) -> [HabitCalendarEntity] {
    let predicate = #Predicate<HabitCalendarEntity> { $0.id == id }
    return (try? context.fetch(FetchDescriptor(predicate: predicate))) ?? []
  }

  func fetchEntries(for calendarId: UUID, in context: ModelContext) throws -> [CalendarEntryEntity] {
    let predicate = #Predicate<CalendarEntryEntity> { $0.calendarId == calendarId }
    return try context.fetch(FetchDescriptor(predicate: predicate))
  }

  func fetchEntries(compositeKey: String, in context: ModelContext) throws -> [CalendarEntryEntity] {
    let predicate = #Predicate<CalendarEntryEntity> { $0.compositeKey == compositeKey }
    return try context.fetch(FetchDescriptor(predicate: predicate))
  }

  func activeCalendarCount(excluding excludedId: UUID, in context: ModelContext) -> Int {
    let predicate = #Predicate<HabitCalendarEntity> { !$0.isArchived && $0.id != excludedId }
    return (try? context.fetchCount(FetchDescriptor(predicate: predicate)))
      ?? snapshot.calendars.filter {
        !$0.isArchived && $0.id != excludedId
      }.count
  }

  func persistCalendarOrder(_ orderedCalendars: [CustomCalendar], in context: ModelContext) {
    for calendar in orderedCalendars {
      for entity in fetchCalendarEntities(id: calendar.id, in: context) {
        entity.order = calendar.order
      }
    }
  }

  func persistNormalizedCalendarOrder(in context: ModelContext) throws {
    let entities = try context.fetch(FetchDescriptor<HabitCalendarEntity>())
    let calendars = entities.map { $0.toCustomCalendar(entries: [:]) }
    let normalizedCalendars = Self.normalizedCalendarOrder(calendars)
    let orderById = normalizedCalendars.reduce(into: [UUID: Int]()) { result, calendar in
      result[calendar.id] = min(result[calendar.id] ?? calendar.order, calendar.order)
    }

    for entity in entities {
      if let normalizedOrder = orderById[entity.id], entity.order != normalizedOrder {
        entity.order = normalizedOrder
      }
    }
  }

  func persistChanges(in context: ModelContext) throws {
    if context.hasChanges {
      try context.save()
    }
  }

  func makeContext() -> ModelContext {
    Self.makeContext(container: container)
  }

  nonisolated static func makeContext(container: ModelContainer) -> ModelContext {
    let context = ModelContext(container)
    context.autosaveEnabled = false
    return context
  }

  static func loadDataVersion() -> Int {
    sharedDefaults?.integer(forKey: dataVersionKey) ?? 0
  }

  func publishSnapshot(
    calendars: [CustomCalendar]? = nil,
    isLoading: Bool? = nil,
    dataVersion: Int? = nil
  ) {
    snapshot = CustomCalendarStoreSnapshot(
      calendars: calendars ?? snapshot.calendars,
      isLoading: isLoading ?? snapshot.isLoading,
      dataVersion: dataVersion ?? snapshot.dataVersion
    )
  }

  func reserveNextDataVersion() -> Int {
    versionLock.lock()
    defer { versionLock.unlock() }

    latestPersistedDataVersion &+= 1
    Self.sharedDefaults?.set(latestPersistedDataVersion, forKey: Self.dataVersionKey)
    return latestPersistedDataVersion
  }

  func currentPersistedDataVersion() -> Int {
    versionLock.lock()
    defer { versionLock.unlock() }
    return latestPersistedDataVersion
  }

  func updateLatestReloadToken(_ token: UUID) {
    reloadLock.lock()
    latestReloadToken = token
    reloadLock.unlock()
  }

  func currentReloadToken() -> UUID {
    reloadLock.lock()
    defer { reloadLock.unlock() }
    return latestReloadToken
  }

  private static let dataVersionKey = "CustomCalendarStore.dataVersion"
  private static let sharedDefaults = UserDefaults(suiteName: LegacyPersistenceKeys.appGroupId)
}
