import Foundation
import SharedModels

struct EditableStep: Identifiable, Hashable {
  var id: UUID
  var title: String
  var detail: String
  var linkedCalendarId: UUID?
  var order: Int
  var createdAt: Date
  var updatedAt: Date

  init(
    id: UUID,
    title: String,
    detail: String,
    linkedCalendarId: UUID?,
    order: Int,
    createdAt: Date,
    updatedAt: Date
  ) {
    self.id = id
    self.title = title
    self.detail = detail
    self.linkedCalendarId = linkedCalendarId
    self.order = order
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  init(step: HabitStackStep) {
    self.init(
      id: step.id,
      title: step.title,
      detail: step.detail ?? "",
      linkedCalendarId: step.linkedCalendarId,
      order: step.order,
      createdAt: step.createdAt,
      updatedAt: step.updatedAt
    )
  }
}
