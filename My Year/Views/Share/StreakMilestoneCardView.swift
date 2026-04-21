import Garnish
import SharedModels
import SwiftUI

struct StreakMilestoneCardView: View {
    let calendar: CustomCalendar
    let milestone: Int
    let currentStreak: Int
    let dates: [Date]
    let kind: MilestoneKind
    let glareOffset: CGSize

    init(
        calendar: CustomCalendar,
        milestone: Int,
        currentStreak: Int,
        dates: [Date],
        kind: MilestoneKind = .streak,
        glareOffset: CGSize = .zero
    ) {
        self.calendar = calendar
        self.milestone = milestone
        self.currentStreak = currentStreak
        self.dates = dates
        self.kind = kind
        self.glareOffset = glareOffset
    }

    var body: some View {
        ZStack {
            cardBackground

            VStack(alignment: .leading, spacing: 10) {
                header

                MilestoneDivider(
                    lightColor: dividerLight,
                    darkColor: dividerDark
                )
                .padding(.horizontal, -28)

                streakBlock

                MilestoneGridView(
                    calendar: calendar,
                    dates: dates,
                    foregroundColor: foregroundColor
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                MilestoneDivider(
                    lightColor: dividerLight,
                    darkColor: dividerDark
                )
                .padding(.horizontal, -28)
                footer
            }
            .padding()
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(calendar.name.capitalized)
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(foregroundColor)
                .fontWeight(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(copy.header)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(secondaryTextColor)
        }
    }

    private var streakBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(copy.kicker)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(secondaryTextColor)
            Text("\(milestone)")
                .font(.system(size: 48, design: .monospaced))
                .foregroundColor(foregroundColor)
                .fontWeight(.black)
            Text(copy.label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(secondaryTextColor)
            if kind == .streak, currentStreak > milestone {
                Text("Now at \(currentStreak) \(calendar.cadence == .weekly ? "weeks" : "days")")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(secondaryTextColor)
            }
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Text("tracked using")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(secondaryTextColor)
                + Text(" yearlit")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(foregroundColor)

            Image("icon")
                .resizable()
                .frame(width: 16, height: 16)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(baseColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                highlightColor.opacity(0.55),
                                baseColor.opacity(0.1),
                                baseColor.opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: highlightColor.opacity(0.6), radius: 30, x: 0, y: -6)
            .shadow(color: foregroundColor.opacity(0.2), radius: 12, x: 0, y: 10)
            .overlay(glareOverlay)
            .overlay(flameOverlay)
            .overlay(NoiseLayer(opacity: 0.25, blendMode: .overlay))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(foregroundColor.opacity(0.2), lineWidth: 1)
            )
    }

    private var flameOverlay: some View {
        ZStack {
            Image(systemName: "flame.fill")
                .font(.system(size: 140, weight: .black))
                .foregroundColor(foregroundColor.opacity(0.08))
                .rotationEffect(.degrees(-12))
                .offset(x: 110, y: -120)
        }
    }

    private var glareOverlay: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.5),
                        Color.white.opacity(0.0),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .rotationEffect(.degrees(-8))
            .offset(x: -40 + glareOffset.width, y: -60 + glareOffset.height)
            .blendMode(.screen)
            .opacity(0.6)
    }

    private var baseColor: Color {
        Color(calendar.color)
    }

    private var foregroundColor: Color {
        try! Garnish.contrastingShade(of: baseColor)
    }

    private var secondaryTextColor: Color {
        foregroundColor.opacity(0.85)
    }

    private var dividerLight: Color {
        GarnishColor.blend(baseColor, with: foregroundColor, ratio: 0.18)
    }

    private var dividerDark: Color {
        let opposite = try! Garnish.contrastingShade(of: foregroundColor)
        return GarnishColor.blend(baseColor, with: opposite, ratio: 0.18)
    }

    private var highlightColor: Color {
        GarnishColor.blend(baseColor, with: foregroundColor, ratio: 0.2)
    }

    private var copy: MilestoneCopy {
        let unitSingular = calendar.cadence == .weekly ? "Week" : "Day"
        let unitPlural = calendar.cadence == .weekly ? "Weeks" : "Days"

        switch kind {
        case .streak:
            switch milestone {
            case 1:
                return MilestoneCopy(
                    header: calendar.cadence == .weekly ? "First week down" : "First day down",
                    kicker: "Streak started",
                    label: "\(unitSingular) in a row"
                )
            case 2 ... 3:
                return MilestoneCopy(header: "Keep it going", kicker: "Momentum building", label: "\(unitPlural) in a row")
            case 4 ... 5:
                return MilestoneCopy(
                    header: "You are on fire",
                    kicker: calendar.cadence == .weekly ? "Strong weekly momentum" : "Strong daily momentum",
                    label: "\(unitPlural) in a row"
                )
            case 6 ... 10:
                return MilestoneCopy(
                    header: "This is real",
                    kicker: calendar.cadence == .weekly ? "Locked in week after week" : "Locked in day after day",
                    label: "\(unitPlural) straight"
                )
            case 11 ... 20:
                return MilestoneCopy(
                    header: "Streak machine",
                    kicker: calendar.cadence == .weekly ? "Weekly consistency unlocked" : "Daily consistency unlocked",
                    label: "\(unitPlural) straight"
                )
            case 21 ... 30:
                return MilestoneCopy(
                    header: "No misses",
                    kicker: calendar.cadence == .weekly ? "Still stacking great weeks" : "Still stacking great days",
                    label: "\(unitPlural) straight"
                )
            case 31 ... 50:
                return MilestoneCopy(
                    header: "Unreal run",
                    kicker: calendar.cadence == .weekly ? "An unreal weekly run" : "An unreal daily run",
                    label: "\(unitPlural) blazing"
                )
            default:
                return MilestoneCopy(
                    header: "Legendary streak",
                    kicker: "\(milestone) \(calendar.cadence == .weekly ? "weeks" : "days") strong",
                    label: "\(unitPlural) blazing"
                )
            }
        case .showedUp:
            switch milestone {
            case 5:
                return MilestoneCopy(
                    header: "You showed up",
                    kicker: calendar.cadence == .weekly ? "A strong weekly start" : "A strong daily start",
                    label: "\(unitPlural) showed up"
                )
            case 10:
                return MilestoneCopy(
                    header: "Consistency unlocked",
                    kicker: calendar.cadence == .weekly ? "Week after week" : "Day after day",
                    label: "\(unitPlural) showed up"
                )
            case 20:
                return MilestoneCopy(
                    header: "You are in it",
                    kicker: calendar.cadence == .weekly ? "Deep into the rhythm" : "Deep into the rhythm",
                    label: "\(unitPlural) showed up"
                )
            case 30:
                return MilestoneCopy(
                    header: calendar.cadence == .weekly ? "A huge run" : "A full month",
                    kicker: calendar.cadence == .weekly ? "That is serious consistency" : "Thirty days strong",
                    label: "\(unitPlural) showed up"
                )
            case 40:
                return MilestoneCopy(
                    header: "No excuses",
                    kicker: calendar.cadence == .weekly ? "Still showing up every week" : "Still showing up every day",
                    label: "\(unitPlural) showed up"
                )
            case 50:
                return MilestoneCopy(
                    header: "Beast mode",
                    kicker: calendar.cadence == .weekly ? "Weekly consistency on lock" : "Fifty days strong",
                    label: "\(unitPlural) showed up"
                )
            case 75:
                return MilestoneCopy(
                    header: "You are relentless",
                    kicker: "Seventy-five \(calendar.cadence == .weekly ? "weeks" : "days")",
                    label: "\(unitPlural) showed up"
                )
            case 100:
                return MilestoneCopy(
                    header: "Century club",
                    kicker: "100 \(calendar.cadence == .weekly ? "weeks" : "days") showed up",
                    label: "\(unitPlural) showed up"
                )
            case 150:
                return MilestoneCopy(
                    header: "Absolutely unreal",
                    kicker: "150 \(calendar.cadence == .weekly ? "weeks" : "days") in",
                    label: "\(unitPlural) showed up"
                )
            default:
                return MilestoneCopy(
                    header: "Built different",
                    kicker: "\(milestone) \(calendar.cadence == .weekly ? "weeks" : "days") showed up",
                    label: "\(unitPlural) showed up"
                )
            }
        case .showedUpMonth:
            switch milestone {
            case 3:
                return MilestoneCopy(
                    header: "Month in motion",
                    kicker: "A clean start this month",
                    label: "\(unitPlural) showed up this month"
                )
            case 5 ... 7:
                return MilestoneCopy(
                    header: "You are showing up",
                    kicker: "This month has momentum",
                    label: "\(unitPlural) showed up this month"
                )
            case 8 ... 14:
                return MilestoneCopy(
                    header: "Strong month",
                    kicker: "You keep coming back",
                    label: "\(unitPlural) showed up this month"
                )
            case 15 ... 21:
                return MilestoneCopy(
                    header: "Locked in",
                    kicker: "Half the month and counting",
                    label: "\(unitPlural) showed up this month"
                )
            default:
                return MilestoneCopy(
                    header: "Month owned",
                    kicker: "This month has your name on it",
                    label: "\(unitPlural) showed up this month"
                )
            }
        case .showedUpYear:
            switch milestone {
            case 7:
                return MilestoneCopy(
                    header: "Year started right",
                    kicker: "Seven days already banked",
                    label: "\(unitPlural) showed up this year"
                )
            case 8 ... 30:
                return MilestoneCopy(
                    header: "Building the year",
                    kicker: "A real base is forming",
                    label: "\(unitPlural) showed up this year"
                )
            case 31 ... 90:
                return MilestoneCopy(
                    header: "This is lasting",
                    kicker: "You keep stacking good days",
                    label: "\(unitPlural) showed up this year"
                )
            case 91 ... 180:
                return MilestoneCopy(
                    header: "Half-year pace",
                    kicker: "This is bigger than a phase",
                    label: "\(unitPlural) showed up this year"
                )
            default:
                return MilestoneCopy(
                    header: "Year on lock",
                    kicker: "You are writing the whole story",
                    label: "\(unitPlural) showed up this year"
                )
            }
        }
    }
}

enum MilestoneKind: String {
    case streak
    case showedUp
    case showedUpMonth
    case showedUpYear
}

private struct MilestoneDivider: View {
    let lightColor: Color
    let darkColor: Color

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(lightColor)
                .frame(height: 1)
            Rectangle()
                .fill(darkColor)
                .frame(height: 1)
                .offset(y: -0.5)
        }
    }
}

private struct MilestoneCopy {
    let header: LocalizedStringKey
    let kicker: LocalizedStringKey
    let label: LocalizedStringKey
}

private struct MilestoneGridView: View {
    let calendar: CustomCalendar
    let dates: [Date]
    let foregroundColor: Color

    private var maxCount: Int {
        getMaxCount(calendar: calendar)
    }

    var body: some View {
        GeometryReader { geometry in
            let dotSize: CGFloat = 10
            let padding: CGFloat = 0
            let availableWidth = max(0, geometry.size.width - (padding * 2))
            let availableHeight = max(1, geometry.size.height - (padding * 2))
            let aspectRatio = max(0.001, availableWidth / availableHeight)
            let columns = adjustedColumns(for: dates.count, aspectRatio: aspectRatio)
            let rows = max(1, Int(ceil(Double(dates.count) / Double(columns))))
            let horizontalSpacing = (availableWidth - (dotSize * CGFloat(columns))) / CGFloat(max(2, columns - 1))
            let verticalSpacing = (availableHeight - (dotSize * CGFloat(rows))) / CGFloat(max(2, rows - 1))

            VStack(spacing: verticalSpacing) {
                ForEach(0 ..< rows, id: \.self) { row in
                    HStack(spacing: horizontalSpacing) {
                        ForEach(0 ..< columns, id: \.self) { col in
                            let dayIndex = row * columns + col
                            if dayIndex < dates.count {
                                GridDot(
                                    color: dotColor(for: dates[dayIndex]),
                                    dotSize: dotSize
                                )
                            } else {
                                Color.clear.frame(width: dotSize, height: dotSize)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func dotColor(for date: Date) -> Color {
        if date.isInFuture {
            return foregroundColor.opacity(0.12)
        }
        let entry = entry(for: calendar, date: date)
        switch calendar.trackingType {
        case .binary:
            return entry?.completed == true ? foregroundColor : foregroundColor.opacity(0.25)
        case .counter:
            guard let entry, entry.count > 0 else { return foregroundColor.opacity(0.25) }
            let ratio = min(1, max(0.2, Double(entry.count) / Double(maxCount)))
            return foregroundColor.opacity(ratio)
        case .multipleDaily:
            guard let entry, entry.count > 0 else { return foregroundColor.opacity(0.25) }
            let ratio = min(1, max(0.2, Double(entry.count) / Double(calendar.dailyTarget)))
            return foregroundColor.opacity(ratio)
        }
    }
}

private func adjustedColumns(for count: Int, aspectRatio: CGFloat) -> Int {
    let targetColumns = max(1, Int(sqrt(Double(count) * aspectRatio)))
    var columns = max(1, min(targetColumns, count))
    while columns > 1 && count % columns == 1 {
        columns -= 1
    }
    return columns
}
