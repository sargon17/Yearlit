import Garnish
import SwiftUI

enum WidgetInstallGuide: String, Identifiable {
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

struct WidgetInstallGuideSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var colorScheme

  let guide: WidgetInstallGuide

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("Add widgets from the Home Screen.")
        .font(AppFont.mono(13))
        .foregroundStyle(.textSecondary)
        .fixedSize(horizontal: false, vertical: true)

      VStack(alignment: .leading, spacing: 12) {
        WidgetInstallStep(number: "01", text: String(localized: "Open your Home Screen."))
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
