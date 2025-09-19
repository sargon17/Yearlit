import Garnish
import SwiftUI

extension Color {
  public static var brand: Color {
    return Color.qsOrange
  }

  public static var brandInverted: Color {
    return try! Garnish.contrastingShade(of: Color.qsOrange)
  }

  public static var brandSecondary: Color {
    return try! GarnishColor.blend(.qsOrange, with: .surfaceMuted, ratio: 0.2)
  }

  public static var brandSecondaryInverted: Color {
    return try! Garnish.contrastingShade(of: Color.brandSecondary)
  }

  public static var buttonBackground: Color {
    return try! GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.05)
  }

  public static var buttonForeground: Color {
    return try! Garnish.contrastingShade(of: Color.buttonBackground)
  }

}
