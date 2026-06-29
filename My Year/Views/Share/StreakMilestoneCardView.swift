import Garnish
import SharedModels
import SwiftUI

struct StreakMilestoneCardView: View {
    @Environment(\.locale) private var locale
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
                .font(AppFont.mono(16))
                .foregroundColor(foregroundColor)
                .fontWeight(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(copy.header)
                .font(AppFont.mono(12))
                .foregroundColor(secondaryTextColor)
        }
    }

    private var streakBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(copy.kicker)
                .font(AppFont.mono(10))
                .foregroundColor(secondaryTextColor)
            Text("\(milestone)")
                .font(AppFont.mono(48))
                .foregroundColor(foregroundColor)
                .fontWeight(.black)
            Text(copy.label)
                .font(AppFont.mono(12))
                .foregroundColor(secondaryTextColor)
            if kind == .streak, currentStreak > milestone {
                Text(currentStreakSummary)
                    .font(AppFont.mono(12))
                    .foregroundColor(secondaryTextColor)
            }
        }
    }

    private var currentStreakSummary: String {
        LocalizedCountText.currentStreak(currentStreak, cadence: calendar.cadence, locale: locale)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Text("tracked using")
                .font(AppFont.mono(12))
                .foregroundColor(secondaryTextColor)
                + Text(" yearlit")
                .font(AppFont.mono(12))
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
        (try? Garnish.contrastingShade(of: baseColor)) ?? .white
    }

    private var secondaryTextColor: Color {
        foregroundColor.opacity(0.85)
    }

    private var dividerLight: Color {
        GarnishColor.blend(baseColor, with: foregroundColor, ratio: 0.18)
    }

    private var dividerDark: Color {
        let opposite = (try? Garnish.contrastingShade(of: foregroundColor)) ?? baseColor
        return GarnishColor.blend(baseColor, with: opposite, ratio: 0.18)
    }

    private var highlightColor: Color {
        GarnishColor.blend(baseColor, with: foregroundColor, ratio: 0.2)
    }

    private var copy: MilestoneCopy {
        kind.copy(milestone: milestone, cadence: calendar.cadence)
    }
}
