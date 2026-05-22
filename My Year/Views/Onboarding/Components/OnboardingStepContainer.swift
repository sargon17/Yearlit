import Garnish
import SwiftUI

struct OnboardingStepContainer<Top: View, Content: View, Actions: View>: View {
  let overlayHeight: CGFloat
  @ViewBuilder let top: () -> Top
  @ViewBuilder let content: () -> Content
  @ViewBuilder let actions: () -> Actions

  init(
    overlayHeight: CGFloat = 0.6, @ViewBuilder top: @escaping () -> Top, @ViewBuilder content: @escaping () -> Content,
    @ViewBuilder actions: @escaping () -> Actions
  ) {
    self.overlayHeight = overlayHeight
    self.top = top
    self.content = content
    self.actions = actions
  }

  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    GeometryReader { geometry in
      ZStack {

        let size = max(geometry.size.width, geometry.size.height) * 1.05
        let color = GarnishColor.blend(.textPrimary, with: .surfaceMuted, ratio: 0.9)

        UnionOneShape()
          .fill(color)
          .frame(width: size, height: size)
          .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
          .accessibilityHidden(true)

        VStack(spacing: 0) {
          ZStack {
            top()

            OnboardingView.GradientOverlay(height: overlayHeight)
              .allowsHitTesting(false)
          }
          .frame(maxHeight: .infinity)

          CustomSeparator()

          VStack(alignment: .leading, spacing: 16) {
            content()
              .padding(.top)
            actions()
              .padding(.bottom)
          }
          .padding(.horizontal)
          .padding(.bottom)
          .background(.surfaceMuted)
        }
        .overlay {
          HStack {
            Rectangle()
              .fill(Color("devider-bottom"))
              .frame(maxHeight: .infinity, alignment: .trailing)
              .frame(maxWidth: 1)

            Spacer()

            Rectangle()
              .fill(Color("devider-top"))
              .frame(maxHeight: .infinity, alignment: .trailing)
              .frame(maxWidth: 1)
          }
          .ignoresSafeArea()
        }
      }.background(.surfaceMuted)
        .overlay(
          NoiseLayer(opacity: 0.35, blendMode: colorScheme == .light ? .colorDodge : .overlay)
        )
    }
  }
}
