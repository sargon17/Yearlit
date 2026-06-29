import Foundation
import Observation
import SwiftData
import WidgetKit

@available(iOS 17.0, macOS 14.0, *)
@MainActor
public final class CustomCalendarStore: ObservableObject {
  public static let shared = CustomCalendarStore()

  @Published public internal(set) var snapshot: CustomCalendarStoreSnapshot

  let container: ModelContainer
  private let fetchCalendarsLoader: @Sendable (ModelContainer) throws -> [CustomCalendar]
  private let migrationRunner: @Sendable (ModelContainer) -> Void
  private let fetchCalendarShellsLoader: @Sendable (ModelContainer) throws -> [CustomCalendar]
  let reloadLock = NSLock()
  let versionLock = NSLock()
  var latestReloadToken = UUID()
  var latestPersistedDataVersion: Int

  public init(
    container: ModelContainer = SwiftDataManager.container,
    dependencies: CustomCalendarStoreDependencies? = nil
  ) {
    let dependencies =
      dependencies
      ?? CustomCalendarStoreDependencies(
        fetchCalendars: { container in
          try Self.fetchCalendars(container: container)
        },
        runMigration: { container in
          LegacyDataMigrator.migrateIfNeeded(container: container)
        },
        fetchCalendarShells: { container in
          try Self.fetchCalendarShells(container: container)
        }
      )
    self.container = container
    fetchCalendarsLoader = dependencies.fetchCalendars
    migrationRunner = dependencies.runMigration
    fetchCalendarShellsLoader = dependencies.fetchCalendarShells
    let initialVersion = Self.loadDataVersion()
    latestPersistedDataVersion = initialVersion
    migrationRunner(container)
    let initialCalendars = Self.initialCalendars(
      container: container,
      fetchCalendarShells: fetchCalendarShellsLoader,
      fetchCalendars: fetchCalendarsLoader
    )
    snapshot = CustomCalendarStoreSnapshot(
      calendars: initialCalendars,
      isLoading: true,
      dataVersion: initialVersion
    )
    loadCalendars(showLoadingIndicator: true, targetVersion: initialVersion)
  }

  private static func initialCalendars(
    container: ModelContainer,
    fetchCalendarShells: (ModelContainer) throws -> [CustomCalendar],
    fetchCalendars: (ModelContainer) throws -> [CustomCalendar]
  ) -> [CustomCalendar] {
    do {
      return try fetchCalendarShells(container)
    } catch {
      NSLog("Failed to load calendar shells from SwiftData: \(error)")
    }

    do {
      return try fetchCalendars(container)
    } catch {
      NSLog("Failed to load initial calendars from SwiftData: \(error)")
      return []
    }
  }

}

@available(iOS 17.0, macOS 14.0, *)
@MainActor
extension CustomCalendarStore {
  public func loadCalendars(showLoadingIndicator: Bool = true) {
    loadCalendars(
      showLoadingIndicator: showLoadingIndicator,
      targetVersion: currentPersistedDataVersion()
    )
  }

  private func loadCalendars(showLoadingIndicator: Bool, targetVersion: Int, runMigration: Bool = false) {
    let token = UUID()
    updateLatestReloadToken(token)

    if showLoadingIndicator {
      Task { @MainActor in
        guard token == self.currentReloadToken() else { return }
        self.publishSnapshot(isLoading: true)
      }
    }

    let container = container
    let fetchCalendarsLoader = fetchCalendarsLoader
    let migrationRunner = migrationRunner
    Task.detached(priority: .userInitiated) { [weak self] in
      do {
        if runMigration {
          migrationRunner(container)
        }

        let calendars = try fetchCalendarsLoader(container)
        await self?.finishLoadingCalendars(
          token: token,
          calendars: calendars,
          targetVersion: targetVersion
        )
      } catch {
        NSLog("Failed to load calendars from SwiftData: \(error)")
        await self?.finishLoadingCalendarsAfterFailure(token: token)
      }
    }
  }

  private func finishLoadingCalendars(
    token: UUID,
    calendars: [CustomCalendar],
    targetVersion: Int
  ) {
    guard token == currentReloadToken() else { return }
    if calendars.isEmpty, !snapshot.calendars.isEmpty, targetVersion <= snapshot.dataVersion {
      publishSnapshot(isLoading: false)
      return
    }
    publishSnapshot(calendars: calendars, isLoading: false, dataVersion: targetVersion)
  }

  private func finishLoadingCalendarsAfterFailure(token: UUID) {
    guard token == currentReloadToken() else { return }
    publishSnapshot(isLoading: false)
  }

  // MARK: - Calendar Management

  public func addCalendar(_ calendar: CustomCalendar) {
    var newCalendar = calendar
    newCalendar.order =
      calendar.isArchived
      ? snapshot.calendars.count
      : snapshot.calendars.filter { !$0.isArchived }.count

    do {
      let context = makeContext()
      let entity = HabitCalendarEntity.make(from: newCalendar)
      context.insert(entity)

      for entry in newCalendar.entries.values {
        let target = entryPersistenceTarget(
          calendarId: entity.id,
          date: entry.date,
          cadence: newCalendar.cadence
        )
        context.insertEntry(
          CalendarEntry(date: target.date, count: entry.count, completed: entry.completed),
          target: target
        )
      }

      try finishHabitMutationFetchingSnapshot(in: context)
    } catch {
      NSLog("Failed to add calendar: \(error)")
    }
  }

  public func updateCalendar(_ calendar: CustomCalendar) {
    do {
      let context = makeContext()
      let entities = fetchCalendarEntities(id: calendar.id, in: context)
      guard let entity = entities.first else { return }
      let isAppleHealthCalendar = entity.isAppleHealthSource
      let calendarToSave = calendarForPersistence(calendar, matching: entity, in: context)

      for entity in entities {
        entity.apply(from: calendarToSave)
      }

      let existingEntries = try fetchEntries(for: calendarToSave.id, in: context)
      if isAppleHealthCalendar {
        updateAppleHealthCompletionState(existingEntries, dailyTarget: calendarToSave.dailyTarget)
      } else {
        syncEntries(for: calendarToSave, existingEntries: existingEntries, in: context)
      }

      try persistNormalizedCalendarOrder(in: context)
      try finishHabitMutationReloadingCalendars(in: context)
    } catch {
      NSLog("Failed to update calendar: \(error)")
    }
  }

  public func deleteCalendar(id: UUID) {
    do {
      let context = makeContext()
      let entities = fetchCalendarEntities(id: id, in: context)
      guard !entities.isEmpty else { return }
      let entries = try fetchEntries(for: id, in: context)
      for entry in entries {
        context.delete(entry)
      }
      for entity in entities {
        context.delete(entity)
      }
      try finishHabitMutationReloadingCalendars(in: context)
    } catch {
      NSLog("Failed to delete calendar: \(error)")
    }
  }

  @MainActor public func moveCalendar(fromOffsets indices: IndexSet, toOffset destination: Int) {
    var reordered = Self.normalizedCalendarOrder(snapshot.calendars)
    reordered.move(fromOffsets: indices, toOffset: destination)
    reordered = Self.assigningContiguousOrder(to: reordered)

    do {
      let context = makeContext()
      persistCalendarOrder(reordered, in: context)
      try finishHabitMutationPublishingSnapshot(reordered, in: context)
    } catch {
      NSLog("Failed to move calendars: \(error)")
    }
  }

  @MainActor public func moveActiveCalendars(fromOffsets indices: IndexSet, toOffset destination: Int) {
    let reordered = Self.reorderedActiveCalendars(
      snapshot.calendars,
      fromOffsets: indices,
      toOffset: destination
    )

    do {
      let context = makeContext()
      persistCalendarOrder(reordered, in: context)
      try finishHabitMutationPublishingSnapshot(reordered, in: context)
    } catch {
      NSLog("Failed to move active calendars: \(error)")
    }
  }

  private func calendarForPersistence(
    _ calendar: CustomCalendar,
    matching entity: HabitCalendarEntity,
    in context: ModelContext
  ) -> CustomCalendar {
    var calendarToSave = calendar
    calendarToSave.source = entity.calendarSource

    if let metric = AppleHealthMetric(source: entity.calendarSource) {
      calendarToSave.cadence = .daily
      calendarToSave.trackingType = .binary
      calendarToSave.trackingStartedAt = entity.trackingStartedAt
      calendarToSave.dailyTarget = max(1, calendarToSave.dailyTarget)
      calendarToSave.unit = metric.unit
      calendarToSave.defaultRecordValue = nil
      calendarToSave.currencySymbol = nil
      calendarToSave.recurringReminderEnabled = false
      calendarToSave.reminderHour = nil
      calendarToSave.reminderMinute = nil
      calendarToSave.reminderWeekday = nil
      calendarToSave.additionalReminderTimes = []
      calendarToSave.suppressWhenCompleted = false
      calendarToSave.streakProtectionEnabled = false
    }

    if entity.isArchived, !calendar.isArchived {
      calendarToSave.order = activeCalendarCount(excluding: calendar.id, in: context)
    }

    return calendarToSave
  }

  func finishHabitMutationReloadingCalendars(in context: ModelContext) throws {
    try persistChanges(in: context)
    let nextVersion = reserveNextDataVersion()
    loadCalendars(showLoadingIndicator: false, targetVersion: nextVersion)
    WidgetReload.scheduleHabitWidgetsReload()
  }

  private func finishHabitMutationFetchingSnapshot(in context: ModelContext) throws {
    try persistChanges(in: context)
    let nextVersion = reserveNextDataVersion()
    let calendars = try fetchCalendarsLoader(container)
    publishSnapshot(calendars: calendars, isLoading: false, dataVersion: nextVersion)
    WidgetReload.scheduleHabitWidgetsReload()
  }

  private func finishHabitMutationPublishingSnapshot(
    _ calendars: [CustomCalendar],
    in context: ModelContext
  ) throws {
    try persistChanges(in: context)
    publishSnapshot(calendars: calendars)
    WidgetReload.scheduleHabitWidgetsReload()
  }

}
