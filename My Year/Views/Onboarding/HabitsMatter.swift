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
                    .font(AppFont.pixelCircle(24))
                    .foregroundStyle(.textPrimary)

                VStack(alignment: .leading) {
                    Text("Habits shape your days.")
                    Text("Your days shape your life.")
                    Text("Small changes → Big results.")
                }
                .multilineTextAlignment(.leading)
                .font(AppFont.mono(14))
                .foregroundStyle(.secondary)
            }
        }
    }
}
