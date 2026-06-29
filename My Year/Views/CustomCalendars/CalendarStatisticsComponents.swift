import Garnish
import SwiftUI

var bottomDivider: some View {
  VStack {
    Spacer()
    CustomSeparator()
  }
}

func labeledValueRow(
  title: String,
  value: String,
  accentColor: Color,
  isLocked: Bool = false
) -> some View {
  HStack(alignment: .center) {
    Text(title)
      .font(AppFont.mono(12))
      .foregroundColor(Color.textSecondary)
    Spacer()
    Text(verbatim: value)
      .font(AppFont.pixelCircle(24))
      .foregroundColor(accentColor)
      .fontWeight(.black)
      .minimumScaleFactor(0.5)
      .lineLimit(1)
      .blur(radius: isLocked ? 10 : 0)
  }
  .background(.surfaceMuted)
}

@ViewBuilder
func weekdayRibbon(
  rates: [Int: Double],
  accentColor: Color,
  isLocked: Bool = false
) -> some View {
  let order = [1, 2, 3, 4, 5, 6, 7]

  HStack(spacing: 6) {
    ForEach(order, id: \.self) { day in
      let rate = rates[day] ?? 0
      let bgColor = GarnishColor.blend(.surfaceMuted, with: accentColor, ratio: isLocked ? 0.2 : rate)
      let labelColor = (try? bgColor.contrastingShade()) ?? Color.textPrimary
      RoundedRectangle(cornerRadius: 2)
        .fill(bgColor)
        .frame(maxWidth: .infinity, minHeight: 30)
        .overlay(
          Text(weekdayName(day).prefix(1))
            .font(AppFont.mono(8))
            .foregroundColor(labelColor)
            .padding(.top, 12), alignment: .top
        )
        .blur(radius: isLocked ? 10 : 0)
    }
  }
  .padding(.top)
  .frame(maxWidth: .infinity)
}

func monthlyBars(
  ratesByMonth: [Int: Double],
  accentColor: Color,
  isLocked: Bool = false
) -> some View {
  VStack(spacing: 6) {
    HStack {
      Text("Year Pattern")
        .font(AppFont.mono(12))
        .foregroundColor(Color.textSecondary)
      Spacer()
    }.padding(.bottom, 8)
    HStack(spacing: 6) {
      ForEach(1...12, id: \.self) { month in
        let rate = ratesByMonth[month] ?? 0
        let bgColor = GarnishColor.blend(
          .surfaceMuted,
          with: accentColor,
          ratio: isLocked ? 0.2 : max(0.02, rate)
        )
        RoundedRectangle(cornerRadius: 2)
          .fill(bgColor)
          .frame(maxWidth: .infinity, maxHeight: 48)
          .blur(radius: isLocked ? 10 : 0)
      }
    }
  }
  .padding(.vertical, 8)
}

@ViewBuilder
func sectionHeader(_ title: LocalizedStringKey, premium: Bool = false) -> some View {
  let bgColor = GarnishColor.blend(.surfaceMuted, with: .moodExcellent, ratio: 0.2)
  let fgColor = GarnishColor.blend(.textPrimary, with: .moodExcellent, ratio: 0.5)

  HStack {
    Text(title)
      .font(AppFont.mono(14))
      .foregroundColor(Color.textPrimary)
    if premium {
      Text("PRO")
        .font(AppFont.mono(8))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
          RoundedRectangle(cornerRadius: 4)
            .stroke(
              style: .init(
                lineWidth: 1, lineCap: .round, lineJoin: .bevel, miterLimit: 1, dash: [2],
                dashPhase: 3
              )
            )
        )
        .background(bgColor)
        .foregroundColor(fgColor)
    }
    Spacer()
  }
  .padding(.top, 12)
}

struct MetricExplanationSheet: View {
  let explanation: MetricExplanation

  var body: some View {
    VStack(alignment: .leading, spacing: 22) {
      Text(explanation.title)
        .font(AppFont.mono(28))
        .fontWeight(.black)
        .foregroundColor(.textPrimary)

      explanationBlock(title: "What it means", body: explanation.meaning)
      explanationBlock(title: "How to read it", body: explanation.howToRead)
      explanationBlock(title: "Why it matters", body: explanation.whyItMatters)

      Spacer(minLength: 0)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
  }

  private func explanationBlock(title: String, body: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(AppFont.mono(12))
        .foregroundColor(.textSecondary)
      Text(body)
        .font(AppFont.mono(14))
        .foregroundColor(.textPrimary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}
