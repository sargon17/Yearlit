import Garnish
import RevenueCatUI
import SharedModels
import SwiftUI
import SwiftfulRouting

struct CalendarStats {
  let activeDays: Int
  let totalCount: Int
  let maxCount: Int
  let longestStreak: Int
  let currentStreak: Int
}

struct CalendarStatisticsView: View {
  let stats: CalendarStats
  let accentColor: Color
  let todaysCount: Int
  let unit: UnitOfMeasure?
  let currencySymbol: String?
  // New advanced metrics
  let completionRateLast30d: Double
  let bestWeekday: Int?
  let weekdayRates: [Int: Double]
  let monthlyRates: [Int: Double]
  let rolling7d: Double
  let rolling30d: Double
  let volatilityStdDev: Double
  let isPremium: Bool
  let onUpgrade: () -> Void
  var trackingType: TrackingType = .binary

  @Environment(\.router) var router

  var entriesLabel: String {
    if let unit = unit {
      if unit == .currency {
        return currencySymbol ?? "€"
      }
      return unit.displayName
    } else {
      return "Entries"
    }
  }

  var body: some View {
    VStack(spacing: 20) {
      VStack(spacing: 16) {
        CustomSeparator()
        HStack {
          Text("Statistics")
            .font(.system(size: 36, design: .monospaced))
            .foregroundColor(Color("text-primary"))
            .fontWeight(.black)
            .padding(.horizontal)

          Spacer()
        }
      }
      // Section: Logging

      VStack(spacing: 12) {
        sectionHeader(entriesLabel)
        HStack {
          CompactStatTile(
            title: "Today",
            value: "\(todaysCount)",
            accentColor: accentColor
          )
          .layoutPriority(1)
          CompactStatTile(
            title: "Total",
            value: "\(stats.totalCount)",
            accentColor: accentColor
          )
          .layoutPriority(1)
          if trackingType != .binary {
            CompactStatTile(
              title: "Best Day",
              value: "\(stats.maxCount)",
              accentColor: accentColor
            )
            .layoutPriority(1)
          }
        }
        .frame(maxWidth: .greatestFiniteMagnitude)
      }
      .frame(maxWidth: .greatestFiniteMagnitude)
      .padding(.horizontal)
      .padding(.bottom, -12)
      .clipped()
      .overlay(bottomDivider)

      // Section: Streaks
      VStack(spacing: 12) {
        sectionHeader("Streaks")
          .padding(.top)
        HStack {
          CompactStatTile(
            title: "Current",
            value: "\(stats.currentStreak)",
            accentColor: accentColor
          )
          .layoutPriority(1)
          CompactStatTile(
            title: "Longest",
            value: "\(stats.longestStreak)",
            accentColor: accentColor
          )
          .layoutPriority(1)

          CompactStatTile(
            title: "Active Days",
            value: "\(stats.activeDays)",
            accentColor: accentColor
          )
          .layoutPriority(1)
        }
        .frame(maxWidth: .greatestFiniteMagnitude)
      }
      .frame(maxWidth: .greatestFiniteMagnitude)
      .padding(.horizontal)
      .padding(.bottom, -12)
      .clipped()
      .overlay(bottomDivider)

      // Section: Performance
      VStack {
        sectionHeader("Performance", premium: !isPremium)
          .padding(.horizontal)
          .padding(.top)
        VStack(spacing: 8) {
          labeledValueRow(
            title: "Completion Rate (30d)",
            value: percent(completionRateLast30d),
            accentColor: accentColor,
            isLocked: !isPremium
          )
          .padding(.horizontal)
          .onTapGesture {
            guard !isPremium else { return }

            router.showScreen(.sheet) { _ in
              PaywallView()
            }

            Task {
              await hapticFeedback()
            }
          }

          monthlyBars(
            ratesByMonth: monthlyRates,
            accentColor: accentColor,
            isLocked: !isPremium
          )
          .padding(.vertical, 8)
          .overlay(bottomDivider)
          .onTapGesture {
            guard !isPremium else { return }

            router.showScreen(.sheet) { _ in
              PaywallView()
            }

            Task {
              await hapticFeedback()
            }
          }

        }
      }

      VStack {

        // Section: Patterns
        sectionHeader("Patterns", premium: !isPremium)
          .padding(.horizontal)
          .padding(.top)
        VStack(spacing: 8) {
          labeledValueRow(
            title: "Best Weekday",
            value: bestWeekday.map { weekdayName($0) } ?? "—",
            accentColor: accentColor,
            isLocked: !isPremium
          )
          .padding(.horizontal)
          .onTapGesture {
            guard !isPremium else { return }

            router.showScreen(.sheet) { _ in
              PaywallView()
            }

            Task {
              await hapticFeedback()
            }
          }
        }

        weekdayRibbon(
          rates: weekdayRates,
          accentColor: accentColor,
          isLocked: !isPremium
        )
        .frame(maxWidth: .greatestFiniteMagnitude)
        .overlay(bottomDivider)
        .onTapGesture {
          guard !isPremium else { return }

          router.showScreen(.sheet) { _ in
            PaywallView()
          }

          Task {
            await hapticFeedback()
          }
        }

      }
      .clipped()

      // Section: Trends (Premium)
      sectionHeader("Trends", premium: !isPremium)
        .padding(.horizontal)
        .padding(.top)

      VStack(spacing: 16) {
        HStack {
          CompactStatTile(
            title: "7d",
            value: "\(percent(rolling7d))",
            accentColor: accentColor,
            size: .small,
            isLocked: !isPremium
          )
          .layoutPriority(1)
          CompactStatTile(
            title: "30d",
            value: "\(percent(rolling30d))",
            accentColor: accentColor,
            size: .small,
            isLocked: !isPremium
          )
          .layoutPriority(1)
        }
        .frame(maxWidth: .greatestFiniteMagnitude)

        // Volatility - Premium
        labeledValueRow(
          title: "Std Dev of Weekly CR",
          value: String(format: "%.2f", volatilityStdDev),
          accentColor: accentColor,
          isLocked: !isPremium
        )
        .onTapGesture {
          guard !isPremium else { return }

          router.showScreen(.sheet) { _ in
            PaywallView()
          }

          Task {
            await hapticFeedback()
          }
        }

      }.padding(.horizontal)
    }
  }
}

struct StatisticItem: View {
  let title: String
  let value: String
  let unit: UnitOfMeasure?
  let currencySymbol: String?
  let accentColor: Color

  var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: .center) {
        Text(title)
          .font(.system(size: 12, design: .monospaced))
          .foregroundColor(Color.textSecondary)

        Spacer()
        Text(value)
          .font(.system(size: 64, design: .monospaced))
          .foregroundColor(Color(accentColor))
          .fontWeight(.black)
          .padding(.bottom, -20)
          .minimumScaleFactor(0.5)
          .lineLimit(1)

        if let unit = unit {
          Text(unit == .currency ? (currencySymbol ?? "$") : unit.rawValue)
            .font(.system(size: 12, design: .monospaced))
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

private func weekdayName(_ idx: Int) -> String {
  let symbols = Calendar.current.shortWeekdaySymbols  // Sun..Sat depending on locale
  let clamped = max(1, min(7, idx))
  return symbols[clamped - 1]
}

private func percent(_ value: Double) -> String {
  let p = max(0, min(1, value))
  return String(format: "%.0f%%", p * 100)
}

@ViewBuilder
private func labeledValueRow(
  title: String,
  value: String,
  accentColor: Color,
  isLocked: Bool = false
) -> some View {

  HStack(alignment: .center) {
    Text(title)
      .font(.system(size: 12, design: .monospaced))
      .foregroundColor(Color.textSecondary)
    Spacer()
    Text(value)
      .font(.system(size: 24, design: .monospaced))
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
      let labelColor = try! bgColor.contrastingShade()
      RoundedRectangle(cornerRadius: 2)
        .fill(bgColor)
        .frame(maxWidth: .greatestFiniteMagnitude, minHeight: 30)
        .overlay(
          Text(weekdayName(d).prefix(1))
            .font(.system(size: 8, design: .monospaced))
            .foregroundColor(labelColor)
            .padding(.top, 12), alignment: .top
        )
        .blur(radius: isLocked ? 10 : 0)
    }
  }
  .padding(.top)
  .padding(.horizontal)
  .frame(maxWidth: .greatestFiniteMagnitude)
}

@ViewBuilder
private func monthlyBars(
  ratesByMonth: [Int: Double],
  accentColor: Color,
  isLocked: Bool = false
) -> some View {
  VStack(spacing: 6) {
    HStack {
      Text("Monthly Breakdown")
        .font(.system(size: 12, design: .monospaced))
        .foregroundColor(Color.textSecondary)
      Spacer()
    }.padding(.bottom, 8)
    HStack(spacing: 6) {
      ForEach(1...12, id: \.self) { m in
        let v = ratesByMonth[m] ?? 0
        var bgColor: Color = GarnishColor.blend(.surfaceMuted, with: accentColor, ratio: isLocked ? 0.2 : max(0.02, v))
        RoundedRectangle(cornerRadius: 2)
          .fill(bgColor)
          .frame(maxWidth: .greatestFiniteMagnitude, maxHeight: 48)
          .blur(radius: isLocked ? 10 : 0)
      }
    }
  }.padding()
}

struct PremiumGate<Content: View>: View {
  let title: String
  let isPremium: Bool
  let onUpgrade: () -> Void
  let content: () -> Content

  init(
    title: String,
    isPremium: Bool,
    onUpgrade: @escaping () -> Void,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.title = title
    self.isPremium = isPremium
    self.onUpgrade = onUpgrade
    self.content = content
  }

  var body: some View {
    VStack(spacing: 8) {
      HStack {
        Text(title)
          .font(.system(size: 12, design: .monospaced))
          .foregroundColor(Color.textSecondary)
        Spacer()
      }
      if self.isPremium {
        content()
      } else {
        HStack {
          Text("Unlock with Premium")
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(Color("text-tertiary"))
          Spacer()
          Button(action: self.onUpgrade) {
            Text("Upgrade")
              .font(.system(size: 12, design: .monospaced))
              .padding(.horizontal, 10)
              .padding(.vertical, 6)
              .background(Color("surface-secondary").opacity(0.5))
              .cornerRadius(6)
          }
        }
      }
    }
  }
}

// Section header helper
@ViewBuilder
private func sectionHeader(_ title: String, premium: Bool = false) -> some View {
  let bgColor = try! GarnishColor.blend(.surfaceMuted, with: .moodExcellent, ratio: 0.2)
  let fgColor = try! GarnishColor.blend(.textPrimary, with: .moodExcellent, ratio: 0.5)

  HStack {
    Text(title)
      .font(.system(size: 14, design: .monospaced))
      .foregroundColor(Color.textPrimary)
    if premium {
      Text("Premium")
        .font(.system(size: 8, design: .monospaced))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
          RoundedRectangle(cornerRadius: 4)
            .stroke(
              style: .init(
                lineWidth: 1, lineCap: .round, lineJoin: .bevel, miterLimit: 1, dash: [2],
                dashPhase: 2
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
