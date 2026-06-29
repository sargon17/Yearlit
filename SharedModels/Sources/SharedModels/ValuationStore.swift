import AppIntents
import Foundation
import Observation
import SwiftData
import SwiftUI
import WidgetKit

#if canImport(UIKit)
  import UIKit
#endif

@available(iOS 17.0, macOS 14.0, *)
public final class ValuationStore: ObservableObject {
  public static let shared = ValuationStore()

  @Published public var selectedYear: Int = LocalDayCalendar.calendar.component(.year, from: Date())
  @Published public private(set) var valuations: [String: DayValuation] = [:]

  private let container: ModelContainer
  private let fetchValuationsLoader: @Sendable (ModelContainer) throws -> [String: DayValuation]
  private let reloadLock = NSLock()
  private var latestReloadToken = UUID()
  private var localCalendar: Calendar {
    LocalDayCalendar.calendar
  }

  public var year: Int {
    selectedYear
  }

  public var currentDayNumber: Int {
    let calendar = localCalendar
    let today = calendar.startOfDay(for: Date())
    let currentYear = calendar.component(.year, from: today)

    if selectedYear > currentYear {
      return 0
    } else if selectedYear < currentYear {
      return numberOfDaysInYear
    }

    guard
      let startOfYear = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1))
    else {
      return 0
    }

    let dayOffset = calendar.dateComponents([.day], from: startOfYear, to: today).day ?? 0
    return dayOffset + 1
  }

  public var numberOfDaysInYear: Int {
    let calendar = localCalendar
    let startOfYear = DateComponents(year: selectedYear, month: 1, day: 1)
    let endOfYear = DateComponents(year: selectedYear, month: 12, day: 31)
    guard let startDate = calendar.date(from: startOfYear),
      let endDate = calendar.date(from: endOfYear)
    else {
      return 365
    }
    let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 365
    return days + 1
  }

  // MARK: - Initialization

  public convenience init(container: ModelContainer = SwiftDataManager.container) {
    self.init(
      container: container,
      fetchValuations: { container in
        try Self.fetchValuations(container: container)
      }
    )
  }

  init(
    container: ModelContainer,
    fetchValuations: @escaping @Sendable (ModelContainer) throws -> [String: DayValuation]
  ) {
    self.container = container
    fetchValuationsLoader = fetchValuations

    LegacyDataMigrator.migrateIfNeeded(container: container)
    do {
      valuations = try fetchValuations(container)
    } catch {
      NSLog("Failed to load valuations: \(error)")
    }
  }

  public func loadValuations() {
    let token = UUID()
    updateLatestReloadToken(token)
    let container = container
    let fetchValuationsLoader = fetchValuationsLoader
    Task.detached(priority: .userInitiated) { [weak self] in
      do {
        let valuations = try fetchValuationsLoader(container)
        await self?.replaceValuations(valuations, token: token)
      } catch {
        NSLog("Failed to load valuations: \(error)")
        await self?.finishLoadingAfterFailure(token: token)
      }
    }
  }

  @MainActor
  private func replaceValuations(_ valuations: [String: DayValuation], token: UUID) {
    guard token == currentReloadToken() else { return }
    self.valuations = valuations
  }

  @MainActor
  private func finishLoadingAfterFailure(token: UUID) {
    guard token == currentReloadToken() else { return }
  }

  public nonisolated static func fetchValuationsSnapshot(
    container: ModelContainer = SwiftDataManager.container
  ) -> [String: DayValuation] {
    (try? fetchValuations(container: container)) ?? [:]
  }

  public func getValuation(for date: Date) -> DayValuation? {
    let canonicalDate = LocalDayCalendar.startOfDay(for: date)
    let key = DayKeyFormatter.shared.string(from: canonicalDate)
    return valuations[key]
  }

  public func setValuation(_ mood: DayMood, for date: Date = Date()) {
    setValuation(mood, for: date, note: nil)
  }

  public func setValuation(_ mood: DayMood, for date: Date = Date(), note: String?) {
    let existingNote = getValuation(for: date)?.note
    let cleanedNote = note.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    let resolvedNote = note == nil ? existingNote : (cleanedNote?.isEmpty == true ? nil : cleanedNote)
    let valuation = DayValuation(date: date, mood: mood, note: resolvedNote)
    do {
      let context = makeContext()
      let matchingEntities = try fetchEntities(matching: valuation, in: context)
      if let entity = Self.preferredEntity(from: matchingEntities) {
        entity.apply(from: valuation)
        for duplicate in matchingEntities where duplicate !== entity {
          context.delete(duplicate)
        }
      } else {
        let entity = DayValuationEntity(
          dayKey: valuation.id,
          timestamp: valuation.timestamp,
          moodRawValue: valuation.mood.rawValue,
          note: valuation.note
        )
        context.insert(entity)
      }

      var newValuations = valuations
      newValuations[valuation.id] = valuation
      try finishValuationMutation(in: context, valuations: newValuations)
    } catch {
      NSLog("Failed to set valuation: \(error)")
    }
  }

  private func fetchEntities(
    matching valuation: DayValuation,
    in context: ModelContext
  ) throws -> [DayValuationEntity] {
    try context.fetch(FetchDescriptor<DayValuationEntity>()).filter { entity in
      entity.dayKey == valuation.id
        || LocalDayCalendar.startOfDay(for: entity.timestamp) == valuation.timestamp
    }
  }

  private func persistChanges(in context: ModelContext) throws {
    if context.hasChanges {
      try context.save()
    }
  }

  private func finishValuationMutation(
    in context: ModelContext,
    valuations: [String: DayValuation]
  ) throws {
    invalidatePendingReloads()
    try persistChanges(in: context)
    self.valuations = valuations

    #if os(iOS)
      WidgetReload.scheduleYearWidgetReload()
    #endif
  }

  private func makeContext() -> ModelContext {
    Self.makeContext(container: container)
  }

  private static func makeContext(container: ModelContainer) -> ModelContext {
    let context = ModelContext(container)
    context.autosaveEnabled = false
    return context
  }

  private func invalidatePendingReloads() {
    updateLatestReloadToken(UUID())
  }

  private func updateLatestReloadToken(_ token: UUID) {
    reloadLock.lock()
    latestReloadToken = token
    reloadLock.unlock()
  }

  private func currentReloadToken() -> UUID {
    reloadLock.lock()
    defer { reloadLock.unlock() }
    return latestReloadToken
  }

  private static func fetchValuations(container: ModelContainer) throws -> [String: DayValuation] {
    let context = makeContext(container: container)
    let descriptor = FetchDescriptor<DayValuationEntity>(
      sortBy: [SortDescriptor(\DayValuationEntity.dayKey)]
    )
    let entities = try context.fetch(descriptor)
    let selection = entities.reduce(
      into: (kept: [String: DayValuationEntity](), duplicates: [DayValuationEntity]())
    ) { result, entity in
      let key = entity.toDayValuation().id
      guard let existing = result.kept[key] else {
        result.kept[key] = entity
        return
      }

      if shouldPrefer(entity, over: existing) {
        result.kept[key] = entity
        result.duplicates.append(existing)
      } else {
        result.duplicates.append(entity)
      }
    }

    for duplicate in selection.duplicates {
      context.delete(duplicate)
    }

    let valuations = selection.kept.reduce(into: [String: DayValuation]()) { result, item in
      let valuation = item.value.toDayValuation()
      if item.value.dayKey != valuation.id {
        item.value.dayKey = valuation.id
      }
      result[valuation.id] = valuation
    }

    if context.hasChanges {
      try context.save()
    }

    return valuations
  }

  private static func preferredEntity(from entities: [DayValuationEntity]) -> DayValuationEntity? {
    entities.reduce(nil) { selected, entity in
      guard let selected else { return entity }
      return shouldPrefer(entity, over: selected) ? entity : selected
    }
  }

  private static func shouldPrefer(
    _ candidate: DayValuationEntity,
    over existing: DayValuationEntity
  ) -> Bool {
    if candidate.timestamp != existing.timestamp {
      return candidate.timestamp > existing.timestamp
    }
    if candidate.note != nil, existing.note == nil {
      return true
    }
    return false
  }
}
