import SwiftUI
#if canImport(WidgetKit)
    import WidgetKit
#endif

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

public enum WidgetStyle {
    public enum RenderingMode {
        case fullColor
        case reduced

        public var isMonochrome: Bool {
            self == .reduced
        }

        #if canImport(WidgetKit)
            public init(_ widgetRenderingMode: WidgetRenderingMode) {
                switch widgetRenderingMode {
                case .fullColor:
                    self = .fullColor
                case .accented:
                    self = .reduced
                case .vibrant:
                    self = .reduced
                default:
                    self = .reduced
                }
            }
        #endif
    }

    public struct GridLayout {
        public let columns: Int
        public let rows: Int
        public let horizontalSpacing: CGFloat
        public let verticalSpacing: CGFloat

        public init(columns: Int, rows: Int, horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
            self.columns = columns
            self.rows = rows
            self.horizontalSpacing = horizontalSpacing
            self.verticalSpacing = verticalSpacing
        }
    }

    public static func adjustedColumns(for count: Int, aspectRatio: CGFloat) -> Int {
        let targetColumns = max(1, Int(sqrt(Double(count) * aspectRatio)))
        var columns = max(1, min(targetColumns, count))
        while columns > 1 && count % columns == 1 {
            columns -= 1
        }
        return columns
    }

    public static func gridLayout(
        count: Int,
        dotSize: CGFloat,
        availableWidth: CGFloat,
        availableHeight: CGFloat
    ) -> GridLayout {
        let safeWidth = max(1, availableWidth)
        let safeHeight = max(1, availableHeight)
        let aspectRatio = max(0.001, safeWidth / safeHeight)
        let columns = adjustedColumns(for: count, aspectRatio: aspectRatio)
        let rows = max(1, Int(ceil(Double(count) / Double(columns))))
        let horizontalSpacing =
            (safeWidth - (dotSize * CGFloat(columns))) / CGFloat(max(2, columns - 1))
        let verticalSpacing =
            (safeHeight - (dotSize * CGFloat(rows))) / CGFloat(max(2, rows - 1))

        return GridLayout(
            columns: columns,
            rows: rows,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing
        )
    }

    public static func blendedColor(base: Color, overlay: Color, ratio: Double) -> Color {
        let clampedRatio = max(0, min(1, ratio))
        guard
            let baseRGBA = rgba(from: base),
            let overlayRGBA = rgba(from: overlay)
        else {
            return base
        }

        let red = baseRGBA.red + (overlayRGBA.red - baseRGBA.red) * clampedRatio
        let green = baseRGBA.green + (overlayRGBA.green - baseRGBA.green) * clampedRatio
        let blue = baseRGBA.blue + (overlayRGBA.blue - baseRGBA.blue) * clampedRatio
        let alpha = baseRGBA.alpha + (overlayRGBA.alpha - baseRGBA.alpha) * clampedRatio

        return Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
    }

    public static func inactiveDotColor(
        surface: Color = Color("surface-muted"),
        text: Color = Color("text-primary"),
        ratio: Double = 0.025
    ) -> Color {
        blendedColor(base: surface, overlay: text, ratio: ratio)
    }

    public static func activeDotColor(
        surface: Color = Color("surface-muted"),
        text: Color = Color("text-primary"),
        ratio: Double = 0.12
    ) -> Color {
        blendedColor(base: surface, overlay: text, ratio: ratio)
    }

    public static func monochromeAccentColor() -> Color {
        Color.primary
    }

    public static func monochromePrimaryColor() -> Color {
        Color.primary
    }

    public static func monochromeSecondaryColor() -> Color {
        Color.secondary
    }

    public static func widgetBackgroundColor(
        for colorScheme: ColorScheme,
        renderingMode: RenderingMode
    ) -> Color {
        renderingMode.isMonochrome ? .clear : surfaceMutedColor(for: colorScheme)
    }

    public static func primaryTextColor(
        for colorScheme: ColorScheme,
        renderingMode: RenderingMode
    ) -> Color {
        renderingMode.isMonochrome ? monochromePrimaryColor() : textPrimaryColor(for: colorScheme)
    }

    public static func secondaryTextColor(
        for colorScheme: ColorScheme,
        renderingMode: RenderingMode
    ) -> Color {
        renderingMode.isMonochrome ? monochromeSecondaryColor() : Color("text-secondary")
    }

    public static func monochromePastDotColor() -> Color {
        monochromePrimaryColor().opacity(0.55)
    }

    public static func monochromeFutureDotColor() -> Color {
        monochromeSecondaryColor().opacity(0.22)
    }

    public static func separatorTopColor(renderingMode: RenderingMode) -> Color {
        renderingMode.isMonochrome ? monochromeSecondaryColor().opacity(0.28) : Color("devider-top")
    }

    public static func separatorBottomColor(renderingMode: RenderingMode) -> Color {
        renderingMode.isMonochrome ? monochromeSecondaryColor().opacity(0.12) : Color("devider-bottom")
    }

    public static func surfaceMutedColor(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0x18 / 255.0, green: 0x18 / 255.0, blue: 0x1B / 255.0)
        default:
            return Color(red: 0xE4 / 255.0, green: 0xE4 / 255.0, blue: 0xE7 / 255.0)
        }
    }

    public static func textPrimaryColor(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0xFA / 255.0, green: 0xFA / 255.0, blue: 0xFA / 255.0)
        default:
            return Color(red: 0x09 / 255.0, green: 0x09 / 255.0, blue: 0x0B / 255.0)
        }
    }

    private static func rgba(from color: Color) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        #if canImport(UIKit)
            let uiColor = UIColor(color)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
            return (red, green, blue, alpha)
        #elseif canImport(AppKit)
            let nsColor = NSColor(color)
            guard let sRGB = nsColor.usingColorSpace(.sRGB) else { return nil }
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            sRGB.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return (red, green, blue, alpha)
        #else
            return nil
        #endif
    }
}

public struct WidgetGridDot: View {
    public let color: Color
    public let dotSize: CGFloat
    public let accentable: Bool

    public init(color: Color, dotSize: CGFloat, accentable: Bool = false) {
        self.color = color
        self.dotSize = dotSize
        self.accentable = accentable
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: dotSize, height: dotSize)
            .widgetAccentable(accentable)
    }
}

public struct WidgetSeparator: View {
    public let renderingMode: WidgetStyle.RenderingMode

    public init(renderingMode: WidgetStyle.RenderingMode = .fullColor) {
        self.renderingMode = renderingMode
    }

    public var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(WidgetStyle.separatorTopColor(renderingMode: renderingMode))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
            Rectangle()
                .fill(WidgetStyle.separatorBottomColor(renderingMode: renderingMode))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
        .widgetAccentable(false)
    }
}
