import Foundation
import Observation
import SwiftData

public enum HabitStackValidationError: Error {
    case invalidHour(Int)
    case invalidMinute(Int)
    case incompleteTime
    case duplicatedStepIdentifiers
}

public struct HabitStackStep: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var stackId: UUID
    public var title: String
    public var detail: String?
    public var linkedCalendarId: UUID?
    public var order: Int
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        stackId: UUID,
        title: String,
        detail: String? = nil,
        linkedCalendarId: UUID? = nil,
        order: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.stackId = stackId
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetail = detail?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.detail = trimmedDetail?.isEmpty == true ? nil : trimmedDetail
        self.linkedCalendarId = linkedCalendarId
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isLinkedToCalendar: Bool {
        linkedCalendarId != nil
    }

    public mutating func touchUpdatedAt(date: Date = Date()) {
        updatedAt = date
    }

    public func withStackId(_ stackId: UUID) -> HabitStackStep {
        var copy = self
        copy.stackId = stackId
        return copy
    }

    public func withOrder(_ order: Int) -> HabitStackStep {
        var copy = self
        copy.order = order
        return copy
    }

    public func updating(title: String, detail: String? = nil, linkedCalendarId: UUID? = nil) -> HabitStackStep {
        HabitStackStep(
            id: id,
            stackId: stackId,
            title: title,
            detail: detail,
            linkedCalendarId: linkedCalendarId,
            order: order,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}

public struct HabitStack: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var prompt: String?
    public var scheduledHour: Int?
    public var scheduledMinute: Int?
    public var order: Int
    public var createdAt: Date
    public var updatedAt: Date
    public var steps: [HabitStackStep]

    public init(
        id: UUID = UUID(),
        name: String,
        prompt: String? = nil,
        scheduledHour: Int? = nil,
        scheduledMinute: Int? = nil,
        order: Int = 0,
        steps: [HabitStackStep] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) throws {
        try self.init(
            id: id,
            name: name,
            prompt: prompt,
            scheduledHour: scheduledHour,
            scheduledMinute: scheduledMinute,
            order: order,
            steps: steps,
            createdAt: createdAt,
            updatedAt: updatedAt,
            enforceValidation: true
        )
    }

    init(
        id: UUID,
        name: String,
        prompt: String?,
        scheduledHour: Int?,
        scheduledMinute: Int?,
        order: Int,
        steps: [HabitStackStep],
        createdAt: Date,
        updatedAt: Date,
        enforceValidation: Bool
    ) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPrompt = prompt?.trimmingCharacters(in: .whitespacesAndNewlines)

        if enforceValidation {
            try HabitStack.validateSchedule(hour: scheduledHour, minute: scheduledMinute)
            try HabitStack.validateSteps(steps)
        }

        self.id = id
        self.name = trimmedName.isEmpty ? name : trimmedName
        if let trimmedPrompt, !trimmedPrompt.isEmpty {
            self.prompt = trimmedPrompt
        } else {
            self.prompt = nil
        }
        self.scheduledHour = scheduledHour
        self.scheduledMinute = scheduledMinute
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.steps = HabitStack.normalizedSteps(steps, stackId: id)
    }

    init(
        uncheckedId id: UUID,
        name: String,
        prompt: String?,
        scheduledHour: Int?,
        scheduledMinute: Int?,
        order: Int,
        steps: [HabitStackStep],
        createdAt: Date,
        updatedAt: Date
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPrompt = prompt?.trimmingCharacters(in: .whitespacesAndNewlines)

        self.id = id
        self.name = trimmedName.isEmpty ? name : trimmedName
        if let trimmedPrompt, !trimmedPrompt.isEmpty {
            self.prompt = trimmedPrompt
        } else {
            self.prompt = nil
        }
        self.scheduledHour = scheduledHour
        self.scheduledMinute = scheduledMinute
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.steps = HabitStack.normalizedSteps(steps, stackId: id)
    }

    public var hasSchedule: Bool {
        scheduledHour != nil && scheduledMinute != nil
    }

    public var scheduledTimeComponents: DateComponents? {
        guard let hour = scheduledHour, let minute = scheduledMinute else { return nil }
        return DateComponents(hour: hour, minute: minute)
    }

    public var stepsSorted: [HabitStackStep] {
        steps.sorted { lhs, rhs in
            if lhs.order == rhs.order {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.order < rhs.order
        }
    }

    public var isEmpty: Bool {
        steps.isEmpty
    }

    public func step(withId id: HabitStackStep.ID) -> HabitStackStep? {
        steps.first { $0.id == id }
    }

    public func indexOfStep(_ id: HabitStackStep.ID) -> Int? {
        stepsSorted.firstIndex { $0.id == id }
    }

    public func containsStep(_ id: HabitStackStep.ID) -> Bool {
        step(withId: id) != nil
    }

    public func nextStep(after stepId: HabitStackStep.ID?) -> HabitStackStep? {
        let sorted = stepsSorted
        guard let stepId else {
            return sorted.first
        }
        guard let index = sorted.firstIndex(where: { $0.id == stepId }) else {
            return sorted.first
        }
        let nextIndex = sorted.index(after: index)
        return nextIndex < sorted.endIndex ? sorted[nextIndex] : nil
    }

    public func previousStep(before stepId: HabitStackStep.ID?) -> HabitStackStep? {
        let sorted = stepsSorted
        guard let stepId else { return nil }
        guard let index = sorted.firstIndex(where: { $0.id == stepId }) else { return nil }
        guard index > sorted.startIndex else { return nil }
        let previousIndex = sorted.index(before: index)
        return sorted[previousIndex]
    }

    public mutating func updateSchedule(hour: Int?, minute: Int?) throws {
        try HabitStack.validateSchedule(hour: hour, minute: minute)
        scheduledHour = hour
        scheduledMinute = minute
        updatedAt = Date()
    }

    public mutating func clearSchedule() {
        scheduledHour = nil
        scheduledMinute = nil
        updatedAt = Date()
    }

    public mutating func replaceSteps(_ newSteps: [HabitStackStep]) throws {
        try HabitStack.validateSteps(newSteps)
        steps = HabitStack.normalizedSteps(newSteps, stackId: id)
        updatedAt = Date()
    }

    public mutating func appendStep(_ step: HabitStackStep) throws {
        var normalized = step.withStackId(id)
        normalized.order = steps.count
        normalized.createdAt = Date()
        normalized.updatedAt = Date()
        var proposal = steps
        proposal.append(normalized)
        try replaceSteps(proposal)
    }

    public mutating func removeStep(id stepId: HabitStackStep.ID) {
        guard containsStep(stepId) else { return }
        steps.removeAll { $0.id == stepId }
        steps = HabitStack.normalizedSteps(steps, stackId: id)
        updatedAt = Date()
    }

    public func validated() throws -> HabitStack {
        try HabitStack(
            id: id,
            name: name,
            prompt: prompt,
            scheduledHour: scheduledHour,
            scheduledMinute: scheduledMinute,
            order: order,
            steps: steps,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func normalizedSteps(_ steps: [HabitStackStep], stackId: UUID) -> [HabitStackStep] {
        let reassigned = steps.map { $0.withStackId(stackId) }
        let sorted = reassigned.sorted { lhs, rhs in
            if lhs.order == rhs.order {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.order < rhs.order
        }
        return sorted.enumerated().map { index, element in
            var copy = element
            copy.order = index
            return copy
        }
    }

    private static func validateSchedule(hour: Int?, minute: Int?) throws {
        if hour == nil, minute == nil {
            return
        }
        guard let hour = hour, let minute = minute else {
            throw HabitStackValidationError.incompleteTime
        }
        guard (0 ... 23).contains(hour) else {
            throw HabitStackValidationError.invalidHour(hour)
        }
        guard (0 ... 59).contains(minute) else {
            throw HabitStackValidationError.invalidMinute(minute)
        }
    }

    private static func validateSteps(_ steps: [HabitStackStep]) throws {
        let identifiers = steps.map(\.id)
        if Set(identifiers).count != identifiers.count {
            throw HabitStackValidationError.duplicatedStepIdentifiers
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
@MainActor
public final class HabitStackStore: ObservableObject {
    public static let shared = HabitStackStore()

    @Published public private(set) var stacks: [HabitStack] = []
    @Published public private(set) var isLoading: Bool = false

    private let container: ModelContainer

    public init(container: ModelContainer = SwiftDataManager.container) {
        self.container = container
        loadStacks(showLoadingIndicator: false)
    }

    public func loadStacks(showLoadingIndicator: Bool = true) {
        if showLoadingIndicator {
            isLoading = true
        }

        let container = container
        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                let stacks = try Self.fetchStacks(container: container)
                await MainActor.run {
                    guard let self else { return }
                    self.stacks = stacks
                    if showLoadingIndicator {
                        self.isLoading = false
                    }
                }
            } catch {
                NSLog("Failed to load habit stacks: \(error)")
                await MainActor.run {
                    guard let self else { return }
                    self.stacks = []
                    if showLoadingIndicator {
                        self.isLoading = false
                    }
                }
            }
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
            try persistChanges(in: context)
            loadStacks(showLoadingIndicator: false)
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
            var existingById = Dictionary(uniqueKeysWithValues: existingSteps.map { ($0.id, $0) })

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

            try persistChanges(in: context)
            loadStacks(showLoadingIndicator: false)
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
            try persistChanges(in: context)
            loadStacks(showLoadingIndicator: false)
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
            stacks = reordered
            try persistChanges(in: context)
            loadStacks(showLoadingIndicator: false)
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

    public func moveStep(inStackWithId stackId: UUID, fromOffsets indices: IndexSet, toOffset destination: Int) {
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
                SortDescriptor(\HabitStackEntity.createdAt),
            ]
        )
        let stepDescriptor = FetchDescriptor<HabitStackStepEntity>(
            sortBy: [
                SortDescriptor(\HabitStackStepEntity.stackId),
                SortDescriptor(\HabitStackStepEntity.order),
            ]
        )
        let stackEntities = try context.fetch(stackDescriptor)
        let stepEntities = try context.fetch(stepDescriptor)
        let groupedSteps = Dictionary(grouping: stepEntities, by: { $0.stackId })

        return stackEntities.map { entity in
            let steps = groupedSteps[entity.id, default: []]
                .sorted { lhs, rhs in
                    if lhs.order == rhs.order {
                        return lhs.createdAt < rhs.createdAt
                    }
                    return lhs.order < rhs.order
                }
                .map { $0.toHabitStackStep() }
            if let stack = try? HabitStack(
                id: entity.id,
                name: entity.name,
                prompt: entity.prompt,
                scheduledHour: entity.scheduledHour,
                scheduledMinute: entity.scheduledMinute,
                order: entity.order,
                steps: steps,
                createdAt: entity.createdAt,
                updatedAt: entity.updatedAt
            ) {
                return stack
            }

            return HabitStack(
                uncheckedId: entity.id,
                name: entity.name,
                prompt: entity.prompt,
                scheduledHour: nil,
                scheduledMinute: nil,
                order: entity.order,
                steps: steps,
                createdAt: entity.createdAt,
                updatedAt: entity.updatedAt
            )
        }
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
