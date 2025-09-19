import SharedModels
import SwiftUI

struct HabitStackRow: View {
  let stack: HabitStack

  private var scheduleLabel: String? {
    guard let hour = stack.scheduledHour, let minute = stack.scheduledMinute else { return nil }
    var components = DateComponents()
    components.hour = hour
    components.minute = minute
    if let date = Calendar.current.date(from: components) {
      return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
    }
    return String(format: "%02d:%02d", hour, minute)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(stack.name)
          .font(.headline)
        Spacer()
        if let scheduleLabel {
          Label(scheduleLabel, systemImage: "alarm")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      if let prompt = stack.prompt, !prompt.isEmpty {
        Text(prompt)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      HStack(spacing: 12) {
        Label("\(stack.steps.count) steps", systemImage: "list.number")
        if let first = stack.stepsSorted.first {
          Text("Starts with \(first.title)")
        }
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    }
    .padding(.vertical, 8)
  }
}
