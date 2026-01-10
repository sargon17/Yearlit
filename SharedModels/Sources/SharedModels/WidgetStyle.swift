import SwiftUI

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

public enum WidgetStyle {
  public static func adjustedColumns(for count: Int, aspectRatio: CGFloat) -> Int {
    let targetColumns = max(1, Int(sqrt(Double(count) * aspectRatio)))
    var columns = max(1, min(targetColumns, count))
    while columns > 1 && count % columns == 1 {
      columns -= 1
    }
    return columns
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

  private static func rgba(from color: Color) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)?
  {
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

  public init(color: Color, dotSize: CGFloat) {
    self.color = color
    self.dotSize = dotSize
  }

  public var body: some View {
    RoundedRectangle(cornerRadius: 3)
      .fill(color)
      .frame(width: dotSize, height: dotSize)
      .widgetAccentable(false)
  }
}

public struct WidgetSeparator: View {
  public init() {}

  public var body: some View {
    VStack(spacing: 0) {
      Rectangle()
        .fill(Color("devider-top"))
        .frame(height: 1)
        .frame(maxWidth: .infinity)
      Rectangle()
        .fill(Color("devider-bottom"))
        .frame(height: 1)
        .frame(maxWidth: .infinity)
    }
  }
}
