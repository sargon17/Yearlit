import Foundation
import Observation
import SwiftData

@available(iOS 17.0, macOS 14.0, *)
@MainActor
public final class HabitStackStore: ObservableObject {
  public static let shared = HabitStackStore()

  @Published public private(set) var stacks: [HabitStack] = []
  @Published public private(set) var isLoading: Bool = false

  private let container: ModelContainer
  private var latestReloadToken = UUID()

  public init(container: ModelContainer = SwiftDataManager.container) {
    self.container = container
    do {
      stacks = try Self.fetchStacks(container: container)
    } catch {
      NSLog("Failed to load habit stacks: \(error)")
    }
  }

  public func loadStacks(showLoadingIndicator: Bool = true) {
    let token = UUID()
    latestReloadToken = token

    if showLoadingIndicator {
      isLoading = true
    }

    let container = container
    Task.detached(priority: .userInitiated) { [weak self] in
      do {
        let stacks = try Self.fetchStacks(container: container)
        await self?.finishLoadingStacks(stacks, token: token, showLoadingIndicator: showLoadingIndicator)
      } catch {
        NSLog("Failed to load habit stacks: \(error)")
        await self?.finishLoadingStacks(token: token, showLoadingIndicator: showLoadingIndicator)
      }
    }
  }

  private func finishLoadingStacks(_ stacks: [HabitStack], token: UUID, showLoadingIndicator: Bool) {
    guard token == latestReloadToken else { return }
    self.stacks = stacks
    if showLoadingIndicator {
      isLoading = false
    }
  }

  private func finishLoadingStacks(token: UUID, showLoadingIndicator: Bool) {
    guard token == latestReloadToken else { return }
    if showLoadingIndicator {
      isLoading = false
    }
  }

  public func addStack(_ stack: HabitStack) {
    do {
      var prepared = try stack.validated()
      prepared.order = stacks.count
      let now = Date()
      prepared.createdAt = now
      prepared.updatedAt = now

      let context = makeContext()
      let entity = HabitStackEntity.make(from: prepared)
      context.insert(entity)
      for step in prepared.steps {
        let stepEntity = HabitStackStepEntity.make(from: step, stackId: prepared.id)
        context.insert(stepEntity)
      }
      try normalizeStackOrder(in: context)
      try finishMutationFetchingStacks(in: context)
    } catch {
      NSLog("Failed to add habit stack: \(error)")
    }
  }

  public func updateStack(_ stack: HabitStack) {
    do {
      var prepared = try stack.validated()
      prepared.updatedAt = Date()

      let context = makeContext()
      guard let entity = fetchStackEntity(id: prepared.id, in: context) else { return }
      entity.apply(from: prepared)

      let existingSteps = try fetchSteps(for: prepared.id, in: context)
      let existingSelection = Self.deduplicatedStepEntities(existingSteps)
      var existingById = existingSelection.kept
      for duplicate in existingSelection.duplicates {
        context.delete(duplicate)
      }

      for step in prepared.steps {
        if let stepEntity = existingById.removeValue(forKey: step.id) {
          stepEntity.apply(from: step, stackId: prepared.id)
        } else {
          let newEntity = HabitStackStepEntity.make(from: step, stackId: prepared.id)
          context.insert(newEntity)
        }
      }

      for orphan in existingById.values {
        context.delete(orphan)
      }

      try finishMutationFetchingStacks(in: context)
    } catch {
      NSLog("Failed to update habit stack: \(error)")
    }
  }

  public func deleteStack(id: UUID) {
    do {
      let context = makeContext()
      guard let entity = fetchStackEntity(id: id, in: context) else { return }
      let stepEntities = try fetchSteps(for: id, in: context)
      for step in stepEntities {
        context.delete(step)
      }
      context.delete(entity)
      try normalizeStackOrder(in: context)
      try finishMutationFetchingStacks(in: context)
    } catch {
      NSLog("Failed to delete habit stack: \(error)")
    }
  }

  public func moveStack(fromOffsets indices: IndexSet, toOffset destination: Int) {
    var reordered = stacks
    moveElements(&reordered, fromOffsets: indices, toOffset: destination)

    do {
      let context = makeContext()
      for (newOrder, var stack) in reordered.enumerated() {
        stack.order = newOrder
        stack.updatedAt = Date()
        if let entity = fetchStackEntity(id: stack.id, in: context) {
          entity.order = newOrder
          entity.updatedAt = stack.updatedAt
        }
      }
      try finishMutationFetchingStacks(in: context)
    } catch {
      NSLog("Failed to reorder habit stacks: \(error)")
    }
  }

  public func addStep(_ step: HabitStackStep, toStackWithId stackId: UUID) {
    guard var stack = stacks.first(where: { $0.id == stackId }) else { return }
    do {
      try stack.appendStep(step)
      updateStack(stack)
    } catch {
      NSLog("Failed to append step to stack \(stackId): \(error)")
    }
  }

  public func updateStep(_ step: HabitStackStep, inStackWithId stackId: UUID) {
    guard var stack = stacks.first(where: { $0.id == stackId }) else { return }
    guard let index = stack.steps.firstIndex(where: { $0.id == step.id }) else { return }
    var updatedStep = step.withStackId(stackId)
    updatedStep.order = stack.steps[index].order
    updatedStep.touchUpdatedAt()
    stack.steps[index] = updatedStep
    stack.steps = HabitStack.normalizedSteps(stack.steps, stackId: stackId)
    stack.updatedAt = Date()
    updateStack(stack)
  }

  public func removeStep(withId stepId: UUID, fromStackWithId stackId: UUID) {
    guard var stack = stacks.first(where: { $0.id == stackId }) else { return }
    stack.removeStep(id: stepId)
    updateStack(stack)
  }

  public func moveStep(
    inStackWithId stackId: UUID,
    fromOffsets indices: IndexSet,
    toOffset destination: Int
  ) {
    guard var stack = stacks.first(where: { $0.id == stackId }) else { return }
    var orderedSteps = stack.stepsSorted
    moveElements(&orderedSteps, fromOffsets: indices, toOffset: destination)
    stack.steps = HabitStack.normalizedSteps(orderedSteps, stackId: stackId)
    stack.updatedAt = Date()
    updateStack(stack)
  }

  private func fetchStackEntity(id: UUID, in context: ModelContext) -> HabitStackEntity? {
    let predicate = #Predicate<HabitStackEntity> { $0.id == id }
    var descriptor = FetchDescriptor(predicate: predicate)
    descriptor.fetchLimit = 1
    return try? context.fetch(descriptor).first
  }

  private func fetchSteps(for stackId: UUID, in context: ModelContext) throws -> [HabitStackStepEntity] {
    let predicate = #Predicate<HabitStackStepEntity> { $0.stackId == stackId }
    let descriptor = FetchDescriptor(predicate: predicate)
    return try context.fetch(descriptor)
  }

  private func persistChanges(in context: ModelContext) throws {
    if context.hasChanges {
      try context.save()
    }
  }

  private func normalizeStackOrder(in context: ModelContext) throws {
    let descriptor = FetchDescriptor<HabitStackEntity>(
      sortBy: [
        SortDescriptor(\HabitStackEntity.order),
        SortDescriptor(\HabitStackEntity.createdAt)
      ]
    )
    let entities = try context.fetch(descriptor)
    for (order, entity) in entities.enumerated() where entity.order != order {
      entity.order = order
    }
  }

  private func finishMutationFetchingStacks(in context: ModelContext) throws {
    latestReloadToken = UUID()
    try persistChanges(in: context)
    stacks = try Self.fetchStacks(container: container)
  }

  private func makeContext() -> ModelContext {
    Self.makeContext(container: container)
  }

  private nonisolated static func makeContext(container: ModelContainer) -> ModelContext {
    let context = ModelContext(container)
    context.autosaveEnabled = false
    return context
  }

  private nonisolated static func fetchStacks(container: ModelContainer) throws -> [HabitStack] {
    let context: ModelContext = makeContext(container: container)
    let stackDescriptor = FetchDescriptor<HabitStackEntity>(
      sortBy: [
        SortDescriptor(\HabitStackEntity.order),
        SortDescriptor(\HabitStackEntity.createdAt)
      ]
    )
    let stepDescriptor = FetchDescriptor<HabitStackStepEntity>(
      sortBy: [
        SortDescriptor(\HabitStackStepEntity.stackId),
        SortDescriptor(\HabitStackStepEntity.order)
      ]
    )
    let stackEntities = try context.fetch(stackDescriptor)
    let stepEntities = try context.fetch(stepDescriptor)
    let groupedSteps = Dictionary(grouping: stepEntities, by: { $0.stackId })

    return stackEntities.map { entity in
      let steps = deduplicatedStepEntities(groupedSteps[entity.id, default: []])
        .kept
        .values
        .map { $0.toHabitStackStep() }
      return entity.toHabitStack(steps: steps)
    }
  }

  private nonisolated static func deduplicatedStepEntities(
    _ steps: [HabitStackStepEntity]
  ) -> (kept: [UUID: HabitStackStepEntity], duplicates: [HabitStackStepEntity]) {
    steps.reduce(
      into: (kept: [UUID: HabitStackStepEntity](), duplicates: [HabitStackStepEntity]())
    ) { result, step in
      guard let existing = result.kept[step.id] else {
        result.kept[step.id] = step
        return
      }

      if shouldPrefer(step, over: existing) {
        result.kept[step.id] = step
        result.duplicates.append(existing)
      } else {
        result.duplicates.append(step)
      }
    }
  }

  private nonisolated static func shouldPrefer(
    _ candidate: HabitStackStepEntity,
    over existing: HabitStackStepEntity
  ) -> Bool {
    if candidate.updatedAt != existing.updatedAt {
      return candidate.updatedAt > existing.updatedAt
    }
    if candidate.order != existing.order {
      return candidate.order < existing.order
    }
    return candidate.createdAt > existing.createdAt
  }

  private func moveElements<T>(
    _ elements: inout [T],
    fromOffsets offsets: IndexSet,
    toOffset destination: Int
  ) {
    guard !offsets.isEmpty else { return }
    let moving = offsets.sorted().map { elements[$0] }
    for index in offsets.sorted(by: >) {
      elements.remove(at: index)
    }
    var insertionIndex = destination
    let removedBeforeDestination = offsets.filter { $0 < destination }.count
    insertionIndex -= removedBeforeDestination
    insertionIndex = max(0, min(insertionIndex, elements.count))
    elements.insert(contentsOf: moving, at: insertionIndex)
  }
}
