import SharedModels
import SwiftUI

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

  var body: some View {
    VStack(spacing: 0) {
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
        CustomSeparator()
      }
      // Section: Logging

      VStack(spacing: 12) {
        sectionHeader("Logging")
        HStack {
          CompactStatTile(
            title: "Today",
            value: "\(todaysCount)",
            unit: unit,
            currencySymbol: currencySymbol,
            accentColor: accentColor
          )
          CompactStatTile(
            title: "Total",
            value: "\(stats.totalCount)",
            unit: unit,
            currencySymbol: currencySymbol,
            accentColor: accentColor
          )
          CompactStatTile(
            title: "Day record",
            value: "\(stats.maxCount)",
            unit: unit,
            currencySymbol: currencySymbol,
            accentColor: accentColor
          )
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
            unit: nil,
            currencySymbol: nil,
            accentColor: accentColor
          )
          CompactStatTile(
            title: "Longest",
            value: "\(stats.longestStreak)",
            unit: nil,
            currencySymbol: nil,
            accentColor: accentColor
          )

          CompactStatTile(
            title: "Total Active Days",
            value: "\(stats.activeDays)",
            unit: nil,
            currencySymbol: nil,
            accentColor: accentColor
          )
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
        sectionHeader("Performance")
          .padding(.horizontal)
          .padding(.top)
        VStack(spacing: 8) {
          labeledValueRow(
            title: "Completion Rate (30d)",
            value: percent(completionRateLast30d),
            accentColor: accentColor
          )
          .padding(.horizontal)

          monthlyBars(ratesByMonth: monthlyRates, accentColor: accentColor)
            .padding(.vertical, 8)
            .overlay(bottomDivider)
        }
      }

      // Section: Patterns
      sectionHeader("Patterns")
        .padding(.horizontal)
        .padding(.top)
      VStack(spacing: 8) {
        labeledValueRow(
          title: "Best Weekday",
          value: bestWeekday.map { weekdayName($0) } ?? "—",
          accentColor: accentColor
        )
        .padding(.horizontal)

        weekdayRibbon(rates: weekdayRates, accentColor: accentColor)
          .frame(maxWidth: .greatestFiniteMagnitude)
          .overlay(bottomDivider)
      }

      // Section: Trends (Premium)
      sectionHeader("Trends", premium: true)
        .padding(.horizontal)
        .padding(.top)

      VStack(spacing: 16) {

        // Rolling consistency 7/30d - Premium
        PremiumGate(
          title: "Rolling Consistency (7/30d)",
          isPremium: self.isPremium,
          onUpgrade: self.onUpgrade
        ) {
          HStack {
            VStack(alignment: .leading) {
              Text("7d")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color("text-tertiary"))
              Text(percent(rolling7d))
                .font(.system(size: 28, design: .monospaced))
                .fontWeight(.black)
                .foregroundColor(accentColor)
            }
            Spacer()
            VStack(alignment: .leading) {
              Text("30d")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color("text-tertiary"))
              Text(percent(rolling30d))
                .font(.system(size: 28, design: .monospaced))
                .fontWeight(.black)
                .foregroundColor(accentColor)
            }
          }
        }

        // Volatility - Premium
        PremiumGate(
          title: "Volatility (weekly)",
          isPremium: self.isPremium,
          onUpgrade: self.onUpgrade
        ) {
          labeledValueRow(
            title: "Std Dev of Weekly CR",
            value: String(format: "%.2f", volatilityStdDev),
            accentColor: accentColor
          )
        }
      }.padding(.horizontal)
        .padding(.top)
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
private func labeledValueRow(title: String, value: String, accentColor: Color) -> some View {
  HStack(alignment: .center) {
    Text(title)
      .font(.system(size: 12, design: .monospaced))
      .foregroundColor(Color.textSecondary)
    Spacer()
    Text(value)
      .font(.system(size: 48, design: .monospaced))
      .foregroundColor(accentColor)
      .fontWeight(.black)
      .padding(.bottom, -12)
      .minimumScaleFactor(0.5)
      .lineLimit(1)
  }
  .background(.surfaceMuted)
}

@ViewBuilder
private func weekdayRibbon(rates: [Int: Double], accentColor: Color) -> some View {
  let order = [1, 2, 3, 4, 5, 6, 7]
  HStack(spacing: 6) {
    ForEach(order, id: \.self) { d in
      let v = rates[d] ?? 0
      RoundedRectangle(cornerRadius: 2)
        .fill(accentColor.opacity(max(0.1, v)))
        .frame(maxWidth: .greatestFiniteMagnitude, minHeight: 30)
        .overlay(
          Text(weekdayName(d).prefix(1))
            .font(.system(size: 8, design: .monospaced))
            .foregroundColor(Color.textSecondary)
            .padding(.top, 12), alignment: .top
        )
    }
  }
  .padding(.top)
  .padding(.horizontal)
  .frame(maxWidth: .greatestFiniteMagnitude)
}

@ViewBuilder
private func monthlyBars(ratesByMonth: [Int: Double], accentColor: Color) -> some View {
  VStack(spacing: 6) {
    HStack {
      Text("Monthly Breakdown")
        .font(.system(size: 12, design: .monospaced))
        .foregroundColor(Color.textSecondary)
      Spacer()
    }
    HStack(spacing: 6) {
      ForEach(1...12, id: \.self) { m in
        let v = ratesByMonth[m] ?? 0
        RoundedRectangle(cornerRadius: 2)
          .fill(accentColor.opacity(max(0.2, v)))
          .frame(maxWidth: .greatestFiniteMagnitude, maxHeight: 48)
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
  HStack {
    Text(title)
      .font(.system(size: 14, design: .monospaced))
      .foregroundColor(Color.textPrimary)
    if premium {
      Text("Premium")
        .font(.system(size: 10, design: .monospaced))
        .foregroundColor(Color.textSecondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.textSecondary.opacity(0.5))
        .cornerRadius(4)
    }
    Spacer()
  }
  .padding(.top, 12)
}

// HStack {
//           VStack {
//             VStack(alignment: .center, spacing: 4) {
//               Text("Days")
//                 .font(.system(size: 10))
//                 .foregroundColor(Color("text-tertiary"))

//               VStack(alignment: .center) {
//                 Text("\(stats.activeDays)")
//                   .font(.system(size: 18))
//                   .foregroundColor(Color("text-secondary"))
//                   .fontWeight(.black)

//                 Text("Active")
//                   .font(.system(size: 10))
//                   .foregroundColor(Color("text-tertiary").opacity(0.5))

//               }
//             }.padding(10)
//           }
//           .frame(maxWidth: .infinity)
//           .background(Color("surface-secondary").opacity(0.5))
//           .cornerRadius(10)

//           Spacer()

//           if calendar.trackingType != .binary {

//             VStack {
//               VStack(alignment: .center, spacing: 4) {
//                 Text("Count")
//                   .font(.system(size: 10))
//                   .foregroundColor(Color("text-tertiary"))

//                 HStack {
//                   VStack(alignment: .center) {
//                     Text("\(stats.totalCount)")
//                       .font(.system(size: 18))
//                       .foregroundColor(Color("text-secondary"))
//                       .fontWeight(.black)

//                     Text("Total")
//                       .font(.system(size: 10))
//                       .foregroundColor(Color("text-tertiary").opacity(0.5))
//                   }.frame(maxWidth: .infinity)

//                   VStack(alignment: .center) {
//                     Text("\(stats.maxCount)")
//                       .font(.system(size: 18))
//                       .foregroundColor(Color("text-secondary"))
//                       .fontWeight(.black)

//                     Text("Max")
//                       .font(.system(size: 10))
//                       .foregroundColor(Color("text-tertiary").opacity(0.5))
//                   }.frame(maxWidth: .infinity)

//                 }
//               }
//               .padding(10)
//             }
//             .frame(maxWidth: .infinity)
//             .background(Color("surface-secondary").opacity(0.5))
//             .cornerRadius(10)
//           }

//           VStack {
//             VStack(alignment: .center, spacing: 4) {
//               Text("Streaks")
//                 .font(.system(size: 10))
//                 .foregroundColor(Color("text-tertiary"))

//               HStack {
//                 VStack(alignment: .center) {
//                   Text("\(stats.currentStreak)")
//                     .font(.system(size: 18))
//                     .foregroundColor(Color("text-primary"))
//                     .fontWeight(.black)

//                   Text("Current")
//                     .font(.system(size: 10))
//                     .foregroundColor(Color("text-tertiary").opacity(0.5))
//                 }.frame(maxWidth: .infinity)

//                 VStack(alignment: .center) {
//                   Text("\(stats.longestStreak)")
//                     .font(.system(size: 18))
//                     .foregroundColor(Color("text-secondary"))
//                     .fontWeight(.black)

//                   Text("Longest")
//                     .font(.system(size: 10))
//                     .foregroundColor(Color("text-tertiary").opacity(0.5))
//                 }.frame(maxWidth: .infinity)

//               }
//             }
//             .padding(10)
//           }
//           .frame(maxWidth: .infinity)
//           .background(Color("surface-secondary").opacity(0.5))
//           .cornerRadius(10)
//         }
//         .padding(.horizontal)
