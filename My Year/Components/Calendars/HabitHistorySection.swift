import SharedModels
import SwiftUI

struct HabitHistorySection: View {
  let cadence: CalendarCadence
  @Binding var trackingStartedAt: Date
  let earliestEntryDate: Date?
  let autoAdjustedMessage: String?
  let onTrackingStartedAtChanged: () -> Void
  let onAddExistingStreak: () -> Void

  var body: some View {
    CustomSection(label: "Habit history") {
      VStack(spacing: 8) {
        VStack(spacing: 2) {
          DatePicker(
            "Habit started on",
            selection: clampedTrackingStartedAt,
            in: ...maxDate,
            displayedComponents: [.date]
          )
          .datePickerStyle(.compact)
          .padding(.horizontal)
          .padding(.vertical, 6)
          .sameLevelBorder(isFlat: true)

          Button(action: onAddExistingStreak) {
            Text("Add existing streak")
              .frame(maxWidth: .infinity, alignment: .center)
              .fontWeight(.bold)
              .padding()
          }
          .sameLevelBorder()
          .foregroundStyle(.textSecondary)
        }
        .padding(.all, 2)
        .sameLevelGroupBackground()

        if let autoAdjustedMessage {
          Text(autoAdjustedMessage)
            .font(.footnote)
            .foregroundStyle(.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
        }

        Text("Your 365 starts from your habit start date. Add past completed days if you already have progress.")
          .font(.footnote)
          .foregroundStyle(.textTertiary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 8)
      }
    }
  }

  private var clampedTrackingStartedAt: Binding<Date> {
    Binding(
      get: { min(HabitHistoryDateResolver.normalized(trackingStartedAt, cadence: cadence), maxDate) },
      set: {
        trackingStartedAt = min(HabitHistoryDateResolver.normalized($0, cadence: cadence), maxDate)
        onTrackingStartedAtChanged()
      }
    )
  }

  private var maxDate: Date {
    let today = HabitHistoryDateResolver.today(cadence: cadence)
    guard let earliestEntryDate else { return today }
    return min(earliestEntryDate, today)
  }
}
