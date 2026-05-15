import CoreText
import SwiftUI
#if canImport(UIKit)
  import UIKit
#endif

public enum AppFont {
  public enum Family {
    case sans
    case mono
    case pixelCircle
  }

  public static func registerFonts() {
    fontFiles.forEach(registerFont)
  }

  public static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    custom(.sans, size: size, weight: weight)
  }

  public static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    custom(.mono, size: size, weight: weight)
  }

  public static func pixelCircle(_ size: CGFloat) -> Font {
    custom(.pixelCircle, size: size, weight: .regular)
  }

  public static func custom(_ family: Family, size: CGFloat, weight: Font.Weight = .regular) -> Font {
    Font.custom(postScriptName(for: family, weight: weight), size: size)
  }

  #if canImport(UIKit)
    public static func uiFont(_ family: Family, size: CGFloat, weight: Font.Weight = .regular) -> UIFont {
      UIFont(name: postScriptName(for: family, weight: weight), size: size) ?? .systemFont(ofSize: size)
    }
  #endif

  private static let fontFiles = [
    "Geist-Thin.ttf",
    "Geist-UltraLight.ttf",
    "Geist-Light.ttf",
    "Geist-Regular.ttf",
    "Geist-Medium.ttf",
    "Geist-SemiBold.ttf",
    "Geist-Bold.ttf",
    "Geist-Black.ttf",
    "Geist-UltraBlack.ttf",
    "GeistMono-Thin.ttf",
    "GeistMono-UltraLight.ttf",
    "GeistMono-Light.ttf",
    "GeistMono-Regular.ttf",
    "GeistMono-Medium.ttf",
    "GeistMono-SemiBold.ttf",
    "GeistMono-Bold.ttf",
    "GeistMono-Black.ttf",
    "GeistMono-UltraBlack.ttf",
    "GeistPixel-Circle.ttf",
  ]

  private static func registerFont(_ filename: String) {
    let name = (filename as NSString).deletingPathExtension
    let ext = (filename as NSString).pathExtension
    let url = Bundle.main.url(forResource: name, withExtension: ext)
      ?? Bundle.main.url(forResource: filename, withExtension: nil, subdirectory: "Fonts")

    guard let url else { return }
    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
  }

  private static func postScriptName(for family: Family, weight: Font.Weight) -> String {
    switch family {
    case .sans:
      return "Geist-\(suffix(for: weight))"
    case .mono:
      return "GeistMono-\(suffix(for: weight))"
    case .pixelCircle:
      return "GeistPixel-Circle"
    }
  }

  private static func suffix(for weight: Font.Weight) -> String {
    switch weight {
    case .ultraLight:
      return "ExtraLight"
    case .thin:
      return "Thin"
    case .light:
      return "Light"
    case .medium:
      return "Medium"
    case .semibold:
      return "SemiBold"
    case .bold:
      return "Bold"
    case .heavy, .black:
      return "Black"
    default:
      return "Regular"
    }
  }
}
