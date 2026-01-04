import AppIntents
import Foundation
import Observation
import SwiftData
import SwiftUI
import WidgetKit

#if canImport(UIKit)
  import UIKit
#endif

// MARK: - Unit of Measure Definition

public enum UnitOfMeasure: String, Codable, CaseIterable, Identifiable {
  public var id: String { rawValue }

  case none = "None"

  // Currency
  case currency = "Currency"

  // Quantity/Count
  case pages = "Pages"
  case items = "Items"
  case rounds = "Rounds"
  case servings = "Servings"
  case doses = "Doses"

  // Distance
  case meters = "m"
  case kilometers = "km"
  case miles = "Miles"
  case steps = "Steps"
  case floors = "Floors"

  // Volume
  case milliliters = "ml"
  case liters = "l"
  case ounces = "oz"
  case cups = "Cups"

  // Time
  case minutes = "Minutes"
  case hours = "Hours"

  // Weight
  case grams = "g"
  case kilograms = "kg"
  case pounds = "Pounds"

  // Energy/Calories
  case calories = "kcal"
  case kilojoules = "kJ"

  public enum Category: String, CaseIterable {
    case quantity = "Quantity/Count"
    case distance = "Distance"
    case volume = "Volume"
    case time = "Time"
    case weight = "Weight"
    case energy = "Energy/Calories"
    case currency = "Currency"
  }

  public var category: Category {
    switch self {
    case .pages, .items, .rounds, .servings, .doses, .none:
      return .quantity
    case .meters, .kilometers, .miles, .steps, .floors:
      return .distance
    case .milliliters, .liters, .ounces, .cups:
      return .volume
    case .minutes, .hours:
      return .time
    case .grams, .kilograms, .pounds:
      return .weight
    case .calories, .kilojoules:
      return .energy
    case .currency:
      return .currency
    }
  }

  // Display name might be different from raw value for units like 'km'
  public var displayName: String {
    switch self {
    case .none: return "Times"
    case .kilometers: return "Kilometers (km)"
    case .meters: return "Meters (m)"
    case .milliliters: return "Milliliters (ml)"
    case .liters: return "Liters (l)"
    case .ounces: return "Ounces (oz)"
    case .grams: return "Grams (g)"
    case .kilograms: return "Kilograms (kg)"
    case .calories: return "Calories (kcal)"
    case .kilojoules: return "Kilojoules (kJ)"
    case .currency: return "Currency"
    default: return rawValue
    }
  }

  public static var allCasesGrouped: [Category: [UnitOfMeasure]] {
    Dictionary(grouping: allCases, by: { $0.category })
  }
}

// MARK: - Custom Calendar Models

public struct CustomCalendar: Codable, Identifiable {
  public let id: UUID
  public var name: String
  public var color: String  // Store as hex or named color
  public var trackingType: TrackingType
  public var dailyTarget: Int
  public var unit: UnitOfMeasure?
  public var currencySymbol: String?
  public var defaultRecordValue: Int?
  public var order: Int = 0
  public var isArchived: Bool
  public var recurringReminderEnabled: Bool
  public var reminderHour: Int?
  public var reminderMinute: Int?
  public var entries: [String: CalendarEntry]  // Date string -> Entry

  public init(
    id: UUID = UUID(), name: String, color: String, trackingType: TrackingType,
    dailyTarget: Int = 1, entries: [String: CalendarEntry] = [:],
    isArchived: Bool = false,
    recurringReminderEnabled: Bool = false, reminderTime: Date? = nil, order: Int = 0,
    unit: UnitOfMeasure? = nil,
    defaultRecordValue: Int? = nil,
    currencySymbol: String? = nil
  ) {
    self.id = id
    self.name = name
    self.color = color
    self.trackingType = trackingType
    self.dailyTarget = dailyTarget
    self.unit = unit
    self.defaultRecordValue = defaultRecordValue
    self.currencySymbol = currencySymbol
    self.isArchived = isArchived
    self.recurringReminderEnabled = recurringReminderEnabled
    self.order = order
    if let time = reminderTime {
      let calendar = Calendar.current
      self.reminderHour = calendar.component(.hour, from: time)
      self.reminderMinute = calendar.component(.minute, from: time)
    } else {
      self.reminderHour = nil
      self.reminderMinute = nil
    }
    self.entries = entries
  }

  // New initializer using hour and minute directly
  public init(
    id: UUID = UUID(), name: String, color: String, trackingType: TrackingType,
    dailyTarget: Int = 1, entries: [String: CalendarEntry] = [:],
    isArchived: Bool = false,
    recurringReminderEnabled: Bool = false, reminderHour: Int? = nil, reminderMinute: Int? = nil,
    order: Int = 0,
    unit: UnitOfMeasure? = nil,
    defaultRecordValue: Int? = nil,
    currencySymbol: String? = nil
  ) throws {
    // Validate hour and minute ranges
    if let hour = reminderHour, let minute = reminderMinute {
      guard (0...23).contains(hour) else {
        throw ValidationError.invalidHour(hour)
      }
      guard (0...59).contains(minute) else {
        throw ValidationError.invalidMinute(minute)
      }
    }
    self.id = id
    self.name = name
    self.color = color
    self.trackingType = trackingType
    self.dailyTarget = dailyTarget
    self.unit = unit
    self.defaultRecordValue = defaultRecordValue
    self.currencySymbol = currencySymbol
    self.isArchived = isArchived
    self.recurringReminderEnabled = recurringReminderEnabled
    self.order = order
    self.reminderHour = reminderHour
    self.reminderMinute = reminderMinute
    self.entries = entries
  }
}

public enum TrackingType: String, Codable, CaseIterable {
  /// A binary tracking type: done or not done (once per day).
  case binary

  /// A counter tracking type: unlimited times per day (GitHub-style count).
  case counter

  /// A multiple-daily tracking type: fixed number of times per day (with target).
  case multipleDaily

  public var description: String {
    switch self {
    case .binary:
      return "Once a day"
    case .counter:
      return "Multiple times (unlimited)"
    case .multipleDaily:
      return "Multiple times (with target)"
    }
  }

  public var icon: String {
    switch self {
    case .binary: return "checkmark.circle"
    case .counter: return "chevron.up.forward.dotted.2"
    case .multipleDaily: return "target"
    }
  }

  public var label: String {
    switch self {
    case .binary: return "binary"
    case .counter: return "counter"
    case .multipleDaily: return "target"
    }
  }

  public var detailDescription: String {
    switch self {
    case .binary:
      return "Track a simple yes/no each day. Great for habits you either complete or skip."
    case .counter:
      return "Log a numeric value per day, like pages read or minutes practiced."
    case .multipleDaily:
      return "Check in multiple times per day toward a daily target."
    }
  }

  @available(iOS 17.0, macOS 13.0, *)
  public static var allCasesDisplayRepresentations: [TrackingType: DisplayRepresentation] {
    [
      .binary: "Once a day (binary)",
      .counter: "Multiple times (unlimited) (counter)",
      .multipleDaily: "Multiple times (with target) (multipleDaily)"
    ]
  }
}

public struct CalendarEntry: Codable {
  public let date: Date
  public var count: Int
  public var completed: Bool

  public init(date: Date, count: Int = 0, completed: Bool = false) {
    self.date = date
    self.count = count
    self.completed = completed
  }
}

public enum DayMood: String, Codable {
  case terrible = "😫"
  case bad = "😞"
  case neutral = "😐"
  case good = "😊"
  case excellent = "🤩"

  public var color: String {
    switch self {
    case .terrible: return "mood-terrible"
    case .bad: return "mood-bad"
    case .neutral: return "mood-neutral"
    case .good: return "mood-good"
    case .excellent: return "mood-excellent"
    }
  }
}

public enum DayMoodType: Hashable {
  case mood(DayMood)  // Wraps the existing DayMood cases
  case notEvaluated  // For days that could be evaluated but weren't
  case future  // For future days

  // Helper to convert DayMood to this type
  static func from(_ mood: DayMood) -> DayMoodType {
    return .mood(mood)
  }

  var color: String {
    switch self {
    case .mood(let mood):
      return mood.color
    case .notEvaluated:
      return "dot-active"
    case .future:
      return "dot-inactive"
    }
  }

  // Add sorting priority
  var sortOrder: Int {
    switch self {
    case .mood(let mood):
      switch mood {
      case .terrible: return 0
      case .bad: return 1
      case .neutral: return 2
      case .good: return 3
      case .excellent: return 4
      }
    case .notEvaluated: return 5
    case .future: return 6
    }
  }
}

public struct DayValuation: Codable, Identifiable, Equatable {
  public let id: String  // Format: "YYYY-MM-DD"
  public let mood: DayMood
  public let timestamp: Date

  public init(date: Date = Date(), mood: DayMood) {
    self.id = DayKeyFormatter.shared.string(from: date)
    self.mood = mood
    self.timestamp = date
  }

  public static func == (lhs: DayValuation, rhs: DayValuation) -> Bool {
    return lhs.id == rhs.id && lhs.mood == rhs.mood
  }
}

// MARK: - Custom Calendar Store

@available(iOS 17.0, macOS 14.0, *)
public final class CustomCalendarStore: ObservableObject {
  public static let shared = CustomCalendarStore()

  @Published public private(set) var calendars: [CustomCalendar] = []
  @Published public private(set) var isLoading: Bool = false
  @Published public private(set) var dataVersion: Int = 0

  private let container: ModelContainer

  public init(container: ModelContainer = SwiftDataManager.container) {
    self.container = container
    dataVersion = Self.loadDataVersion()

    isLoading = true
    let container = container
    Task.detached(priority: .userInitiated) { [weak self] in
      LegacyDataMigrator.migrateIfNeeded(container: container)
      do {
        let calendars = try Self.fetchCalendars(container: container)
        await MainActor.run {
          guard let self else { return }
          self.calendars = calendars
          self.isLoading = false
        }
      } catch {
        NSLog("Failed to load calendars from SwiftData: \(error)")
        await MainActor.run {
          guard let self else { return }
          self.calendars = []
          self.isLoading = false
        }
      }
    }
  }

  public func loadCalendars(showLoadingIndicator: Bool = true) {
    if showLoadingIndicator {
      Task { @MainActor in
        self.isLoading = true
      }
    }

    let container = container
    Task.detached(priority: .userInitiated) { [weak self] in
      do {
        let calendars = try Self.fetchCalendars(container: container)
        await MainActor.run {
          guard let self else { return }
          self.calendars = calendars
          if showLoadingIndicator {
            self.isLoading = false
          }
        }
      } catch {
        NSLog("Failed to load calendars from SwiftData: \(error)")
        await MainActor.run {
          guard let self else { return }
          self.calendars = []
          if showLoadingIndicator {
            self.isLoading = false
          }
        }
      }
    }
  }

  // MARK: - Calendar Management

  public func addCalendar(_ calendar: CustomCalendar) {
    var newCalendar = calendar
    newCalendar.order = calendars.count

    do {
      let context = makeContext()
      let entity = HabitCalendarEntity.make(from: newCalendar)
      context.insert(entity)

      for (dayKey, entry) in newCalendar.entries {
        let entryEntity = CalendarEntryEntity(
          compositeKey: CalendarEntryEntity.makeCompositeKey(calendarId: entity.id, dayKey: dayKey),
          calendarId: entity.id,
          dayKey: dayKey,
          date: entry.date,
          count: entry.count,
          completed: entry.completed
        )
        context.insert(entryEntity)
      }

      try persistChanges(in: context)
      bumpDataVersion()
    } catch {
      NSLog("Failed to add calendar: \(error)")
    }
    loadCalendars(showLoadingIndicator: false)
  }

  public func updateCalendar(_ calendar: CustomCalendar) {
    do {
      let context = makeContext()
      guard let entity = fetchCalendarEntity(id: calendar.id, in: context) else { return }
      entity.apply(from: calendar)

      let existingEntries = try fetchEntries(for: calendar.id, in: context)
      var existingByKey = existingEntries.reduce(into: [String: CalendarEntryEntity]()) { partialResult, entry in
        if let existing = partialResult[entry.dayKey] {
          if entry.date > existing.date {
            partialResult[entry.dayKey] = entry
          }
        } else {
          partialResult[entry.dayKey] = entry
        }
      }

      for (key, entryModel) in calendar.entries {
        if let entryEntity = existingByKey.removeValue(forKey: key) {
          entryEntity.apply(from: entryModel, calendarId: calendar.id, overrideDayKey: key)
        } else {
          let entryEntity = CalendarEntryEntity(
            compositeKey: CalendarEntryEntity.makeCompositeKey(calendarId: calendar.id, dayKey: key),
            calendarId: calendar.id,
            dayKey: key,
            date: entryModel.date,
            count: entryModel.count,
            completed: entryModel.completed
          )
          context.insert(entryEntity)
        }
      }

      for redundant in existingByKey.values {
        context.delete(redundant)
      }

      try persistChanges(in: context)
      bumpDataVersion()
      loadCalendars(showLoadingIndicator: false)
    } catch {
      NSLog("Failed to update calendar: \(error)")
    }
  }

  public func deleteCalendar(id: UUID) {
    do {
      let context = makeContext()
      guard let entity = fetchCalendarEntity(id: id, in: context) else { return }
      let entries = try fetchEntries(for: id, in: context)
      for entry in entries {
        context.delete(entry)
      }
      context.delete(entity)
      try persistChanges(in: context)
      bumpDataVersion()
      loadCalendars(showLoadingIndicator: false)
    } catch {
      NSLog("Failed to delete calendar: \(error)")
    }
  }

  public func moveCalendar(fromOffsets indices: IndexSet, toOffset destination: Int) {
    var reordered = calendars
    reordered.move(fromOffsets: indices, toOffset: destination)

    do {
      let context = makeContext()
      for (index, var calendar) in reordered.enumerated() {
        calendar.order = index
        reordered[index] = calendar
        if let entity = fetchCalendarEntity(id: calendar.id, in: context) {
          entity.order = index
        }
      }

      calendars = reordered
      bumpDataVersion()
      try persistChanges(in: context)
      loadCalendars(showLoadingIndicator: false)
    } catch {
      NSLog("Failed to move calendars: \(error)")
    }
  }

  public func moveActiveCalendars(fromOffsets indices: IndexSet, toOffset destination: Int) {
    let orderedCalendars = calendars.sorted { $0.order < $1.order }
    let activeCalendars = orderedCalendars.filter { !$0.isArchived }
    guard !activeCalendars.isEmpty else { return }

    var reorderedActive = activeCalendars
    reorderedActive.move(fromOffsets: indices, toOffset: destination)

    var activeIterator = reorderedActive.makeIterator()
    var reorderedAll: [CustomCalendar] = []
    reorderedAll.reserveCapacity(orderedCalendars.count)

    for calendar in orderedCalendars {
      if calendar.isArchived {
        reorderedAll.append(calendar)
      } else if let next = activeIterator.next() {
        reorderedAll.append(next)
      }
    }

    do {
      let context = makeContext()
      for (index, var calendar) in reorderedAll.enumerated() {
        calendar.order = index
        reorderedAll[index] = calendar
        if let entity = fetchCalendarEntity(id: calendar.id, in: context) {
          entity.order = index
        }
      }

      calendars = reorderedAll
      bumpDataVersion()
      try persistChanges(in: context)
      loadCalendars(showLoadingIndicator: false)
    } catch {
      NSLog("Failed to move active calendars: \(error)")
    }
  }

  // MARK: - Entry Management

  public func addEntry(calendarId: UUID, entry: CalendarEntry) {
    do {
      let context = makeContext()
      guard fetchCalendarEntity(id: calendarId, in: context) != nil else { return }
      let dayKey = formatDate(date: entry.date)
      let compositeKey = CalendarEntryEntity.makeCompositeKey(calendarId: calendarId, dayKey: dayKey)

      if let entryEntity = fetchEntry(compositeKey: compositeKey, in: context) {
        entryEntity.apply(from: entry, calendarId: calendarId, overrideDayKey: dayKey)
      } else {
        let entryEntity = CalendarEntryEntity(
          compositeKey: compositeKey,
          calendarId: calendarId,
          dayKey: dayKey,
          date: entry.date,
          count: entry.count,
          completed: entry.completed
        )
        context.insert(entryEntity)
      }

      try persistChanges(in: context)
      bumpDataVersion()
      loadCalendars(showLoadingIndicator: false)
    } catch {
      NSLog("Failed to add entry: \(error)")
    }
  }

  public func getEntry(calendarId: UUID, date: Date) -> CalendarEntry? {
    let context = makeContext()
    let dayKey = formatDate(date: date)
    let compositeKey = CalendarEntryEntity.makeCompositeKey(calendarId: calendarId, dayKey: dayKey)
    return fetchEntry(compositeKey: compositeKey, in: context)?.toCalendarEntry()
  }

  public func clearEntries(calendarId: UUID) {
    do {
      let context = makeContext()
      let entries = try fetchEntries(for: calendarId, in: context)
      for entry in entries {
        context.delete(entry)
      }
      try persistChanges(in: context)
      bumpDataVersion()
      loadCalendars(showLoadingIndicator: false)
    } catch {
      NSLog("Failed to clear entries: \(error)")
    }
  }

  public func deleteEntry(calendarId: UUID, date: Date) {
    do {
      let context = makeContext()
      let dayKey = formatDate(date: date)
      let compositeKey = CalendarEntryEntity.makeCompositeKey(calendarId: calendarId, dayKey: dayKey)
      guard let target = fetchEntry(compositeKey: compositeKey, in: context) else { return }
      context.delete(target)
      try persistChanges(in: context)
      bumpDataVersion()
      loadCalendars(showLoadingIndicator: false)
    } catch {
      NSLog("Failed to delete entry: \(error)")
    }
  }

  private func fetchCalendarEntity(id: UUID, in context: ModelContext) -> HabitCalendarEntity? {
    let predicate = #Predicate<HabitCalendarEntity> { $0.id == id }
    var descriptor = FetchDescriptor(predicate: predicate)
    descriptor.fetchLimit = 1
    return try? context.fetch(descriptor).first
  }

  private func fetchEntries(for calendarId: UUID, in context: ModelContext) throws -> [CalendarEntryEntity] {
    let predicate = #Predicate<CalendarEntryEntity> { $0.calendarId == calendarId }
    return try context.fetch(FetchDescriptor(predicate: predicate))
  }

  private func fetchEntry(compositeKey: String, in context: ModelContext) -> CalendarEntryEntity? {
    let predicate = #Predicate<CalendarEntryEntity> { $0.compositeKey == compositeKey }
    var descriptor = FetchDescriptor(predicate: predicate)
    descriptor.fetchLimit = 1
    return try? context.fetch(descriptor).first
  }

  private func persistChanges(in context: ModelContext) throws {
    if context.hasChanges {
      try context.save()
    }
  }

  private func makeContext() -> ModelContext {
    Self.makeContext(container: container)
  }

  private static func makeContext(container: ModelContainer) -> ModelContext {
    let context = ModelContext(container)
    context.autosaveEnabled = false
    return context
  }

  private func formatDate(date: Date) -> String {
    DayKeyFormatter.shared.string(from: date)
  }

  private static let dataVersionKey = "CustomCalendarStore.dataVersion"

  private static func loadDataVersion() -> Int {
    UserDefaults.standard.integer(forKey: dataVersionKey)
  }

  private func bumpDataVersion() {
    dataVersion &+= 1
    UserDefaults.standard.set(dataVersion, forKey: Self.dataVersionKey)
  }

  private static func fetchCalendars(container: ModelContainer) throws -> [CustomCalendar] {
    let context = makeContext(container: container)
    let calendarsDescriptor = FetchDescriptor<HabitCalendarEntity>(
      sortBy: [SortDescriptor(\HabitCalendarEntity.order)]
    )
    let calendarEntities = try context.fetch(calendarsDescriptor)
    let entryEntities = try context.fetch(FetchDescriptor<CalendarEntryEntity>())
    let groupedEntries = Dictionary(grouping: entryEntities, by: { $0.calendarId })

    let deduplicatedCalendars = calendarEntities.reduce(into: [UUID: CustomCalendar]()) { partialResult, entity in
      let entries = groupedEntries[entity.id, default: []]
        .reduce(into: [String: CalendarEntry]()) { partialEntries, entry in
          let key = entry.dayKey
          let converted = entry.toCalendarEntry()
          if let existing = partialEntries[key] {
            if converted.date > existing.date {
              partialEntries[key] = converted
            }
          } else {
            partialEntries[key] = converted
          }
        }

      let calendar = entity.toCustomCalendar(entries: entries)
      if let existing = partialResult[calendar.id] {
        if calendar.order < existing.order {
          partialResult[calendar.id] = calendar
        }
      } else {
        partialResult[calendar.id] = calendar
      }
    }

    return deduplicatedCalendars.values.sorted { $0.order < $1.order }
  }
}

@available(iOS 17.0, macOS 14.0, *)
public final class ValuationStore: ObservableObject {
  public static let shared = ValuationStore()

  @Published public var selectedYear: Int = Calendar.current.component(.year, from: Date())
  @Published public private(set) var valuations: [String: DayValuation] = [:]

  private let container: ModelContainer

  // MARK: - Date Calculations
  // TODO: Remove this function (LEGACY)
  public func dateForDay(_ day: Int) -> Date {
    let calendar = Calendar.current
    let startOfYear = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1))!
    return calendar.date(byAdding: .day, value: day, to: startOfYear)!
  }

  public var year: Int {
    selectedYear
  }

  public var currentDayNumber: Int {
    let calendar = Calendar.current
    let today = Date()
    let currentYear = calendar.component(.year, from: today)

    if selectedYear > currentYear {
      return 0
    } else if selectedYear < currentYear {
      return numberOfDaysInYear
    }

    return calendar.ordinality(of: .day, in: .year, for: today) ?? 0
  }

  public var numberOfDaysInYear: Int {
    let calendar = Calendar.current
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

  public init(container: ModelContainer = SwiftDataManager.container) {
    self.container = container

    let container = container
    Task.detached(priority: .userInitiated) { [weak self] in
      LegacyDataMigrator.migrateIfNeeded(container: container)
      do {
        let valuations = try Self.fetchValuations(container: container)
        await MainActor.run {
          guard let self else { return }
          self.valuations = valuations
        }
      } catch {
        NSLog("Failed to load valuations: \(error)")
        await MainActor.run {
          guard let self else { return }
          self.valuations = [:]
        }
      }
    }
  }

  public func loadValuations() {
    let container = container
    Task.detached(priority: .userInitiated) { [weak self] in
      do {
        let valuations = try Self.fetchValuations(container: container)
        await MainActor.run {
          guard let self else { return }
          self.valuations = valuations
        }
      } catch {
        NSLog("Failed to load valuations: \(error)")
        await MainActor.run {
          guard let self else { return }
          self.valuations = [:]
        }
      }
    }
  }

  public func getValuation(for date: Date) -> DayValuation? {
    let key = DayKeyFormatter.shared.string(from: date)
    return valuations[key]
  }

  public func setValuation(_ mood: DayMood, for date: Date = Date()) {
    let valuation = DayValuation(date: date, mood: mood)
    do {
      let context = makeContext()
      if let entity = fetchEntity(dayKey: valuation.id, in: context) {
        entity.apply(from: valuation)
      } else {
        let entity = DayValuationEntity(
          dayKey: valuation.id,
          timestamp: valuation.timestamp,
          moodRawValue: valuation.mood.rawValue
        )
        context.insert(entity)
      }

      try persistChanges(in: context)

      var newValuations = valuations
      newValuations[valuation.id] = valuation
      valuations = newValuations

      #if os(iOS)
        WidgetReload.scheduleAllTimelinesReload()
      #endif
    } catch {
      NSLog("Failed to set valuation: \(error)")
    }
  }

  public func clearAllValuations() {
    do {
      let context = makeContext()
      let descriptor = FetchDescriptor<DayValuationEntity>()
      let entities = try context.fetch(descriptor)
      for entity in entities {
        context.delete(entity)
      }
      try persistChanges(in: context)
      valuations = [:]

      #if os(iOS)
        WidgetReload.scheduleAllTimelinesReload()
      #endif
    } catch {
      NSLog("Failed to clear valuations: \(error)")
    }
  }

  private func fetchEntity(dayKey: String, in context: ModelContext) -> DayValuationEntity? {
    let predicate = #Predicate<DayValuationEntity> { $0.dayKey == dayKey }
    var descriptor = FetchDescriptor(predicate: predicate)
    descriptor.fetchLimit = 1
    return try? context.fetch(descriptor).first
  }

  private func persistChanges(in context: ModelContext) throws {
    if context.hasChanges {
      try context.save()
    }
  }

  private func makeContext() -> ModelContext {
    Self.makeContext(container: container)
  }

  private static func makeContext(container: ModelContainer) -> ModelContext {
    let context = ModelContext(container)
    context.autosaveEnabled = false
    return context
  }

  private static func fetchValuations(container: ModelContainer) throws -> [String: DayValuation] {
    let context = makeContext(container: container)
    let descriptor = FetchDescriptor<DayValuationEntity>(
      sortBy: [SortDescriptor(\DayValuationEntity.dayKey)]
    )
    let entities = try context.fetch(descriptor)
    return entities.reduce(into: [String: DayValuation]()) { partialResult, entity in
      let valuation = entity.toDayValuation()
      if let existing = partialResult[entity.dayKey] {
        if valuation.timestamp > existing.timestamp {
          partialResult[entity.dayKey] = valuation
        }
      } else {
        partialResult[entity.dayKey] = valuation
      }
    }
  }
}

public enum VisualizationType: String, Codable, AppEnum {
  case full
  case pastOnly
  case evaluatedOnly

  @available(macOS 13.0, *)
  public static var typeDisplayRepresentation: TypeDisplayRepresentation {
    "Visualization Type"
  }

  @available(macOS 13.0, *)
  public static var caseDisplayRepresentations: [VisualizationType: DisplayRepresentation] {
    [
      .full: "Full Year",
      .pastOnly: "Past Days Only",
      .evaluatedOnly: "Evaluated Days Only"
    ]
  }
}

@available(macOS 10.15, *)
public struct MosaicChart: View {
  public let dayTypesQuantity: [DayMoodType: Int]

  @State var visualizationType: VisualizationType = .full

  public init(dayTypesQuantity: [DayMoodType: Int], visualizationType: VisualizationType? = nil) {
    self.dayTypesQuantity = dayTypesQuantity
    self.visualizationType = visualizationType ?? .full
  }

  public var sortedEntries: [(type: DayMoodType, count: Int)] {
    dayTypesQuantity.sorted { lhs, rhs in
      switch (lhs.key, rhs.key) {
      case (.mood(let m1), .mood(let m2)):
        return m1.rawValue < m2.rawValue
      case (.mood, _):
        return true
      case (_, .mood):
        return false
      case (.notEvaluated, .future):
        return true
      case (.future, .notEvaluated):
        return false
      default:
        return true
      }
    }
    .map { (type: $0.key, count: $0.value) }
  }

  public var filteredEntries: [(type: DayMoodType, count: Int)] {
    sortedEntries.filter { entry in
      switch visualizationType {
      case .full: return true
      case .pastOnly: return entry.type != .future
      case .evaluatedOnly:
        if case .mood(_) = entry.type {
          return true
        }
        return false
      }
    }
  }

  public var body: some View {
    VStack {
      GeometryReader { geometry in
        let availableWidth = geometry.size.width

        HStack(spacing: 2) {
          ForEach(filteredEntries, id: \.type) { entry in
            RoundedRectangle(cornerRadius: 3)
              .fill(Color(entry.type.color))
              .frame(
                width: calculateWidth(for: entry, availableWidth: availableWidth), height: .infinity
              )
          }
          .transition(
            .asymmetric(
              insertion: .scale.combined(with: .opacity),
              removal: .scale.combined(with: .opacity)
            ))
        }
        .animation(.spring(duration: 0.3, bounce: 0.2), value: visualizationType)
        .animation(.spring(duration: 0.3, bounce: 0.2), value: filteredEntries.map { $0.count })
      }
    }
    .frame(height: .infinity)
    .padding(.trailing)
    .onTapGesture {
      withAnimation {
        handleTap()
      }

      #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
      #endif
    }
  }

  public func handleTap() {
    if visualizationType == .full {
      visualizationType = .pastOnly
    } else if visualizationType == .pastOnly {
      visualizationType = .evaluatedOnly
    } else if visualizationType == .evaluatedOnly {
      visualizationType = .full
    }
  }

  public func calculateWidth(for entry: (type: DayMoodType, count: Int), availableWidth: CGFloat)
    -> CGFloat
  {
    let totalCount = filteredEntries.reduce(0) { $0 + $1.count }
    return availableWidth * CGFloat(entry.count) / CGFloat(totalCount)
  }
}

@available(iOS 17.0, macOS 14.0, *)
public func updateDayTypesQuantity(store: ValuationStore) -> [DayMoodType: Int] {
  let evaluatedDays = store.valuations.values.reduce(into: [:]) { counts, valuation in
    counts[DayMoodType.from(valuation.mood), default: 0] += 1
  }

  let notEvaluatedDays = store.currentDayNumber - store.valuations.count
  let futureDays = store.numberOfDaysInYear - store.currentDayNumber

  var quantities = evaluatedDays
  quantities[DayMoodType.notEvaluated] = notEvaluatedDays
  quantities[DayMoodType.future] = futureDays

  return quantities
}

// Add the following error type above the CustomCalendar struct
public enum ValidationError: Error {
  case invalidHour(Int)
  case invalidMinute(Int)
}
