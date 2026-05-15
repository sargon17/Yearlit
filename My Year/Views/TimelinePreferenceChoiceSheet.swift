import SharedModels
import SwiftUI

struct TimelinePreferenceChoiceSheet: View {
  let onSelect: (CalendarTimelineMode) -> Void

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        CustomSeparator()
          .padding(.horizontal, -16)

        VStack(spacing: 0) {
          Spacer(minLength: 24)

          VStack(alignment: .leading, spacing: 16) {
            floatingHabitImage

            Text("Your year starts the day you do.")
              .font(.system(size: 22, weight: .black, design: .monospaced))
              .foregroundStyle(.textPrimary)
              .multilineTextAlignment(.leading)
              .fixedSize(horizontal: false, vertical: true)

            Text(
              "Habits rarely begin on January 1st. Your 365 gives each daily habit its own year, starting on day one."
            )
            .font(.system(size: 14, design: .monospaced))
            .foregroundStyle(.textSecondary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)

            Text("No empty months. No feeling late. Just the year you’re actually building.")
              .font(.system(size: 14, design: .monospaced))
              .foregroundStyle(.textSecondary)
              .multilineTextAlignment(.leading)
              .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
              Text("Recommended")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.textTertiary)
                .textCase(.uppercase)

              Text("Use the new view to make every completed day feel like visible proof you showed up.")
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 8)
          }
          .frame(maxWidth: .infinity)

          Spacer(minLength: 24)

          VStack(spacing: 14) {
            modeButton(
              title: "Use 'Your 365' View",
              mode: .your365,
              style: .primary
            )

            modeButton(
              title: "Stay Calendar View",
              mode: .calendarYear,
              style: .link
            )
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 32)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
      .navigationTitle("Your 365")
      .navigationBarTitleDisplayMode(.large)
    }
    .interactiveDismissDisabled(true)
  }

  private var floatingHabitImage: some View {
    HStack {
      Image("union 1")
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: 96, height: 96, alignment: .leading)
        .accessibilityHidden(true)
        .foregroundStyle(Color.textPrimary)

      Image("union 2")
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: 96, height: 96, alignment: .leading)
        .accessibilityHidden(true)
        .foregroundStyle(Color.qsOrange)

      Image("union 3")
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: 96, height: 96, alignment: .leading)
        .accessibilityHidden(true)
        .foregroundStyle(Color.textPrimary)
    }
  }

  @ViewBuilder
  private func modeButton(
    title: String,
    mode: CalendarTimelineMode,
    style: ModeButtonStyle
  ) -> some View {
    let button = Button {
      onSelect(mode)
    } label: {
      modeButtonLabel(title: title, style: style)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)

    if style == .primary {
      VStack {
        button
          .clipShape(RoundedRectangle(cornerRadius: 4))
          .sameLevelBorder(radius: 4, color: .brand)
      }
      .padding(2)
      .background(getVoidColor(colorScheme: colorScheme))
    } else {
      button
    }
  }

  private func modeButtonLabel(
    title: String,
    style: ModeButtonStyle
  ) -> some View {
    Text(title)
      .font(.system(size: style.titleSize, weight: .bold, design: .monospaced))
      .foregroundStyle(style.foregroundColor)
      .underline(style == .link)
      .padding(.horizontal, style.horizontalPadding)
      .padding(.vertical, style.verticalPadding)
      .frame(maxWidth: .infinity, alignment: .center)
      .background(style.backgroundColor)
  }
}

private enum ModeButtonStyle: Equatable {
  case primary
  case link

  var foregroundColor: Color {
    switch self {
    case .primary:
      return .brandInverted
    case .link:
      return .textSecondary
    }
  }

  var backgroundColor: Color {
    switch self {
    case .primary:
      return .brand
    case .link:
      return .clear
    }
  }

  var horizontalPadding: CGFloat {
    switch self {
    case .primary:
      return 14
    case .link:
      return 0
    }
  }

  var verticalPadding: CGFloat {
    switch self {
    case .primary:
      return 16
    case .link:
      return 4
    }
  }

  var titleSize: CGFloat {
    switch self {
    case .primary:
      return 18
    case .link:
      return 14
    }
  }
}
