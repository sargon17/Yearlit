import SharedModels
import SwiftUI

struct TimelinePreferenceChoiceSheet: View {
    let onSelect: (CalendarTimelineMode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose your default year view")
                    .font(.title2.bold())
                Text("Pick the view you want to open by default. You can change it later in Settings.")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                modeButton(
                    title: "Use Your 365",
                    subtitle: "Each habit starts its own 365-day journey from the day you began.",
                    mode: .your365,
                    isPrimary: true
                )

                modeButton(
                    title: "Keep Calendar Year",
                    subtitle: "View progress from January to December.",
                    mode: .calendarYear,
                    isPrimary: false
                )
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
        .interactiveDismissDisabled(true)
    }

    @ViewBuilder
    private func modeButton(
        title: String,
        subtitle: String,
        mode: CalendarTimelineMode,
        isPrimary: Bool
    ) -> some View {
        Button {
            onSelect(mode)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        if isPrimary {
            button.buttonStyle(.borderedProminent).tint(.accentColor)
        } else {
            button.buttonStyle(.bordered).tint(.secondary)
        }
    }
}
