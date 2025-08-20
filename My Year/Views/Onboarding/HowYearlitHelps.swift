import SwiftUI

struct HowYearlitHelps: View {
  let onNext: () -> Void

  var body: some View {
    OnboardingView.OnboardingSlide(onNext: onNext) {

    } lower: {
      VStack(alignment: .leading, spacing: 8) {
        Spacer()

        Text("The 4 Rules of Good Habits")
          .font(.system(size: 24, weight: .black, design: .monospaced))
          .foregroundStyle(.textPrimary)

        // To make habits stick, keep them:
        VStack(alignment: .leading) {
          Text("To make habits stick, keep them:")
          Text("Obvious, Attractive, Easy & Satisfying")
        }
        .multilineTextAlignment(.leading)
        .font(.system(size: 14, design: .monospaced))
        .foregroundStyle(.secondary)
      }
    }
  }
}
