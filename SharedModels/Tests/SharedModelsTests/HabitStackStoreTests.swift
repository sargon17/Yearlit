import Foundation
import SharedModels
import SwiftData
import Testing

@MainActor
@Suite(.serialized)
struct HabitStackStoreTests {
  @Test func deletingThenAddingStacksKeepsContiguousOrder() throws {
    let container = try makeContainer()
    let store = HabitStackStore(container: container)

    store.addStack(try makeStack(name: "A"))
    store.addStack(try makeStack(name: "B"))
    store.addStack(try makeStack(name: "C"))
    let deleted = try #require(store.stacks.first(where: { $0.name == "B" }))

    store.deleteStack(id: deleted.id)
    store.addStack(try makeStack(name: "D"))

    let orderedStacks = store.stacks.sorted { $0.order < $1.order }
    let context = ModelContext(container)
    let persistedOrders = try context.fetch(FetchDescriptor<HabitStackEntity>())
      .map(\.order)
      .sorted()

    #expect(orderedStacks.map(\.name) == ["A", "C", "D"])
    #expect(orderedStacks.map(\.order) == [0, 1, 2])
    #expect(persistedOrders == [0, 1, 2])
  }

  @Test func loadingStackWithDuplicateStepRowsKeepsLatestStep() throws {
    let container = try makeContainer()
    let stackId = UUID()
    let stepId = UUID()
    let oldDate = try #require(makeDate(year: 2026, month: 1, day: 1))
    let newDate = try #require(makeDate(year: 2026, month: 1, day: 2))
    let context = ModelContext(container)

    context.insert(
      HabitStackEntity(
        id: stackId,
        name: "Morning",
        prompt: nil,
        scheduledHour: nil,
        scheduledMinute: nil,
        order: 0,
        createdAt: oldDate,
        updatedAt: oldDate
      )
    )
    context.insert(makeStepEntity(id: stepId, stackId: stackId, title: "Old", updatedAt: oldDate))
    context.insert(makeStepEntity(id: stepId, stackId: stackId, title: "New", updatedAt: newDate))
    try context.save()

    let store = HabitStackStore(container: container)

    let stack = try #require(store.stacks.first)
    #expect(stack.steps.map(\.title) == ["New"])
  }

  @Test func updateStackDeletesDuplicateStepRows() throws {
    let container = try makeContainer()
    let stackId = UUID()
    let stepId = UUID()
    let oldDate = try #require(makeDate(year: 2026, month: 1, day: 1))
    let newDate = try #require(makeDate(year: 2026, month: 1, day: 2))
    let context = ModelContext(container)

    context.insert(
      HabitStackEntity(
        id: stackId,
        name: "Morning",
        prompt: nil,
        scheduledHour: nil,
        scheduledMinute: nil,
        order: 0,
        createdAt: oldDate,
        updatedAt: oldDate
      )
    )
    context.insert(makeStepEntity(id: stepId, stackId: stackId, title: "Old", updatedAt: oldDate))
    context.insert(makeStepEntity(id: stepId, stackId: stackId, title: "New", updatedAt: newDate))
    try context.save()

    let store = HabitStackStore(container: container)
    var stack = try #require(store.stacks.first)
    var step = try #require(stack.steps.first)
    step.title = "Updated"
    stack.steps = [step]
    store.updateStack(stack)

    let refreshedContext = ModelContext(container)
    let persistedSteps = try refreshedContext.fetch(FetchDescriptor<HabitStackStepEntity>())

    #expect(persistedSteps.count == 1)
    #expect(persistedSteps.first?.title == "Updated")
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

private func makeStack(name: String) throws -> HabitStack {
  try HabitStack(
    name: name,
    steps: [
      HabitStackStep(stackId: UUID(), title: "\(name) step")
    ]
  )
}

private func makeStepEntity(
  id: UUID,
  stackId: UUID,
  title: String,
  updatedAt: Date
) -> HabitStackStepEntity {
  HabitStackStepEntity(
    id: id,
    stackId: stackId,
    title: title,
    detail: nil,
    linkedCalendarId: nil,
    order: 0,
    createdAt: updatedAt,
    updatedAt: updatedAt
  )
}

private func makeDate(year: Int, month: Int, day: Int) -> Date? {
  var calendar = Calendar(identifier: .gregorian)
  calendar.locale = Locale(identifier: "en_US_POSIX")
  calendar.timeZone = .autoupdatingCurrent
  return calendar.date(from: DateComponents(year: year, month: month, day: day))
}
