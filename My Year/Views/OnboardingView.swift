import Garnish
import SwiftUI

struct OnboardingView: View {
  let onDone: () -> Void

  enum OnboardingPage: Int, CaseIterable, Identifiable {
    case whatItIs = 0
    case habitsMatter
    case habitsLoop
    case identityFirst
    case compoundEffect
    case fourRules
    case howYearlitHelps
    case createFirstHabit
    case Paywall

    var id: Int { rawValue }
  }

  @State private var currentPage: OnboardingPage = .whatItIs

  private func goNext() {
    if let next = OnboardingPage(rawValue: currentPage.rawValue + 1) {
      withAnimation { currentPage = next }
    } else {
      onDone()
    }

    Task {
      await hapticFeedback()
    }
  }

  var body: some View {
    ZStack {
      // Overall background color for the entire onboarding
      Color(.systemGroupedBackground)
        .ignoresSafeArea()

      TabView(
        selection: $currentPage.onChange { _ in
          Task {
            await hapticFeedback()
          }
        }
      ) {
        WhatItIs(onNext: goNext)
          .tag(OnboardingView.OnboardingPage.whatItIs)

        HabitsMatter(onNext: goNext)
          .tag(OnboardingView.OnboardingPage.habitsMatter)

        HabitsLoop(onNext: goNext)
          .tag(OnboardingView.OnboardingPage.habitsLoop)

        IdentityFirst(onNext: goNext)
          .tag(OnboardingView.OnboardingPage.identityFirst)

        CompoundEffect(onNext: goNext)
          .tag(OnboardingView.OnboardingPage.compoundEffect)

        FourRules(onNext: goNext)
          .tag(OnboardingView.OnboardingPage.fourRules)

        HowYearlitHelps(onNext: goNext)
          .tag(OnboardingView.OnboardingPage.howYearlitHelps)

        CreateFirstHabit(onNext: goNext)
          .tag(OnboardingView.OnboardingPage.createFirstHabit)

        OnboardingPaywall(onNext: goNext)
          .tag(OnboardingView.OnboardingPage.Paywall)
      }
      .ignoresSafeArea()
      .tabViewStyle(.page(indexDisplayMode: .never))
      .scrollDismissesKeyboard(.immediately)
    }
  }
}

extension OnboardingView {
  struct OnboardingSlide<Upper: View, Lower: View>: View {
    let onNext: () -> Void
    var disabled: Bool = false
    var withSkip: Bool = false
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

            HStack {
              if withSkip {
                SkipButton(onTap: onNext)
              }
              ForwardButton(onTap: onNext, disabled: disabled)
            }
          }
          .frame(maxHeight: height * 0.3)
          .padding(.horizontal)
          .background(.surfaceMuted)
        }
        .background(.surfaceMuted)
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
          }.ignoresSafeArea()
        }

      }
    }
  }

  struct SkipButton: View {
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
      VStack {
        Button(action: {
          onTap()
        }) {
          Text("Skip")
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.textPrimary)
            .font(.system(size: 18, weight: .bold, design: .monospaced))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .accessibilityIdentifier("skip")
        }
        .sameLevelBorder(color: .surfaceMuted)
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

  struct ForwardButton: View {
    let onTap: () -> Void
    var disabled: Bool = false
    @Environment(\.colorScheme) var colorScheme

    var foregroundColor: Color {
      withAnimation {
        return disabled ? .black : .brandInverted
      }
    }

    var backgroundColor: Color {
      withAnimation {
        return disabled ? .gray : .brand
      }
    }

    var body: some View {
      VStack {
        Button(action: {
          onTap()
        }) {
          Text("Next")
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(foregroundColor)
            .font(.system(size: 18, weight: .bold, design: .monospaced))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .accessibilityIdentifier("next_slide")
        }
        .sameLevelBorder(radius: 4, color: backgroundColor)
        .disabled(disabled)
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
