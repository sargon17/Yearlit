import SharedModels
import SwiftUI

struct EditableStepRow: View {
  @Binding var step: EditableStep
  let calendars: [CustomCalendar]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      TextField("Step title", text: $step.title)
        .textInputAutocapitalization(.sentences)

      TextField("Detail (optional)", text: $step.detail, axis: .vertical)
        .lineLimit(1...4)

      if calendars.isEmpty {
        Label("Link calendars to habits once you have them.", systemImage: "calendar")
          .font(.caption)
          .foregroundStyle(.secondary)
      } else {
        Picker(
          "Linked calendar",
          selection: Binding(
            get: { step.linkedCalendarId },
            set: { step.linkedCalendarId = $0 }
          )
        ) {
          Text("None").tag(UUID?.none)
          ForEach(calendars) { calendar in
            Text(calendar.name).tag(Optional(calendar.id))
          }
        }
        .pickerStyle(.menu)
      }
    }
    .padding(.vertical, 6)
  }
}
