import SharedModels
import SwiftUI

extension HabitStackEditorView {
  func addStep() {
    let now = Date()
    let newStep = EditableStep(
      id: UUID(),
      title: "",
      detail: "",
      linkedCalendarId: nil,
      order: steps.count,
      createdAt: now,
      updatedAt: now
    )
    steps.append(newStep)
  }

  func removeStep(_ step: EditableStep) {
    steps.removeAll { $0.id == step.id }
  }

  func moveStep(_ step: EditableStep, direction: Int) {
    guard let currentIndex = steps.firstIndex(of: step) else { return }
    let destination = currentIndex + direction
    guard steps.indices.contains(destination) else { return }

    withAnimation(.snappy) {
      steps.swapAt(currentIndex, destination)
    }
  }

  func save() {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else {
      errorMessage = "Give the stack a name."
      return
    }

    guard let sanitizedSteps = sanitizeSteps() else { return }

    let components = Calendar.current.dateComponents([.hour, .minute], from: scheduleTime)
    let hour = scheduleEnabled ? components.hour : nil
    let minute = scheduleEnabled ? components.minute : nil

    isSaving = true
    defer { isSaving = false }

    do {
      let stack = try buildStack(
        name: trimmedName,
        steps: sanitizedSteps,
        hour: hour,
        minute: minute
      )

      if isEditing {
        store.updateStack(stack)
      } else {
        store.addStack(stack)
      }
      dismiss()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func sanitizeSteps() -> [HabitStackStep]? {
    let sanitized =
      steps
      .enumerated()
      .compactMap { index, editable -> HabitStackStep? in
        let trimmedTitle = editable.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }
        let trimmedDetail = editable.detail.trimmingCharacters(in: .whitespacesAndNewlines)
        return HabitStackStep(
          id: editable.id,
          stackId: stackId,
          title: trimmedTitle,
          detail: trimmedDetail.isEmpty ? nil : trimmedDetail,
          linkedCalendarId: editable.linkedCalendarId,
          order: index,
          createdAt: editable.createdAt,
          updatedAt: Date()
        )
      }

    guard !sanitized.isEmpty else {
      errorMessage = "Add at least one step before saving."
      return nil
    }
    return sanitized
  }

  func buildStack(
    name: String,
    steps: [HabitStackStep],
    hour: Int?,
    minute: Int?
  ) throws -> HabitStack {
    let existing: HabitStack? = {
      if case .edit(let stack) = mode { return stack }
      return nil
    }()

    return try HabitStack(
      id: stackId,
      name: name,
      prompt: prompt.trimmedOrNil,
      scheduledHour: hour,
      scheduledMinute: minute,
      order: existing?.order ?? store.stacks.count,
      steps: steps,
      createdAt: existing?.createdAt ?? Date(),
      updatedAt: Date()
    )
  }

  static func makeDate(hour: Int, minute: Int) -> Date? {
    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    components.hour = hour
    components.minute = minute
    return Calendar.current.date(from: components)
  }
}
