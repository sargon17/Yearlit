import SwiftUI

struct WhatItIs: View {
  let onNext: () -> Void

  var body: some View {
    OnboardingView.OnboardingSlide(onNext: onNext) {
      GeometryReader { geometry in
        let height = geometry.size.height
        let width = geometry.size.width
        ZStack {
          Image("onboarding_1")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: width * 0.9)
            .offset(y: height * 0.15)

          LinearGradient(
            gradient: Gradient(colors: [Color.clear, .surfaceMuted]),
            startPoint: .center,
            endPoint: .bottom
          )
          .padding(.top, height * 0.35)
          .ignoresSafeArea()

          Image("icon")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: width * 0.15)
            .offset(x: 0, y: -(height * 0.35))
            .rotationEffect(Angle(degrees: 35))
            .shadow(color: .black, radius: 4, x: 0, y: 5)
        }
      }
    } lower: {
      VStack(alignment: .leading, spacing: 8) {
        Spacer()
        Text("Yearlit")
          .font(.system(size: 36, weight: .black, design: .monospaced))
          .foregroundStyle(.qsOrange)

        VStack(alignment: .leading) {
          Text("A simple habit calendar.")
          Text("Tap once each day you do your habit.")
          Text("Watch your chain grow.")
        }
        .multilineTextAlignment(.leading)
        .font(.system(size: 14, design: .monospaced))
        .foregroundStyle(.secondary)
      }
    }
  }
}
