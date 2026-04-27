import Garnish
import SwiftUI

public extension Color {
    static var brand: Color {
        return Color.qsOrange
    }

    static var brandInverted: Color {
        return safeContrastingShade(of: Color.qsOrange)
    }

    static var brandSecondary: Color {
        return GarnishColor.blend(.qsOrange, with: .surfaceMuted, ratio: 0.2)
    }

    static var brandSecondaryInverted: Color {
        return safeContrastingShade(of: Color.brandSecondary)
    }

    static var buttonBackground: Color {
        return GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.05)
    }

    init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        let scanner = Scanner(string: hexString)
        var value: UInt64 = 0
        guard scanner.scanHexInt64(&value) else { return nil }

        let r, g, b, a: UInt64
        switch hexString.count {
        case 6:
            (r, g, b, a) = (value >> 16, (value >> 8) & 0xFF, value & 0xFF, 0xFF)
        case 8:
            (r, g, b, a) = (value >> 24, (value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }

    func safeContrastingShade(fallback: Color = .white) -> Color {
        (try? contrastingShade()) ?? fallback
    }

    static func safeContrastingShade(of color: Color, fallback: Color = .white) -> Color {
        (try? Garnish.contrastingShade(of: color)) ?? fallback
    }

    static var buttonForeground: Color {
        return safeContrastingShade(of: Color.buttonBackground)
    }
}
