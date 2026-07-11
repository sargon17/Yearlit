import Foundation
import SwiftData
import Testing

@testable import SharedModels

struct PersistenceContractTests {
  @MainActor
  @Test func backupRestorePreservesCompletePersistenceContract() throws {
    let fixture = try Fixture()
    try fixture.seed()
    let backup = try fixture.service.createProtectiveBackup(reason: .beforeBulkChange)

    try fixture.deleteAll()
    try fixture.service.restoreBackup(id: backup.id)

    let context = ModelContext(fixture.container)
    let calendar = try #require(context.fetch(FetchDescriptor<HabitCalendarEntity>()).first)
    let entry = try #require(context.fetch(FetchDescriptor<CalendarEntryEntity>()).first)
    let valuation = try #require(context.fetch(FetchDescriptor<DayValuationEntity>()).first)
    let stack = try #require(context.fetch(FetchDescriptor<HabitStackEntity>()).first)
    let step = try #require(context.fetch(FetchDescriptor<HabitStackStepEntity>()).first)

    fixture.expectCalendar(calendar)
    fixture.expectEntry(entry)
    fixture.expectValuation(valuation)
    fixture.expectStack(stack)
    fixture.expectStep(step)
  }

  @MainActor
  private final class Fixture {
    let calendarId: UUID
    let stackId: UUID
    let stepId: UUID
    let trackingStartedAt: Date
    let entryDate: Date
    let valuationDate: Date
    let createdAt: Date
    let updatedAt: Date
    let container: ModelContainer
    let service: DataBackupService

    var entryDayKey: String { DayKeyFormatter.shared.string(from: entryDate) }
    var valuationDayKey: String { DayKeyFormatter.shared.string(from: valuationDate) }

    init() throws {
      calendarId = try #require(UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"))
      stackId = try #require(UUID(uuidString: "11111111-2222-3333-4444-555555555555"))
      stepId = try #require(UUID(uuidString: "66666666-7777-8888-9999-AAAAAAAAAAAA"))
      trackingStartedAt = try #require(Self.makeDate(year: 2025, month: 12, day: 29))
      entryDate = try #require(Self.makeDate(year: 2026, month: 1, day: 5))
      valuationDate = try #require(Self.makeDate(year: 2026, month: 1, day: 6))
      createdAt = try #require(Self.makeDate(year: 2025, month: 12, day: 1))
      updatedAt = try #require(Self.makeDate(year: 2026, month: 1, day: 7))
      container = try ModelContainer(
        for: HabitCalendarEntity.self,
        CalendarEntryEntity.self,
        DayValuationEntity.self,
        HabitStackEntity.self,
        HabitStackStepEntity.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
      )
      let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
      service = DataBackupService(container: container, directoryURL: directory)
    }

    func seed() throws {
      let context = ModelContext(container)
      context.autosaveEnabled = false
      let calendar = try CustomCalendar(
        id: calendarId,
        name: "Complete",
        color: "qs-purple",
        cadence: .weekly,
        trackingType: .multipleDaily,
        trackingStartedAt: trackingStartedAt,
        dailyTarget: 7,
        entries: [entryDayKey: CalendarEntry(date: entryDate, count: 5, completed: false)],
        isArchived: true,
        recurringReminderEnabled: true,
        reminderHour: 21,
        reminderMinute: 15,
        reminderWeekday: 6,
        order: 4,
        unit: .pages,
        defaultRecordValue: 3,
        currencySymbol: "€",
        reminderTimeZone: "Europe/Rome",
        notificationPrivacyMode: .generic,
        suppressWhenCompleted: false,
        additionalReminderTimes: [ReminderTime(hour: 8, minute: 30)],
        streakProtectionEnabled: false,
        streakProtectionThreshold: 12,
        source: .manual
      )
      context.insert(HabitCalendarEntity.make(from: calendar))
      context.insert(CalendarEntryEntity(
        compositeKey: CalendarEntryEntity.makeCompositeKey(calendarId: calendarId, dayKey: entryDayKey),
        calendarId: calendarId,
        dayKey: entryDayKey,
        date: entryDate,
        count: 5,
        completed: false
      ))
      context.insert(DayValuationEntity(
        dayKey: valuationDayKey,
        timestamp: valuationDate,
        moodRawValue: DayMood.excellent.rawValue,
        note: "Kept note"
      ))
      context.insert(HabitStackEntity(
        id: stackId,
        name: "Evening",
        prompt: "Wind down",
        scheduledHour: 22,
        scheduledMinute: 30,
        order: 2,
        createdAt: createdAt,
        updatedAt: updatedAt
      ))
      context.insert(HabitStackStepEntity(
        id: stepId,
        stackId: stackId,
        title: "Read",
        detail: "Ten pages",
        linkedCalendarId: calendarId,
        order: 1,
        createdAt: createdAt,
        updatedAt: updatedAt
      ))
      try context.save()
    }

    func expectCalendar(_ calendar: HabitCalendarEntity) {
      #expect(calendar.id == calendarId)
      #expect(calendar.name == "Complete")
      #expect(calendar.color == "qs-purple")
      #expect(calendar.cadenceRawValue == CalendarCadence.weekly.rawValue)
      #expect(calendar.trackingTypeRawValue == TrackingType.multipleDaily.rawValue)
      #expect(calendar.trackingStartedAt == LocalDayCalendar.startOfDay(for: trackingStartedAt))
      #expect(calendar.dailyTarget == 7)
      #expect(calendar.unitRawValue == UnitOfMeasure.pages.rawValue)
      #expect(calendar.defaultRecordValue == 3)
      #expect(calendar.currencySymbol == "€")
      #expect(calendar.isArchived)
      #expect(calendar.recurringReminderEnabled)
      #expect(calendar.reminderHour == 21)
      #expect(calendar.reminderMinute == 15)
      #expect(calendar.reminderWeekday == 6)
      #expect(calendar.reminderTimeZone == "Europe/Rome")
      #expect(calendar.notificationPrivacyModeRawValue == NotificationPrivacyMode.generic.rawValue)
      #expect(!calendar.suppressWhenCompleted)
      #expect(calendar.additionalReminderTimesJSON?.contains("8") == true)
      #expect(!calendar.streakProtectionEnabled)
      #expect(calendar.streakProtectionThreshold == 12)
      #expect(calendar.sourceRawValue == CalendarSource.manual.rawValue)
      #expect(calendar.order == 0)
    }

    func expectEntry(_ entry: CalendarEntryEntity) {
      #expect(entry.compositeKey == CalendarEntryEntity.makeCompositeKey(
        calendarId: calendarId,
        dayKey: entryDayKey
      ))
      #expect(entry.calendarId == calendarId)
      #expect(entry.dayKey == entryDayKey)
      #expect(entry.date == entryDate)
      #expect(entry.count == 5)
      #expect(!entry.completed)
    }

    func expectValuation(_ valuation: DayValuationEntity) {
      #expect(valuation.dayKey == valuationDayKey)
      #expect(valuation.timestamp == LocalDayCalendar.startOfDay(for: valuationDate))
      #expect(valuation.moodRawValue == DayMood.excellent.rawValue)
      #expect(valuation.note == "Kept note")
    }

    func expectStack(_ stack: HabitStackEntity) {
      #expect(stack.id == stackId)
      #expect(stack.name == "Evening")
      #expect(stack.prompt == "Wind down")
      #expect(stack.scheduledHour == 22)
      #expect(stack.scheduledMinute == 30)
      #expect(stack.order == 2)
      #expect(stack.createdAt == createdAt)
      #expect(stack.updatedAt == updatedAt)
    }

    func expectStep(_ step: HabitStackStepEntity) {
      #expect(step.id == stepId)
      #expect(step.stackId == stackId)
      #expect(step.title == "Read")
      #expect(step.detail == "Ten pages")
      #expect(step.linkedCalendarId == calendarId)
      #expect(step.order == 0)
      #expect(step.createdAt == createdAt)
      #expect(step.updatedAt == updatedAt)
    }

    func deleteAll() throws {
      let context = ModelContext(container)
      for entity in try context.fetch(FetchDescriptor<HabitCalendarEntity>()) { context.delete(entity) }
      for entity in try context.fetch(FetchDescriptor<CalendarEntryEntity>()) { context.delete(entity) }
      for entity in try context.fetch(FetchDescriptor<DayValuationEntity>()) { context.delete(entity) }
      for entity in try context.fetch(FetchDescriptor<HabitStackEntity>()) { context.delete(entity) }
      for entity in try context.fetch(FetchDescriptor<HabitStackStepEntity>()) { context.delete(entity) }
      try context.save()
    }

    private static func makeDate(year: Int, month: Int, day: Int) -> Date? {
      var calendar = Calendar(identifier: .gregorian)
      calendar.locale = Locale(identifier: "en_US_POSIX")
      calendar.timeZone = .gmt
      return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }
  }
}
