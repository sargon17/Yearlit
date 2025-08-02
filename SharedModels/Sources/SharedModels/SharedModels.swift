import AppIntents
import Foundation
import Observation
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
  public var recurringReminderEnabled: Bool
  public var reminderHour: Int?
  public var reminderMinute: Int?
  public var entries: [String: CalendarEntry]  // Date string -> Entry

  public init(
    id: UUID = UUID(), name: String, color: String, trackingType: TrackingType,
    dailyTarget: Int = 1, entries: [String: CalendarEntry] = [:],
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
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    self.id = formatter.string(from: date)
    self.mood = mood
    self.timestamp = date
  }

  public static func == (lhs: DayValuation, rhs: DayValuation) -> Bool {
    return lhs.id == rhs.id && lhs.mood == rhs.mood
  }
}

// MARK: - Custom Calendar Store

@available(macOS 10.15, *)
public class CustomCalendarStore: ObservableObject {
  public static let shared = CustomCalendarStore()

  private let defaults: UserDefaults
  private let calendarsKey = "customCalendars"
  private let appGroupId = "group.sargon17.My-Year"

  @Published public private(set) var calendars: [CustomCalendar] = []
  @Published public private(set) var isLoading: Bool = false

  public init() {
    UserDefaults.standard.addSuite(named: appGroupId)

    guard let defaults = UserDefaults(suiteName: appGroupId) else {
      fatalError("Failed to initialize UserDefaults with App Group: \(appGroupId)")
    }
    self.defaults = defaults

    loadCalendars()
  }

  public func loadCalendars() {
    isLoading = true
    defer { isLoading = false }

    CFPreferencesAppSynchronize(appGroupId as CFString)

    guard let data = defaults.data(forKey: calendarsKey) else {
      calendars = []
      return
    }

    // Try to decode with new model
    if let decodedCalendars = try? JSONDecoder().decode([CustomCalendar].self, from: data) {
      calendars = decodedCalendars.sorted { $0.order < $1.order }
      return
    }

    // If that fails, try to decode old model and migrate
    struct OldCalendar: Codable {
      let id: UUID
      var name: String
      var color: String
      var trackingType: TrackingType
      var entries: [String: CalendarEntry]
    }

    if let oldCalendars = try? JSONDecoder().decode([OldCalendar].self, from: data) {
      calendars = oldCalendars.enumerated().map { index, old in
        CustomCalendar(
          id: old.id,
          name: old.name,
          color: old.color,
          trackingType: old.trackingType,
          dailyTarget: old.trackingType == .multipleDaily ? 2 : 1,
          entries: old.entries,
          recurringReminderEnabled: false,
          order: index,
          unit: nil,
          defaultRecordValue: nil,
          currencySymbol: nil
        )
      }
      // Save the migrated data
      saveCalendars()
    } else {
      calendars = []
    }
  }

  private func saveCalendars() {
    guard let data = try? JSONEncoder().encode(calendars) else { return }
    defaults.set(data, forKey: calendarsKey)
    defaults.synchronize()
  }

  // MARK: - Calendar Management

  public func addCalendar(_ calendar: CustomCalendar) {
    var newCalendar = calendar
    newCalendar.order = calendars.count
    calendars.append(newCalendar)
    saveCalendars()
  }

  public func updateCalendar(_ calendar: CustomCalendar) {
    guard let index = calendars.firstIndex(where: { $0.id == calendar.id }) else { return }
    calendars[index] = calendar
    saveCalendars()
  }

  public func deleteCalendar(id: UUID) {
    calendars.removeAll { $0.id == id }
    saveCalendars()
  }

  public func moveCalendar(fromOffsets indices: IndexSet, toOffset destination: Int) {
    var newCalendars = calendars
    newCalendars.move(fromOffsets: indices, toOffset: destination)
    for (index, var calendar) in newCalendars.enumerated() {
      calendar.order = index
      newCalendars[index] = calendar
    }
    calendars = newCalendars
    saveCalendars()
  }

  // MARK: - Entry Management

  public func addEntry(calendarId: UUID, entry: CalendarEntry) {
    guard let index = calendars.firstIndex(where: { $0.id == calendarId }) else { return }
    let dateKey = formatDate(date: entry.date)

    var calendar = calendars[index]
    calendar.entries[dateKey] = entry
    calendars[index] = calendar
    saveCalendars()
  }

  public func getEntry(calendarId: UUID, date: Date) -> CalendarEntry? {
    guard let calendar = calendars.first(where: { $0.id == calendarId }) else { return nil }
    let dateKey = formatDate(date: date)
    return calendar.entries[dateKey]
  }

  public func clearEntries(calendarId: UUID) {
    guard let index = calendars.firstIndex(where: { $0.id == calendarId }) else { return }
    calendars[index].entries = [:]
    saveCalendars()
  }

  public func deleteEntry(calendarId: UUID, date: Date) {
    guard let index = calendars.firstIndex(where: { $0.id == calendarId }) else { return }
    let dateKey = formatDate(date: date)
    calendars[index].entries.removeValue(forKey: dateKey)
    saveCalendars()
  }

  private func formatDate(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter.string(from: date)
  }
}

public class ValuationStore: ObservableObject {
  public static let shared = ValuationStore()
  private let appGroupId = "group.sargon17.My-Year"
  private let valuationsKey = "dayValuations"
  private let defaults: UserDefaults
  private var isLoading = false

  @Published public var selectedYear: Int = Calendar.current.component(.year, from: Date())
  @Published public var valuations: [String: DayValuation] = [:] {
    didSet {
      if !isLoading {
        saveValuations()
      }
    }
  }

  // MARK: - Date Calculations

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

  public init() {
    UserDefaults.standard.addSuite(named: appGroupId)

    guard let defaults = UserDefaults(suiteName: appGroupId) else {
      fatalError("Failed to initialize UserDefaults with App Group: \(appGroupId)")
    }
    self.defaults = defaults

    loadValuations()
  }

  public func loadValuations() {
    isLoading = true
    defer { isLoading = false }

    CFPreferencesAppSynchronize(appGroupId as CFString)

    guard let data = defaults.data(forKey: valuationsKey),
      let decoded = try? JSONDecoder().decode([String: DayValuation].self, from: data)
    else {
      return
    }

    if #available(macOS 10.15, *) {
      valuations = decoded
    }
  }

  public func getValuation(for date: Date) -> DayValuation? {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let key = formatter.string(from: date)
    return valuations[key]
  }

  public func setValuation(_ mood: DayMood, for date: Date = Date()) {
    let valuation = DayValuation(date: date, mood: mood)
    var newValuations = valuations
    newValuations[valuation.id] = valuation
    valuations = newValuations

    #if os(iOS)
      WidgetCenter.shared.reloadAllTimelines()
    #endif
  }

  private func saveValuations() {
    guard let encoded = try? JSONEncoder().encode(valuations) else {
      return
    }

    CFPreferencesSetAppValue(
      valuationsKey as CFString,
      encoded as CFData,
      appGroupId as CFString)
    CFPreferencesAppSynchronize(appGroupId as CFString)

    defaults.set(encoded, forKey: valuationsKey)

    #if os(iOS)
      WidgetCenter.shared.reloadAllTimelines()
    #endif
  }

  public func clearAllValuations() {
    valuations = [:]
    defaults.removeObject(forKey: valuationsKey)
    defaults.synchronize()

    #if os(iOS)
      WidgetCenter.shared.reloadAllTimelines()
    #endif
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
