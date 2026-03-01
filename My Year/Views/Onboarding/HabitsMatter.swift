import SwiftUI

struct HabitsMatter: View {
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

                Text("Why Habits Matter")
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundStyle(.textPrimary)

                VStack(alignment: .leading) {
                    Text("Habits shape your days.")
                    Text("Your days shape your life.")
                    Text("Small changes → Big results.")
                }
                .multilineTextAlignment(.leading)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(.secondary)
            }
        }
    }
}
