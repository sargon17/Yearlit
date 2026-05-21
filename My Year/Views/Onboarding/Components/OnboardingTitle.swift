import Garnish
import SwiftUI

extension OnboardingView {
  struct Title: View {
    let title: LocalizedStringKey
    let lineLimit: Int

    init(_ title: LocalizedStringKey, lineLimit: Int = 2) {
      self.title = title
      self.lineLimit = lineLimit
    }

    var body: some View {
      Text(title)
        .font(AppFont.pixelCircle(32))
        .lineLimit(lineLimit)
        .minimumScaleFactor(0.5)
        .foregroundStyle(.textPrimary)
    }
  }
}
