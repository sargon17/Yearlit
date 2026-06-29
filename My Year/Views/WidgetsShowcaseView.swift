import Garnish
import SharedModels
import SwiftUI

struct WidgetsShowcaseView: View {
  @Environment(\.colorScheme) private var colorScheme
  @State private var selectedInstallGuide: WidgetInstallGuide?

  private var backgroundColor: Color {
    WidgetStyle.surfaceMutedColor(for: colorScheme)
  }

  private var primaryTextColor: Color {
    WidgetStyle.textPrimaryColor(for: colorScheme)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("Tap a widget for setup steps.")
          .font(AppFont.mono(13))
          .foregroundStyle(.textSecondary)
          .fixedSize(horizontal: false, vertical: true)

        WidgetShowcaseGroup(title: "Year Progress") {
          WidgetShowcaseButton(guide: .year, selectedInstallGuide: $selectedInstallGuide) {
            WidgetPreviewFrame(family: .medium, width: mediumPreviewWidth) {
              YearProgressWidgetDisplayView(
                family: .medium,
                referenceDate: Date(),
                backgroundColor: backgroundColor,
                textPrimaryColor: primaryTextColor
              )
            }
          }

          WidgetShowcaseButton(guide: .year, selectedInstallGuide: $selectedInstallGuide) {
            WidgetPreviewFrame(family: .small, width: smallPreviewWidth) {
              YearProgressWidgetDisplayView(
                family: .small,
                referenceDate: Date(),
                backgroundColor: backgroundColor,
                textPrimaryColor: primaryTextColor
              )
            }
          }
        }

        WidgetShowcaseGroup(title: "Habit Progress") {
          WidgetShowcaseButton(guide: .habitProgress, selectedInstallGuide: $selectedInstallGuide) {
            WidgetPreviewFrame(family: .medium, width: mediumPreviewWidth) {
              HabitProgressWidgetDisplayView(
                family: .medium,
                calendar: WidgetPreviewFixtures.habitCalendar(),
                backgroundColor: backgroundColor,
                textPrimaryColor: primaryTextColor
              )
            }
          }

          WidgetShowcaseButton(guide: .habitProgress, selectedInstallGuide: $selectedInstallGuide) {
            WidgetPreviewFrame(family: .small, width: smallPreviewWidth) {
              HabitProgressWidgetDisplayView(
                family: .small,
                calendar: WidgetPreviewFixtures.habitCalendar(),
                backgroundColor: backgroundColor,
                textPrimaryColor: primaryTextColor
              )
            }
          }
        }

        WidgetShowcaseGroup(title: "Streak") {
          WidgetShowcaseButton(guide: .streak, selectedInstallGuide: $selectedInstallGuide) {
            WidgetPreviewFrame(family: .small, width: smallPreviewWidth) {
              StreakWidgetDisplayView(
                calendarName: String(localized: "Daily Training"),
                accentColor: Color("qs-orange"),
                streak: 18,
                isAtRisk: false,
                backgroundColor: backgroundColor,
                textPrimaryColor: primaryTextColor
              )
            }
          }
        }
      }
      .padding()
      .padding(.bottom, 40)
    }
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .navigationTitle("Widgets")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(item: $selectedInstallGuide) { guide in
      WidgetInstallGuideSheet(guide: guide)
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.visible)
    }
  }

  private var mediumPreviewWidth: CGFloat {
    min(UIScreen.main.bounds.width * 0.8, 360)
  }

  private var smallPreviewWidth: CGFloat {
    min(max(UIScreen.main.bounds.width * 0.38, 158), 190)
  }
}

#Preview {
  NavigationStack {
    WidgetsShowcaseView()
  }
}
