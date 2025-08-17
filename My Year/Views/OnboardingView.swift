import Garnish
import SwiftUI

struct OnboardingView: View {
  let onDone: () -> Void

  enum OnboardingPage: Int, CaseIterable, Identifiable {
    case whatItIs = 0
    case habitsMatter
    case habitsLoop
    case identityFirst

    var id: Int { rawValue }
  }

  @State private var currentPage: OnboardingPage = .whatItIs

  private func goNext() {
    if let next = OnboardingPage(rawValue: currentPage.rawValue + 1) {
      withAnimation { currentPage = next }
    } else {
      onDone()
    }
  }

  var body: some View {
    ZStack {
      // Overall background color for the entire onboarding
      Color(.systemGroupedBackground)
        .ignoresSafeArea()

      TabView(selection: $currentPage) {
        WhatItIs(onNext: goNext)
          .tag(OnboardingView.OnboardingPage.whatItIs)

        HabitsMatter(onNext: goNext)
          .tag(OnboardingView.OnboardingPage.habitsMatter)

        HabitsLoop(onNext: goNext)
          .tag(OnboardingView.OnboardingPage.habitsLoop)

        IdentityFirst(onNext: goNext)
          .tag(OnboardingView.OnboardingPage.identityFirst)

      }
      .ignoresSafeArea()
      .tabViewStyle(.page(indexDisplayMode: .never))
    }
  }
}

extension OnboardingView {
  struct OnboardingSlide<Upper: View, Lower: View>: View {
    let onNext: () -> Void
    @ViewBuilder let upper: () -> Upper
    @ViewBuilder let lower: () -> Lower

    var body: some View {
      GeometryReader { geometry in
        let height = geometry.size.height
        // let width = geometry.size.width  // Keep if needed by children

        VStack(spacing: 0) {
          ZStack {
            upper()
          }
          .frame(height: height * 0.7)

          CustomSeparator()

          VStack(alignment: .leading, spacing: 16) {
            lower()
            Spacer()
            ForwardButton(onTap: onNext)
          }
          .frame(maxHeight: height * 0.3)
          .padding(.horizontal)
          .background(.surfaceMuted)
        }
        .background(.surfaceMuted)
      }
    }
  }

  struct ForwardButton: View {
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme

    let textColor = try! Garnish.contrastingColor(.surfaceMuted, against: .qsOrange)

    var body: some View {
      VStack {
        Button(action: {
          onTap()
        }) {
          Text("Next")
            .frame(maxWidth: .infinity)
            .padding()
            .background(.qsOrange)
            .foregroundColor(.qsOrangeSecondary)
            .font(.system(size: 18, weight: .bold, design: .monospaced))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .accessibilityIdentifier("next_slide")
        }
        .sameLevelBorder()
      }
      .padding(.all, 2)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .foregroundStyle(
            getVoidColor(colorScheme: colorScheme)
          )
      )
      .clipped()
      .outerSameLevelShadow()
    }
  }
}
