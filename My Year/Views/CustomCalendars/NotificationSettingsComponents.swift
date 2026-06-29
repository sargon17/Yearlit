import SwiftUI

enum NotificationSettingsStyle {
  case draft
  case saved
}

struct NotificationSettingsSection<Content: View>: View {
  let label: LocalizedStringKey
  let description: LocalizedStringKey?
  let style: NotificationSettingsStyle
  let content: () -> Content

  @Environment(\.colorScheme) private var colorScheme

  init(
    label: LocalizedStringKey,
    description: LocalizedStringKey? = nil,
    style: NotificationSettingsStyle,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.label = label
    self.description = description
    self.style = style
    self.content = content
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      VStack(alignment: .leading, spacing: 4) {
        Text(label)
          .labelStyle(type: style == .saved ? .secondary : .tertiary)
          .textCase(nil)

        if let description {
          Text(description)
            .descriptionStyle()
            .textCase(nil)
        }
      }

      VStack(alignment: .leading, spacing: style == .saved ? 1 : 2) {
        content()
      }
      .padding(style == .saved ? 1 : 2)
      .background(
        Group {
          if style == .saved {
            Rectangle().fill(getVoidColor(colorScheme: colorScheme))
          } else {
            RoundedRectangle(cornerRadius: 6).fill(getVoidColor(colorScheme: colorScheme))
          }
        }
      )
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

extension View {
  func notificationSurface() -> some View {
    sameLevelBorder(radius: 6, isFlat: true)
      .overlay(
        RoundedRectangle(cornerRadius: 6)
          .stroke(Color.black.opacity(0.75), lineWidth: 2)
      )
  }
}
