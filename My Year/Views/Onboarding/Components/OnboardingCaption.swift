import Garnish
import SwiftUI

extension OnboardingView {
  struct Caption: View {
    let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
      self.text = text
    }

    var body: some View {
      Text(text)
        .font(AppFont.sans(16))
        .minimumScaleFactor(0.5)
        .foregroundStyle(.textSecondary)
    }
  }
}
