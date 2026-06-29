import Foundation
import SwiftData
import Testing

@testable import SharedModels

@MainActor
@Suite(.serialized)
struct ValuationStoreTests {
  @Test func initLoadsPersistedValuationsSynchronously() throws {
    let container = try makeContainer()
    let date = makeDate(year: 2026, month: 2, day: 4)
    let dayKey = DayKeyFormatter.shared.string(from: LocalDayCalendar.startOfDay(for: date))
    let context = ModelContext(container)
    context.insert(
      DayValuationEntity(
        dayKey: dayKey,
        timestamp: LocalDayCalendar.startOfDay(for: date),
        moodRawValue: DayMood.good.rawValue,
        note: "Already here"
      )
    )
    try context.save()

    let store = ValuationStore(container: container)

    #expect(store.getValuation(for: date)?.mood == .good)
    #expect(store.getValuation(for: date)?.note == "Already here")
  }

  @Test func settingMoodWithoutNotePreservesExistingNote() throws {
    let container = try makeContainer()
    let date = makeDate(year: 2026, month: 3, day: 8)
    let store = ValuationStore(container: container)

    store.setValuation(.good, for: date, note: "Keep this")
    store.setValuation(.bad, for: date)

    #expect(store.getValuation(for: date)?.mood == .bad)
    #expect(store.getValuation(for: date)?.note == "Keep this")
  }

  @Test func loadFailureKeepsCurrentValuations() async throws {
    let container = try makeContainer()
    let date = makeDate(year: 2026, month: 3, day: 9)
    let valuation = DayValuation(date: date, mood: .good, note: "Still here")
    let loader = PlannedValuationLoader([
      .success([valuation.id: valuation]),
      .failure(TestValuationLoadError.failed)
    ])
    let store = ValuationStore(container: container, fetchValuations: loader.makeLoader())

    store.loadValuations()
    try await waitUntil { loader.callCount >= 2 }

    #expect(store.getValuation(for: date)?.mood == .good)
    #expect(store.getValuation(for: date)?.note == "Still here")
  }

  @Test func initCanonicalizesStaleValuationDayKeys() throws {
    let container = try makeContainer()
    let date = makeDate(year: 2026, month: 4, day: 9)
    let context = ModelContext(container)
    context.insert(
      DayValuationEntity(
        dayKey: "stale-key",
        timestamp: LocalDayCalendar.startOfDay(for: date),
        moodRawValue: DayMood.excellent.rawValue,
        note: "Canonical"
      )
    )
    try context.save()

    let store = ValuationStore(container: container)
    let refreshedContext = ModelContext(container)
    let persisted = try #require(refreshedContext.fetch(FetchDescriptor<DayValuationEntity>()).first)

    #expect(store.getValuation(for: date)?.mood == .excellent)
    #expect(store.valuations["stale-key"] == nil)
    #expect(persisted.dayKey == DayKeyFormatter.shared.string(from: LocalDayCalendar.startOfDay(for: date)))
  }

  @Test func setValuationUpdatesStaleRowInsteadOfDuplicating() throws {
    let container = try makeContainer()
    let date = makeDate(year: 2026, month: 5, day: 10)
    let context = ModelContext(container)
    context.insert(
      DayValuationEntity(
        dayKey: "stale-key",
        timestamp: LocalDayCalendar.startOfDay(for: date),
        moodRawValue: DayMood.good.rawValue,
        note: nil
      )
    )
    try context.save()

    let store = ValuationStore(container: container)
    store.setValuation(.bad, for: date, note: "Updated")

    let refreshedContext = ModelContext(container)
    let persisted = try refreshedContext.fetch(FetchDescriptor<DayValuationEntity>())
    let expectedKey = DayKeyFormatter.shared.string(from: LocalDayCalendar.startOfDay(for: date))

    #expect(persisted.count == 1)
    #expect(persisted.first?.dayKey == expectedKey)
    #expect(persisted.first?.moodRawValue == DayMood.bad.rawValue)
    #expect(persisted.first?.note == "Updated")
  }

  @Test func initDeletesDuplicateValuationsForSameCanonicalDay() throws {
    let container = try makeContainer()
    let date = makeDate(year: 2026, month: 6, day: 11)
    let context = ModelContext(container)
    context.insert(
      DayValuationEntity(
        dayKey: "stale-low",
        timestamp: LocalDayCalendar.startOfDay(for: date),
        moodRawValue: DayMood.good.rawValue,
        note: nil
      )
    )
    context.insert(
      DayValuationEntity(
        dayKey: "stale-note",
        timestamp: LocalDayCalendar.startOfDay(for: date),
        moodRawValue: DayMood.excellent.rawValue,
        note: "Keep"
      )
    )
    try context.save()

    let store = ValuationStore(container: container)
    let refreshedContext = ModelContext(container)
    let persisted = try refreshedContext.fetch(FetchDescriptor<DayValuationEntity>())

    #expect(persisted.count == 1)
    #expect(store.getValuation(for: date)?.note == "Keep")
    #expect(store.getValuation(for: date)?.mood == .excellent)
  }
}

@MainActor
private func makeContainer() throws -> ModelContainer {
  let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
  return try ModelContainer(
    for: HabitCalendarEntity.self,
    CalendarEntryEntity.self,
    DayValuationEntity.self,
    HabitStackEntity.self,
    HabitStackStepEntity.self,
    configurations: configuration
  )
}

private func makeDate(year: Int, month: Int, day: Int) -> Date {
  var calendar = Calendar(identifier: .gregorian)
  calendar.locale = Locale(identifier: "en_US_POSIX")
  calendar.timeZone = .autoupdatingCurrent
  return calendar.date(from: DateComponents(year: year, month: month, day: day))!
}

private func waitUntil(_ predicate: @escaping @Sendable () -> Bool) async throws {
  let deadline = Date().addingTimeInterval(3)
  while Date() < deadline {
    if predicate() {
      return
    }
    try await Task.sleep(nanoseconds: 20_000_000)
  }

  Issue.record("Condition was not met before timeout")
  throw CancellationError()
}

private final class PlannedValuationLoader: @unchecked Sendable {
  private let lock = NSLock()
  private var plans: [Result<[String: DayValuation], Error>]
  private(set) var callCount = 0

  init(_ plans: [Result<[String: DayValuation], Error>]) {
    self.plans = plans
  }

  func makeLoader() -> @Sendable (ModelContainer) throws -> [String: DayValuation] {
    { [self] container in
      _ = container
      lock.lock()
      callCount += 1
      let plan = plans.isEmpty ? .success([:]) : plans.removeFirst()
      lock.unlock()
      return try plan.get()
    }
  }
}

private enum TestValuationLoadError: Error {
  case failed
}
