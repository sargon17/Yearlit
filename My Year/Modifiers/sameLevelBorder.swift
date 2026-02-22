import SwiftUI
import UIKit

struct SameLevelBorder: ViewModifier {
    let radius: CGFloat
    let color: Color
    let isFlat: Bool

    init(radius: CGFloat = 4, color: Color = .surfaceMuted, isFlat: Bool = false) {
        self.radius = radius
        self.color = color
        self.isFlat = isFlat
    }

    @Environment(\.colorScheme) var colorScheme
    private let lightOffset: CGFloat = 2.6
    private let darkOffset: CGFloat = -2.6

    func body(content: Content) -> some View {
        let lightModeScale = colorScheme == .dark ? 1.0 : shadowScale(for: color)
        let flatScale: Double = isFlat ? 0.2 : 1
        let lightOpacitySmall = clampedOpacity((colorScheme == .dark ? 0.05 : 0.3) * lightModeScale * flatScale)
        let lightOpacityLarge = clampedOpacity((colorScheme == .dark ? 0.05 : 0.6) * lightModeScale * flatScale)
        let darkOpacitySmall = clampedOpacity((colorScheme == .dark ? 0.5 : 0.4) * lightModeScale * flatScale)
        let darkOpacityLarge = clampedOpacity((colorScheme == .dark ? 0.4 : 0.1) * lightModeScale * flatScale)

        ZStack {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: radius)
                .foregroundStyle(
                    color
                        .shadow(
                            .inner(
                                color: .white.opacity(lightOpacitySmall),
                                radius: 0.5,
                                x: lightOffset,
                                y: lightOffset
                            )
                        ) // inner light shadow
                        .shadow(
                            .inner(
                                color: .white.opacity(lightOpacityLarge),
                                radius: 4,
                                x: lightOffset * 2,
                                y: lightOffset * 2
                            )
                        )

                        .shadow(
                            .inner(
                                color: .black.opacity(darkOpacitySmall),
                                radius: 0.5,
                                x: darkOffset,
                                y: darkOffset
                            )
                        ) // inner dark shadow
                        .shadow(
                            .inner(
                                color: .black.opacity(darkOpacityLarge),
                                radius: 4,
                                x: darkOffset * 2,
                                y: darkOffset * 2
                            )
                        ) // inner dark shadow
                )
                .overlay(
                    NoiseLayer(opacity: 0.35, blendMode: nil)
                        .mask(RoundedRectangle(cornerRadius: radius))
                )
                .shadow(
                    color: .black.opacity(
                        clampedOpacity((colorScheme == .dark ? 0.4 : 0.4) * lightModeScale * flatScale)
                    ),
                    radius: isFlat ? 1 : 2,
                    x: isFlat ? 1 : 4,
                    y: isFlat ? 1 : 6
                )
        )
    }

    private func shadowScale(for color: Color) -> Double {
        let luminance = relativeLuminance(for: color)
        return 0.6 + (0.8 * luminance)
    }

    private func relativeLuminance(for color: Color) -> Double {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return 0.5
        }
        return Double(0.2126 * red + 0.7152 * green + 0.0722 * blue)
    }

    private func clampedOpacity(_ value: Double) -> Double {
        min(1, max(0, value))
    }
}

func getVoidColor(colorScheme: ColorScheme) -> Color {
    return colorScheme == .dark ? .black.opacity(1) : .black.opacity(0.9)
}

extension View {
    func sameLevelBorder(radius: CGFloat = 4, color: Color = .surfaceMuted, isFlat: Bool = false)
        -> some View
    {
        modifier(SameLevelBorder(radius: radius, color: color, isFlat: isFlat))
    }
}

struct OuterSameLevelShadow: ViewModifier {
    let radius: CGFloat
    private let lightOffset: CGFloat = 0.6
    private let darkOffset: CGFloat = -0.6

    @Environment(\.colorScheme) var colorScheme

    init(radius: CGFloat = 0.5) {
        self.radius = radius
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .foregroundStyle(
                        .surfaceMuted
                            .shadow(
                                .drop(
                                    color: .white.opacity(colorScheme == .dark ? 0.05 : 0.3),
                                    radius: 0.2,
                                    x: lightOffset,
                                    y: lightOffset
                                )
                            )

                            .shadow(
                                .drop(
                                    color: .black.opacity(colorScheme == .dark ? 1 : 0.4),
                                    radius: 0.2,
                                    x: darkOffset,
                                    y: darkOffset
                                )
                            )
                    )
            )
    }
}

extension View {
    func outerSameLevelShadow(radius: CGFloat = 6) -> some View {
        modifier(OuterSameLevelShadow(radius: radius))
    }
}
