import SwiftUI

struct WidgetShowcaseButton<Content: View>: View {
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

struct WidgetShowcaseGroup<Content: View>: View {
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
