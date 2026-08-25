#if DEBUG

import SwiftUI
import SwiftfulRouting

// PROTOTYPE — Progress proof in Yearlit's native paywall language. Remove after the Offer design is chosen.
struct OfferPaywallPrototypeSection: View {
  @Environment(\.router) private var router

  var body: some View {
    Section(header: Text("Offer prototypes")) {
      Button {
        router.showScreen(.sheet) { _ in
          OfferPaywallPrototypeView()
        }
      } label: {
        Label("Preview Offer paywall", systemImage: "tag")
      }

      Button {
        router.showScreen(.sheet) { _ in
          OfferSettingsRowPrototypeView()
        }
      } label: {
        Label("Preview Settings row", systemImage: "gearshape")
      }
    }
  }
}

private enum OfferPrototypeVariant: CaseIterable, Identifiable {
  case reward
  case spotlight
  case proof

  var id: Self { self }

  var name: String {
    switch self {
    case .reward: return "Earned reward"
    case .spotlight: return "Price spotlight"
    case .proof: return "Progress proof"
    }
  }

  var eyebrow: LocalizedStringKey {
    switch self {
    case .reward: return "A reward for your year"
    case .spotlight: return "Yearlit yearly"
    case .proof: return "Your year so far"
    }
  }

  var title: LocalizedStringKey {
    switch self {
    case .reward: return "Keep your year going."
    case .spotlight: return "Half price for your next year."
    case .proof: return "Keep the pattern alive."
    }
  }

  func subtitle(for audience: OfferPrototypeAudience) -> LocalizedStringKey {
    switch (self, audience) {
    case (.reward, .discount): return "You have built a year worth keeping."
    case (.reward, .winBack): return "Your progress is still here when you are ready."
    case (.spotlight, .discount): return "One clear price for every premium tool."
    case (.spotlight, .winBack): return "Come back to the tools that kept your year visible."
    case (.proof, .discount): return "Your pattern is already in motion."
    case (.proof, .winBack): return "Your pattern is still here."
    }
  }
}

private enum OfferPrototypeAudience: String, CaseIterable, Identifiable {
  case discount = "Discount offer"
  case winBack = "Win-back offer"

  var id: Self { self }
}

private struct OfferPrototypePlan {
  let name: String
  let price: String
  let period: String
  let comparisonPrice: String?
  let footer: LocalizedStringKey

  static let annual = OfferPrototypePlan(
    name: "Yearly",
    price: "$19.99",
    period: "/year",
    comparisonPrice: "$39.99/year",
    footer: "Best for building consistency"
  )

  static let monthly = OfferPrototypePlan(
    name: "Monthly",
    price: "$4.99",
    period: "/month",
    comparisonPrice: nil,
    footer: "Simple monthly plan"
  )

  static let weekly = OfferPrototypePlan(
    name: "Weekly",
    price: "$1.49",
    period: "/week",
    comparisonPrice: nil,
    footer: "Flexible access"
  )
}

struct OfferPaywallPrototypeView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var variant: OfferPrototypeVariant = .proof
  @State private var audience: OfferPrototypeAudience = .discount
  @State private var showsTrial = false
  @State private var showsOtherPlans = false

  var body: some View {
    OnboardingStepContainer(overlayHeight: 0.9, actionsBottomPadding: 4) {
      GeometryReader { proxy in
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            OnboardingView.Caption(variant.eyebrow)

            OnboardingView.Title(variant.title, lineLimit: 3)
              .padding(.top, 8)

            OnboardingView.Caption(variant.subtitle(for: audience))
              .padding(.top, 6)

            if variant == .proof {
              proofSignal
                .padding(.top, 28)
            }
          }
          .padding(.top, proxy.safeAreaInsets.top + 86)
          .padding(.horizontal)
          .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
      }
    } content: {
    } actions: {
      VStack(spacing: 8) {
        annualPlan

        plansDisclosure

        if showsOtherPlans {
          otherPlans
        }

        primaryAction

        PaywallFooterLinks(onRestore: {})
      }
      .padding(.top, 4)
    }
    .overlay(alignment: .topLeading) {
      closeButton
    }
    .overlay(alignment: .topTrailing) {
      prototypeMenu
    }
    .environment(\.onboardingAccent, .brand)
  }

  private var closeButton: some View {
    Button {
      dismiss()
    } label: {
      Image(systemName: "xmark")
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(.textSecondary.opacity(0.6))
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .padding(.top, 44)
    .padding(.leading, 8)
    .accessibilityLabel("Close paywall")
  }

  private var prototypeMenu: some View {
    Menu {
      Section("Layout") {
        ForEach(OfferPrototypeVariant.allCases) { option in
          Button {
            withAnimation(.easeOut(duration: 0.18)) {
              variant = option
            }
          } label: {
            Label(option.name, systemImage: option == variant ? "checkmark" : "circle")
          }
        }
      }

      Section("Audience") {
        ForEach(OfferPrototypeAudience.allCases) { option in
          Button {
            audience = option
          } label: {
            Label(option.rawValue, systemImage: option == audience ? "checkmark" : "circle")
          }
        }
      }

      Toggle("Show trial line", isOn: $showsTrial)
    } label: {
      Image(systemName: "ellipsis.circle")
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(.textSecondary)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .padding(.top, 44)
    .padding(.trailing, 8)
  }

  private var proofSignal: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("142")
        .font(AppFont.pixelCircle(26))
        .foregroundStyle(Color.brand)

      OnboardingView.Caption("check-ins this year")
    }
  }

  private var annualPlan: some View {
    OfferPrototypePlanCard(
      plan: .annual,
      isFeatured: true,
      showsTrial: showsTrial
    )
  }

  private var plansDisclosure: some View {
    Button {
      withAnimation(.easeOut(duration: 0.18)) {
        showsOtherPlans.toggle()
      }
    } label: {
      HStack {
        Text(showsOtherPlans ? "Hide other plans" : "See other plans")
          .font(AppFont.sans(13, weight: .semibold))

        Spacer()

        Image(systemName: showsOtherPlans ? "chevron.up" : "chevron.down")
          .font(.caption.weight(.semibold))
      }
      .foregroundStyle(.textSecondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private var otherPlans: some View {
    VStack(spacing: 8) {
      OfferPrototypeCompactPlan(plan: .monthly)
      OfferPrototypeCompactPlan(plan: .weekly)
    }
    .transition(.opacity.combined(with: .move(edge: .top)))
  }

  private var primaryAction: some View {
    Button("Continue with Pro") {}
      .font(AppFont.sans(18, weight: .bold))
      .foregroundStyle(Color.brandInverted)
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color.brand)
      .clipShape(RoundedRectangle(cornerRadius: 4))
      .buttonStyle(OfferPrototypePrimaryButtonStyle())
      .sameLevelBorder(radius: 4, color: .brand)
  }
}

private struct OfferPrototypePrimaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.96 : 1)
      .opacity(configuration.isPressed ? 0.92 : 1)
      .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
  }
}

private struct OfferPrototypePlanCard: View {
  let plan: OfferPrototypePlan
  let isFeatured: Bool
  let showsTrial: Bool

  var body: some View {
    Button {} label: {
      VStack(alignment: .leading, spacing: 0) {
        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 8) {
            Text(plan.name)
              .font(AppFont.sans(18, weight: .bold))
              .foregroundStyle(isFeatured ? Color.brand : Color.textPrimary)

            HStack(spacing: 10) {
              if let comparisonPrice = plan.comparisonPrice {
                Text(comparisonPrice)
                  .font(AppFont.sans(15, weight: .semibold))
                  .foregroundStyle(.textSecondary.opacity(0.55))
                  .strikethrough(true, color: .textSecondary.opacity(0.55))

                Text(plan.price + plan.period)
                  .font(AppFont.sans(16, weight: .bold))
              } else {
                Text(plan.price + plan.period)
                  .font(AppFont.sans(16, weight: .semibold))
              }

              if isFeatured {
                Text("-50%")
                  .font(AppFont.sans(14, weight: .bold))
                  .padding(.horizontal, 4)
                  .padding(.vertical, 2)
                  .foregroundStyle(Color.surfaceMuted)
                  .background(Color.brand)
              }
            }

            if showsTrial, isFeatured {
              Text("7 days free, then \(plan.price)\(plan.period)")
                .font(AppFont.sans(13, weight: .semibold))
                .foregroundStyle(.textSecondary.opacity(0.8))
            }
          }

          Spacer()
        }

        if isFeatured {
          Spacer()
        }

        Text(plan.footer)
          .font(AppFont.sans(12))
          .foregroundStyle(.textSecondary.opacity(0.8))
      }
      .frame(maxWidth: .infinity, maxHeight: isFeatured ? 156 : nil, alignment: .leading)
      .padding(12)
      .background(.surfaceMuted)
      .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    .buttonStyle(.plain)
    .sameLevelBorder(radius: 4, isFlat: isFeatured)
  }
}

private struct OfferPrototypeCompactPlan: View {
  let plan: OfferPrototypePlan

  var body: some View {
    HStack {
      Text(plan.name)
        .font(AppFont.sans(14, weight: .semibold))
      Spacer()
      Text(plan.price + plan.period)
        .font(AppFont.sans(14, weight: .semibold))
        .foregroundStyle(.textSecondary)
    }
    .padding(10)
    .background(.surfaceMuted)
    .clipShape(RoundedRectangle(cornerRadius: 4))
    .sameLevelBorder(radius: 4, color: .textSecondary.opacity(0.28))
  }
}

struct OfferSettingsRowPrototypeView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section {
          HStack(spacing: 12) {
            Image(systemName: "tag")
              .foregroundStyle(Color.brand)
              .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
              Text("Yearlit Offer")
                .font(AppFont.sans(16, weight: .semibold))
              Text("Save 50% on yearly")
                .font(AppFont.sans(13))
                .foregroundStyle(.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.textSecondary)
          }
          .contentShape(Rectangle())
        } header: {
          Text("After Yearlit PRO")
        } footer: {
          Text("Show this row only while a live Offer is available.")
        }
      }
      .navigationTitle("Settings")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  OfferPaywallPrototypeView()
}

#Preview("Settings row") {
  OfferSettingsRowPrototypeView()
}

#endif
