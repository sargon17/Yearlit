import Garnish
import SwiftUI

struct OnboardingView: View {
  let onDone: () -> Void

  enum OnboardingPage: Int, CaseIterable, Identifiable {
    case whatItIs = 0
    case habitsMatter
    case habitsLoop
    case howItWorks
    case whyItWorks

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
        // 1) What it is
        WhatItIs(onNext: goNext)
          .tag(OnboardingView.OnboardingPage.whatItIs)

        HabitsMatter(onNext: goNext)
          .tag(OnboardingView.OnboardingPage.habitsMatter)

        HabitsLoop(onNext: goNext)
          .tag(OnboardingView.OnboardingPage.habitsLoop)

        // 2) How it works
        VStack(spacing: 16) {
          Spacer()
          Image(systemName: "hand.tap")
            .font(.system(size: 64, weight: .semibold))
            .padding(.bottom, 4)

          Text("How it works")
            .font(.largeTitle).bold()

          VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
              Text("1.").bold()
              Text("Pick one habit you want to do every day.")
            }
            HStack(alignment: .top, spacing: 8) {
              Text("2.").bold()
              Text("Each day you do it, tap that day on the calendar.")
            }
            HStack(alignment: .top, spacing: 8) {
              Text("3.").bold()
              Text("Keep the chain going. Small taps add up fast.")
            }
          }
          .padding(.horizontal)

          Spacer()

          Button(action: goNext) {
            Text("Next")
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.accentColor)
              .foregroundColor(.white)
              .clipShape(RoundedRectangle(cornerRadius: 12))
              .accessibilityIdentifier("onboarding_next_howItWorks")
          }
          .padding(.horizontal)
        }
        .tag(OnboardingView.OnboardingPage.howItWorks)

        // 3) Why it helps + CTA
        VStack(spacing: 16) {
          Spacer()
          Image(systemName: "flame.fill")
            .font(.system(size: 64, weight: .semibold))
            .padding(.bottom, 4)

          Text("Why it works")
            .font(.largeTitle).bold()

          VStack(alignment: .leading, spacing: 8) {
            Label("Streaks feel good, so you come back.", systemImage: "sparkles")
            Label("One screen. No clutter. Just your wins.", systemImage: "rectangle.grid.1x2")
            Label("Gentle reminders keep you steady.", systemImage: "bell")
          }
          .padding(.horizontal)

          Spacer()

          Button(action: goNext) {
            Text("Next")
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.accentColor)
              .foregroundColor(.white)
              .clipShape(RoundedRectangle(cornerRadius: 12))
              .accessibilityIdentifier("onboarding_next_whyItWorks")
          }
          .padding(.horizontal)
        }
        .tag(OnboardingView.OnboardingPage.whyItWorks)
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
