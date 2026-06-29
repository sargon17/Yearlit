import Foundation
import SwiftData

@available(iOS 17.0, macOS 14.0, *)
@Model
public final class HabitStackEntity {
    public var id: UUID = UUID()
    public var name: String = ""
    public var prompt: String?
    public var scheduledHour: Int?
    public var scheduledMinute: Int?
    public var order: Int = 0
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

    public init(
        id: UUID = UUID(),
        name: String,
        prompt: String?,
        scheduledHour: Int?,
        scheduledMinute: Int?,
        order: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.prompt = prompt
        self.scheduledHour = scheduledHour
        self.scheduledMinute = scheduledMinute
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@available(iOS 17.0, macOS 14.0, *)
@Model
public final class HabitStackStepEntity {
    public var id: UUID = UUID()
    public var stackId: UUID = UUID()
    public var title: String = ""
    public var detail: String?
    public var linkedCalendarId: UUID?
    public var order: Int = 0
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

    public init(
        id: UUID = UUID(),
        stackId: UUID,
        title: String,
        detail: String?,
        linkedCalendarId: UUID?,
        order: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.stackId = stackId
        self.title = title
        self.detail = detail
        self.linkedCalendarId = linkedCalendarId
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension HabitStackEntity {
    func toHabitStack(steps: [HabitStackStep]) -> HabitStack {
        let normalized = HabitStack.normalizedSteps(steps, stackId: id)
        if let stack = try? HabitStack(
            id: id,
            name: name,
            prompt: prompt,
            scheduledHour: scheduledHour,
            scheduledMinute: scheduledMinute,
            order: order,
            steps: normalized,
            createdAt: createdAt,
            updatedAt: updatedAt
        ) {
            return stack
        }

        return HabitStack(
            uncheckedId: id,
            name: name,
            prompt: prompt,
            scheduledHour: nil,
            scheduledMinute: nil,
            order: order,
            steps: normalized,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func apply(from stack: HabitStack) {
        name = stack.name
        prompt = stack.prompt
        scheduledHour = stack.scheduledHour
        scheduledMinute = stack.scheduledMinute
        order = stack.order
        createdAt = stack.createdAt
        updatedAt = stack.updatedAt
    }

    static func make(from stack: HabitStack) -> HabitStackEntity {
        HabitStackEntity(
            id: stack.id,
            name: stack.name,
            prompt: stack.prompt,
            scheduledHour: stack.scheduledHour,
            scheduledMinute: stack.scheduledMinute,
            order: stack.order,
            createdAt: stack.createdAt,
            updatedAt: stack.updatedAt
        )
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension HabitStackStepEntity {
    func toHabitStackStep() -> HabitStackStep {
        HabitStackStep(
            id: id,
            stackId: stackId,
            title: title,
            detail: detail,
            linkedCalendarId: linkedCalendarId,
            order: order,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func apply(from step: HabitStackStep, stackId: UUID) {
        id = step.id
        self.stackId = stackId
        title = step.title
        detail = step.detail
        linkedCalendarId = step.linkedCalendarId
        order = step.order
        createdAt = step.createdAt
        updatedAt = step.updatedAt
    }

    static func make(from step: HabitStackStep, stackId: UUID) -> HabitStackStepEntity {
        HabitStackStepEntity(
            id: step.id,
            stackId: stackId,
            title: step.title,
            detail: step.detail,
            linkedCalendarId: step.linkedCalendarId,
            order: step.order,
            createdAt: step.createdAt,
            updatedAt: step.updatedAt
        )
    }
}
