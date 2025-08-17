import SwiftUI

struct HabitsLoop: View {
  let onNext: () -> Void

  var body: some View {
    OnboardingView.OnboardingSlide(onNext: onNext) {
      ZStack {
        Image("onboarding_2")
          .resizable()
          .scaledToFill()
          .ignoresSafeArea(.all)

        LinearGradient(
          gradient: Gradient(colors: [Color.clear, .surfaceMuted]),
          startPoint: .top,
          endPoint: .bottom
        )
      }
    } lower: {
      VStack(alignment: .leading, spacing: 8) {
        Spacer()

        Text("The Habit Loop")
          .font(.system(size: 24, weight: .black, design: .monospaced))
          .foregroundStyle(.textPrimary)

        VStack(alignment: .leading) {
          Text("1. Cue")
          Text("2. Craving")
          Text("3. Action")
          Text("4. Reward")
        }
        .multilineTextAlignment(.leading)
        .font(.system(size: 14, design: .monospaced))
        .foregroundStyle(.secondary)
      }
    }
  }
}
