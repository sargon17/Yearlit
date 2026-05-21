import Garnish
import SwiftUI

enum OnboardingButtonStyle {
  case primary
  case secondary
  case disabled
}

extension OnboardingView {
  struct ForwardButton: View {
    let title: LocalizedStringKey
    let onTap: () -> Void
    let style: OnboardingButtonStyle
    @Environment(\.colorScheme) var colorScheme

    init(title: LocalizedStringKey, onTap: @escaping () -> Void, style: OnboardingButtonStyle = .primary) {
      self.title = title
      self.onTap = onTap
      self.style = style
    }

    var foregroundColor: Color {
      switch style {
      case .primary:
        return .brandInverted
      case .secondary:
        return .textPrimary
      case .disabled:
        return .textTertiary.opacity(0.5)
      }
    }

    var backgroundColor: Color {
      switch style {
      case .primary:
        return .brand
      case .secondary:
        return .surfaceMuted
      case .disabled:
        return .surfaceMuted
      }
    }

    var body: some View {
      VStack {
        Button(action: onTap) {
          Text(title)
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(foregroundColor)
            .font(AppFont.sans(18, weight: .bold))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .sameLevelBorder(radius: 4, color: backgroundColor)
        .disabled(style == .disabled)
      }
      .padding(.all, 2)
    }
  }
}
