import Garnish
import SwiftUI

public extension Color {
    static var brand: Color {
        return Color.qsOrange
    }

    static var brandInverted: Color {
        return try! Garnish.contrastingShade(of: Color.qsOrange)
    }

    static var brandSecondary: Color {
        return try! GarnishColor.blend(.qsOrange, with: .surfaceMuted, ratio: 0.2)
    }

    static var brandSecondaryInverted: Color {
        return try! Garnish.contrastingShade(of: Color.brandSecondary)
    }

    static var buttonBackground: Color {
        return try! GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.05)
    }

    static var buttonForeground: Color {
        return try! Garnish.contrastingShade(of: Color.buttonBackground)
    }
}
