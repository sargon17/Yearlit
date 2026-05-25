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
        Text("Yearlit widgets keep progress visible without opening the app.")
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

private enum WidgetInstallGuide: String, Identifiable {
  case year
  case habitProgress
  case streak

  var id: String { rawValue }

  var title: String {
    switch self {
    case .year:
      return String(localized: "Year Progress")
    case .habitProgress:
      return String(localized: "Habit Progress")
    case .streak:
      return String(localized: "Streak")
    }
  }
}

private struct WidgetShowcaseButton<Content: View>: View {
  let guide: WidgetInstallGuide
  @Binding var selectedInstallGuide: WidgetInstallGuide?
  @ViewBuilder let content: () -> Content

  var body: some View {
    Button {
      selectedInstallGuide = guide
    } label: {
      content()
    }
    .buttonStyle(.plain)
    .accessibilityLabel(String(localized: "Add \(guide.title) widget"))
  }
}

private struct WidgetShowcaseGroup<Content: View>: View {
  let title: LocalizedStringKey
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.system(size: 13, weight: .bold, design: .monospaced))
        .foregroundStyle(.textSecondary)

      ScrollView(.horizontal) {
        HStack(alignment: .top, spacing: 16) {
          content()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
      }
      .scrollClipDisabled()
      .scrollIndicators(.hidden)
      .padding(.horizontal, -18)
    }
  }
}

private struct WidgetInstallGuideSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var colorScheme
  let guide: WidgetInstallGuide

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("iOS does not let apps open the widget picker directly. Add it from the Home Screen.")
        .font(AppFont.mono(13))
        .foregroundStyle(.textSecondary)
        .fixedSize(horizontal: false, vertical: true)

      VStack(alignment: .leading, spacing: 12) {
        WidgetInstallStep(number: "01", text: String(localized: "Go to your Home Screen."))
        WidgetInstallStep(number: "02", text: String(localized: "Touch and hold an empty area."))
        WidgetInstallStep(number: "03", text: String(localized: "Tap Edit, then Add Widget."))
        WidgetInstallStep(number: "04", text: String(localized: "Search Yearlit and choose \(guide.title)."))
      }
      .padding(.top, 2)

      Spacer()

      Button {
        dismiss()
      } label: {
        Text("Got it")
          .font(AppFont.mono(16, weight: .bold))
          .foregroundColor(.brandInverted)
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.brand)
      }
      .buttonStyle(.plain)
      .clipShape(RoundedRectangle(cornerRadius: 4))
      .sameLevelBorder(radius: 4, color: .brand)
      .padding(2)
      .background(getVoidColor(colorScheme: colorScheme))
    }
    .navigationTitle(String(localized: "Add \(guide.title)"))
    .navigationBarTitleDisplayMode(.large)
    .padding(24)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
  }
}

private struct WidgetInstallStep: View {
  let number: String
  let text: String

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Text(number)
        .font(AppFont.mono(11, weight: .bold))
        .foregroundStyle(.textTertiary)
        .frame(width: 26, alignment: .leading)

      Text(text)
        .font(AppFont.mono(13))
        .foregroundStyle(.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

struct WidgetPreviewFrame<Content: View>: View {
  @Environment(\.colorScheme) private var colorScheme

  let family: WidgetPreviewFamily
  var width: CGFloat?
  @ViewBuilder let content: () -> Content

  private var canonicalSize: CGSize {
    switch family {
    case .small:
      return CGSize(width: 158, height: 158)
    case .medium:
      return CGSize(width: 338, height: 158)
    case .large:
      return CGSize(width: 338, height: 354)
    }
  }

  private var size: CGSize {
    guard let width else { return canonicalSize }
    return CGSize(width: width, height: width * canonicalSize.height / canonicalSize.width)
  }

  private var shadowColor: Color {
    colorScheme == .dark ? .black.opacity(0.35) : .black.opacity(0.14)
  }

  var body: some View {
    content()
      .frame(width: size.width, height: size.height)
      .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
          .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.45), lineWidth: 0.5)
      }
      .shadow(color: shadowColor, radius: 18, x: 0, y: 10)
  }
}

#Preview {
  NavigationStack {
    WidgetsShowcaseView()
  }
}
