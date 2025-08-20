import Garnish
import SwiftUI

struct FourRules: View {
  let onNext: () -> Void

  var body: some View {
    OnboardingView.OnboardingSlide(onNext: onNext) {
      DynamicBento()
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

private struct DynamicBento: View {
  private let columns: [GridItem] = [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)]
  private let items: [BentoItem] = [
    .init(
      title: "Obvious",
      text: "Keep the cue in sight so the habit is hard to miss.",
      color: .brand, image: "habit_rules_04", aspectRatio: 1.1
    ),
    .init(
      title: "Attractive",
      text: "Pair it with something you already enjoy.",
      color: .brandSecondary, image: "habit_rules_03", aspectRatio: 1.1
    ),
    .init(
      title: "Easy", text: "Shrink it down — start small and simple.",
      color: .brandSecondary, image: "habit_rules_02"
    ),
    .init(
      title: "Satisfying",
      text: "Make progress visible and rewarding right away.",
      color: .brand, image: "habit_rules_01"
    )
  ]

  var body: some View {
    LazyVGrid(columns: columns, alignment: .center, spacing: 6) {
      ForEach(items) { item in
        BentoCard(item: item)
          .aspectRatio(1, contentMode: .fill)
      }
    }
    .padding(.horizontal)
    .accessibilityElement(children: .contain)
  }
}

// MARK: - Models

private struct BentoItem: Identifiable, Hashable {
  let id = UUID()
  let title: String
  let text: String
  let color: Color
  let image: String
  var aspectRatio: Double = 1
}

// MARK: - Card

private struct BentoCard: View {
  let item: BentoItem
  @Environment(\.colorScheme) var colorScheme

  let width: Double = 90

  var body: some View {
    ZStack {
      VStack {
        // RoundedRectangle(cornerRadius: 4, style: .continuous)
        //   .fill(item.color)
        //   .sameLevelBorder(radius: 4, color: item.color)
        //   .frame(maxWidth: .greatestFiniteMagnitude)

        TwinkleImage(
          name: item.image,
          maxWidth: width,
          maxHeight: width * item.aspectRatio,
          position: .polar(center: CGPoint(x: 30, y: 30), radius: 0, degrees: 20),
          scale: 1,
          minOpacity: 0.9,
          maxOpacity: 1.0
        )

        HStack {
          VStack(alignment: .leading, spacing: 8) {
            Spacer()
            HStack(spacing: 4) {
              Text(item.title)
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            }

            Text(item.text)
              .font(.system(size: 10, weight: .regular, design: .monospaced))
          }
          .foregroundStyle(try! Garnish.contrastingShade(of: item.color))
          .padding()

          Spacer()
        }
        .frame(maxWidth: .greatestFiniteMagnitude, maxHeight: .greatestFiniteMagnitude)
      }
      .sameLevelBorder(radius: 4, color: item.color)
    }
    .clipped()
    .frame(maxWidth: .greatestFiniteMagnitude)
    .padding(.all, 2)
    .background(getVoidColor(colorScheme: colorScheme))
    .cornerRadius(6)
    .outerSameLevelShadow(radius: 6)
    .accessibilityLabel(Text(item.title))
  }

  private var gradient: LinearGradient {
    let c = item.color
    return LinearGradient(
      colors: [c.opacity(0.65), c.opacity(0.35)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
}
