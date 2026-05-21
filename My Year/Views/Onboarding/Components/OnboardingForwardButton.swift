import Garnish
import SwiftUI

extension OnboardingView {
  struct ForwardButton: View {
    let title: LocalizedStringKey
    let onTap: () -> Void
    var disabled: Bool = false
    @Environment(\.colorScheme) var colorScheme

    var foregroundColor: Color {
      disabled ? .textTertiary : .brandInverted
    }

    var backgroundColor: Color {
      disabled ? .surfaceMuted : .brand
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
        .disabled(disabled)
      }
      .padding(.all, 2)
      // .background(
      //   RoundedRectangle(cornerRadius: 6)
      //     .foregroundStyle(getVoidColor(colorScheme: colorScheme))
      // )
      // .clipped()
      // .outerSameLevelShadow()
    }
  }
}
