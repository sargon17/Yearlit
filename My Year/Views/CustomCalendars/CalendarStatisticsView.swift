import Garnish
import RevenueCatUI
import SharedModels
import SwiftUI
import SwiftfulRouting

struct CalendarStats {
  // Legacy in-memory name. For weekly calendars this represents active weeks.
  // Kept as-is to avoid broad churn for a UI-only semantic improvement.
  let activeDays: Int
  let totalCount: Int
  let maxCount: Int
  let longestStreak: Int
  let currentStreak: Int
}

struct CalendarStatisticsView: View {
  let stats: CalendarStats
  let accentColor: Color
  let currentPeriodCount: Int?
  let unit: UnitOfMeasure?
  let currencySymbol: String?
  // New advanced metrics
  let completionRateTrailingLongWindow: Double
  let bestWeekday: Int?
  let weekdayRates: [Int: Double]
  let monthlyRates: [Int: Double]
  let averageProgressTrailingShortWindow: Double
  let averageProgressTrailingLongWindow: Double
  let volatilityStdDev: Double
  let currentMissedPeriods: Int
  let averageRecoveryPeriods: Double?
  let isPremium: Bool
  var cadence: CalendarCadence = .daily
  var trackingType: TrackingType = .binary
  var onTapShare: (() -> Void)?

  @Environment(\.router) var router
  @State private var selectedExplanation: MetricExplanation?

  private var displayModel: CalendarStatisticsDisplayModel {
    CalendarStatisticsDisplayModel(
      stats: stats,
      currentPeriodCount: currentPeriodCount,
      unit: unit,
      currencySymbol: currencySymbol,
      completionRateTrailingLongWindow: completionRateTrailingLongWindow,
      bestWeekday: bestWeekday,
      monthlyRates: monthlyRates,
      averageProgressTrailingShortWindow: averageProgressTrailingShortWindow,
      averageProgressTrailingLongWindow: averageProgressTrailingLongWindow,
      volatilityStdDev: volatilityStdDev,
      currentMissedPeriods: currentMissedPeriods,
      averageRecoveryPeriods: averageRecoveryPeriods,
      isPremium: isPremium,
      cadence: cadence,
      trackingType: trackingType
    )
  }

  var body: some View {
    VStack(spacing: 20) {
      VStack(spacing: 16) {
        CustomSeparator()
        HStack {
          Text("Statistics")
            .font(AppFont.mono(36))
            .foregroundColor(Color("text-primary"))
            .fontWeight(.black)
            .padding(.horizontal)

          Spacer()

          if let onTapShare {
            Button(action: onTapShare) {
              Image(systemName: "square.and.arrow.up")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.textTertiary)
                .frame(width: 28, height: 28)
            }
            .padding(.trailing, 12)
          }
        }
      }

      ForEach(displayModel.sections) { section in
        statisticSection(section)
      }
    }
    .sheet(item: $selectedExplanation) { explanation in
      MetricExplanationSheet(explanation: explanation)
        .presentationDetents([.height(380), .medium])
    }
  }

  @ViewBuilder
  private func statisticSection(_ section: StatisticSection) -> some View {
    let tileMetrics = section.metrics.filter {
      $0.presentation == .largeTile || $0.presentation == .smallTile
    }
    let detailMetrics = section.metrics.filter { !tileMetrics.contains($0) }

    VStack(spacing: 12) {
      sectionHeader(LocalizedStringKey(section.title), premium: section.isPremium)
        .padding(.top, section.id == "logging" ? 0 : 12)

      if !tileMetrics.isEmpty {
        LazyVGrid(
          columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
          ],
          alignment: .leading,
          spacing: 14
        ) {
          ForEach(tileMetrics) { metric in
            metricTile(metric)
              .layoutPriority(1)
          }
        }
        .frame(maxWidth: .infinity)
      }

      ForEach(detailMetrics) { metric in
        metricDetail(metric)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal)
    .padding(.bottom, -22)
    .clipped()
    .overlay(bottomDivider)
  }

  @ViewBuilder
  private func metricTile(_ metric: StatisticMetric) -> some View {
    let isLocked = metric.isPremium && !isPremium
    CompactStatTile(
      title: LocalizedStringKey(metric.title),
      value: metric.value,
      accentColor: accentColor,
      size: metric.presentation == .smallTile ? .small : .large,
      isLocked: isLocked,
      onTap: { handleMetricTap(metric) }
    )
  }

  @ViewBuilder
  private func metricDetail(_ metric: StatisticMetric) -> some View {
    let isLocked = metric.isPremium && !isPremium

    switch metric.presentation {
    case .valueRow:
      labeledValueRow(
        title: metric.title,
        value: metric.value,
        accentColor: accentColor,
        isLocked: isLocked
      )
      .contentShape(Rectangle())
      .onTapGesture {
        handleMetricTap(metric)
      }

    case .monthlyBars:
      monthlyBars(
        ratesByMonth: monthlyRates,
        accentColor: accentColor,
        isLocked: isLocked
      )
      .padding(.vertical, 8)
      .contentShape(Rectangle())
      .onTapGesture {
        handleMetricTap(metric)
      }

    case .weekdayRibbon:
      weekdayRibbon(
        rates: weekdayRates,
        accentColor: accentColor,
        isLocked: isLocked
      )
      .frame(maxWidth: .infinity)
      .contentShape(Rectangle())
      .onTapGesture {
        handleMetricTap(metric)
      }

    case .largeTile, .smallTile:
      EmptyView()
    }
  }

  private func handleMetricTap(_ metric: StatisticMetric) {
    if metric.isPremium && !isPremium {
      router.showScreen(.sheet) { _ in
        OnboardingPaywall(
          showsCloseButton: false,
          isPresentedAsSheet: true,
          trigger: .statsGate,
          onNext: {}
        )
      }

      Task {
        await hapticFeedback()
      }
      return
    }

    selectedExplanation = metric.explanation
  }
}

struct StatisticItem: View {
  let title: LocalizedStringKey
  let value: String
  let unit: UnitOfMeasure?
  let currencySymbol: String?
  let accentColor: Color

  var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: .center) {
        Text(title)
          .font(AppFont.mono(12))
          .foregroundColor(Color.textSecondary)

        Spacer()
        Text(verbatim: value)
          .font(AppFont.mono(64))
          .foregroundColor(Color(accentColor))
          .fontWeight(.black)
          .padding(.bottom, -20)
          .minimumScaleFactor(0.5)
          .lineLimit(1)

        if let unit = unit {
          Text(verbatim: unit == .currency ? (currencySymbol ?? "$") : unit.rawValue)
            .font(AppFont.mono(12))
            .foregroundColor(Color("text-tertiary"))
            .padding(.top, -10)
        }
      }
      .clipped()
      .padding(0)
      .padding(.horizontal)
      .overlay(
        VStack {
          Spacer()
          CustomSeparator()
        }
      ).frame(maxWidth: .infinity)
    }
  }
}

// MARK: - Helpers

private var bottomDivider: some View {
  VStack {
    Spacer()
    CustomSeparator()
  }
}

func compactStatsNumber(_ value: Int) -> String {
  let sign = value < 0 ? "-" : ""
  var number = value == Int.min ? Double(Int.max) + 1 : Double(abs(value))
  let units = ["", "K", "M", "B"]
  var unitIndex = 0

  while number >= 1_000, unitIndex < units.count - 1 {
    number /= 1_000
    unitIndex += 1
  }

  guard unitIndex > 0 else {
    return "\(value)"
  }

  var rounded = (number * 10).rounded() / 10
  if rounded >= 1_000, unitIndex < units.count - 1 {
    rounded /= 1_000
    unitIndex += 1
  }

  let text =
    rounded >= 100 || rounded.rounded() == rounded
    ? String(format: "%.0f", rounded)
    : String(format: "%.1f", rounded)
  return "\(sign)\(text)\(units[unitIndex])"
}

private func labeledValueRow(
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
private func weekdayRibbon(
  rates: [Int: Double],
  accentColor: Color,
  isLocked: Bool = false
) -> some View {
  let order = [1, 2, 3, 4, 5, 6, 7]

  HStack(spacing: 6) {
    ForEach(order, id: \.self) { d in
      let v = rates[d] ?? 0
      let bgColor: Color = GarnishColor.blend(.surfaceMuted, with: accentColor, ratio: isLocked ? 0.2 : v)
      let labelColor = (try? bgColor.contrastingShade()) ?? Color.textPrimary
      RoundedRectangle(cornerRadius: 2)
        .fill(bgColor)
        .frame(maxWidth: .infinity, minHeight: 30)
        .overlay(
          Text(weekdayName(d).prefix(1))
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

private func monthlyBars(
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
      ForEach(1...12, id: \.self) { m in
        let v = ratesByMonth[m] ?? 0
        let bgColor: Color = GarnishColor.blend(
          .surfaceMuted,
          with: accentColor,
          ratio: isLocked ? 0.2 : max(0.02, v)
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

/// Section header helper
@ViewBuilder
private func sectionHeader(_ title: LocalizedStringKey, premium: Bool = false) -> some View {
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

private struct MetricExplanationSheet: View {
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
