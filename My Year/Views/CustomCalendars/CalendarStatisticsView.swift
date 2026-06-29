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
  let onUpgrade: () -> Void
  var cadence: CalendarCadence = .daily
  var trackingType: TrackingType = .binary
  var onTapShare: (() -> Void)? = nil

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
    let tileMetrics = section.metrics.filter { $0.presentation == .largeTile || $0.presentation == .smallTile }
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
        PremiumPaywallSheet(trigger: .statsGate)
      }

      Task {
        await hapticFeedback()
      }
      return
    }

    selectedExplanation = metric.explanation
  }
}
