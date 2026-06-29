import SwiftUI

struct DailyWallpaperSettingsGroup<Content: View>: View {
  let title: LocalizedStringKey
  let footer: LocalizedStringKey?
  let content: () -> Content

  init(
    _ title: LocalizedStringKey,
    footer: LocalizedStringKey? = nil,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.title = title
    self.footer = footer
    self.content = content
  }

  var body: some View {
    CustomSection(label: title) {
      content()

      if let footer {
        Text(footer)
          .font(.footnote)
          .foregroundStyle(.textTertiary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 8)
          .padding(.top, 8)
      }
    }
  }
}

struct WallpaperThemePicker: View {
  let selectedTheme: DailyWallpaperTheme
  let accentColor: Color
  let onSelect: (DailyWallpaperTheme) -> Void

  var body: some View {
    HStack(spacing: 2) {
      ForEach(DailyWallpaperTheme.allCases) { theme in
        themeButton(for: theme)
      }
    }
    .padding(.all, 2)
    .frame(maxWidth: .greatestFiniteMagnitude)
    .sameLevelGroupBackground()
  }

  private func themeButton(for theme: DailyWallpaperTheme) -> some View {
    Button {
      withAnimation(.snappy) { onSelect(theme) }
      Task { await hapticFeedback(.rigid) }
    } label: {
      PickerOptionTile(isSelected: selectedTheme == theme, isEnabled: true) {
        PickerOptionContent(
          icon: theme.systemImageName,
          title: theme.displayName,
          accentColor: accentColor,
          isSelected: selectedTheme == theme
        )
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text(theme.displayName))
  }
}

struct LockedWallpaperOptionRow: View {
  let title: LocalizedStringKey
  var subtitle: LocalizedStringKey?
  var iconName: String?
  let showsLock: Bool
  var accentColor: Color?
  var trailingIconName: String?

  var body: some View {
    HStack(spacing: 12) {
      if let iconName {
        Image(systemName: iconName)
          .font(.system(size: 15, weight: .semibold))
          .foregroundColor(accentColor ?? Color("text-secondary"))
          .frame(width: 22)
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(AppFont.mono(12, weight: subtitle == nil ? .regular : .bold))
          .foregroundColor(Color("text-primary"))
        if let subtitle {
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.textTertiary)
        }
      }

      Spacer()

      if showsLock {
        Image(systemName: "lock.fill")
          .font(.system(size: 12, weight: .bold))
          .foregroundColor(Color("text-tertiary"))
      }
      if let trailingIconName {
        Image(systemName: trailingIconName)
          .font(AppFont.mono(12))
          .foregroundColor(accentColor ?? Color("text-tertiary"))
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 10)
    .sameLevelBorder(isFlat: true)
    .accessibilityElement(children: .combine)
  }
}

private extension DailyWallpaperTheme {
  var displayName: LocalizedStringKey {
    switch self {
    case .dark: "Dark"
    case .light: "Light"
    }
  }

  var systemImageName: String {
    switch self {
    case .dark: "moon.fill"
    case .light: "sun.max.fill"
    }
  }
}
