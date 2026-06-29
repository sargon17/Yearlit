import Foundation

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

    public mutating func touchUpdatedAt(date: Date = Date()) {
        updatedAt = date
    }

    public func withStackId(_ stackId: UUID) -> HabitStackStep {
        var copy = self
        copy.stackId = stackId
        return copy
    }

    public func updating(
        title: String,
        detail: String? = nil,
        linkedCalendarId: UUID? = nil
    ) -> HabitStackStep {
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
        try Self.validateSchedule(hour: scheduledHour, minute: scheduledMinute)
        try Self.validateSteps(steps)
        self.init(
            uncheckedId: id,
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
        self.prompt = trimmedPrompt?.isEmpty == false ? trimmedPrompt : nil
        self.scheduledHour = scheduledHour
        self.scheduledMinute = scheduledMinute
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.steps = Self.normalizedSteps(steps, stackId: id)
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

    public func containsStep(_ id: HabitStackStep.ID) -> Bool {
        step(withId: id) != nil
    }

    public mutating func replaceSteps(_ newSteps: [HabitStackStep]) throws {
        try Self.validateSteps(newSteps)
        steps = Self.normalizedSteps(newSteps, stackId: id)
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
        steps = Self.normalizedSteps(steps, stackId: id)
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
