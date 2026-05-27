import Testing
import UIKit

@testable import My_Year

@MainActor
struct DailyWallpaperRendererTests {
  private let pixelSize = CGSize(width: 430, height: 932)
  private let screenScale: CGFloat = 1
  private let referenceDate = Date(timeIntervalSince1970: 1_779_840_000)

  @Test func deterministicRenderPathUsesExpectedSizeAndReferenceDate() throws {
    let settings = wallpaperSettings(template: .classic, theme: .dark)
    let firstImage = try render(settings: settings, referenceDate: referenceDate)
    let secondImage = try render(settings: settings, referenceDate: referenceDate)
    let laterImage = try render(
      settings: settings,
      referenceDate: referenceDate.addingTimeInterval(60 * 60 * 24 * 90)
    )

    assertSize(firstImage)
    #expect(bitmapData(from: firstImage) == bitmapData(from: secondImage))
    #expect(fingerprint(of: firstImage) != fingerprint(of: laterImage))
  }

  @Test func renderProducesContentForEachTemplateAndTheme() throws {
    for template in DailyWallpaperTemplate.allCases {
      for theme in DailyWallpaperTheme.allCases {
        let settings = wallpaperSettings(template: template, theme: theme)
        let image = try render(settings: settings, referenceDate: referenceDate)
        let bitmap = try PixelBitmap(image: image)
        let palette = DailyWallpaperPalette(theme: theme, accentColorName: settings.accentColorName)

        assertSize(image)
        #expect(bitmap.color(atX: 4, y: 4).isClose(to: palette.background))
        #expect(bitmap.countPixels(differentFrom: palette.background, minimumDistance: 12) > 800)
        #expect(bitmap.countPixels(closeTo: palette.accent, maximumDistance: 48) > 20)
      }
    }
  }

  @Test func templateDispatchProducesDistinctLayouts() throws {
    let fingerprints = try DailyWallpaperTemplate.allCases.map { template in
      let image = try render(
        settings: wallpaperSettings(template: template, theme: .dark), referenceDate: referenceDate)
      return fingerprint(of: image)
    }

    #expect(Set(fingerprints).count == DailyWallpaperTemplate.allCases.count)
  }

  private func wallpaperSettings(
    template: DailyWallpaperTemplate,
    theme: DailyWallpaperTheme
  ) -> DailyWallpaperSettings {
    DailyWallpaperSettings(
      template: template,
      theme: theme,
      accentColorName: "qs-orange",
      message: "One honest day at a time"
    )
  }

  private func render(settings: DailyWallpaperSettings, referenceDate: Date) throws -> UIImage {
    try #require(
      DailyWallpaperRenderer.render(
        pixelSize: pixelSize,
        screenScale: screenScale,
        settings: settings,
        referenceDate: referenceDate
      ))
  }

  private func assertSize(_ image: UIImage) {
    #expect(image.size == pixelSize)
    #expect(image.scale == 1)
    #expect(image.cgImage?.width == Int(pixelSize.width))
    #expect(image.cgImage?.height == Int(pixelSize.height))
  }

  private func fingerprint(of image: UIImage) throws -> UInt64 {
    let bitmap = try PixelBitmap(image: image)
    var hash: UInt64 = 14_695_981_039_346_656_037

    for y in stride(from: 0, to: bitmap.height, by: 29) {
      for x in stride(from: 0, to: bitmap.width, by: 31) {
        let color = bitmap.color(atX: x, y: y)
        hash ^= UInt64(color.red)
        hash &*= 1_099_511_628_211
        hash ^= UInt64(color.green)
        hash &*= 1_099_511_628_211
        hash ^= UInt64(color.blue)
        hash &*= 1_099_511_628_211
      }
    }

    return hash
  }

  private func bitmapData(from image: UIImage) throws -> [UInt8] {
    try PixelBitmap(image: image).pixels
  }
}

private struct PixelBitmap {
  let width: Int
  let height: Int
  let pixels: [UInt8]

  init(image: UIImage) throws {
    let cgImage = try #require(image.cgImage)
    width = cgImage.width
    height = cgImage.height
    var pixels = [UInt8](repeating: 0, count: width * height * 4)

    let context = try #require(
      CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      ))
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    self.pixels = pixels
  }

  func color(atX x: Int, y: Int) -> PixelColor {
    let clampedX = max(0, min(width - 1, x))
    let clampedY = max(0, min(height - 1, y))
    let index = ((clampedY * width) + clampedX) * 4
    return PixelColor(
      red: pixels[index],
      green: pixels[index + 1],
      blue: pixels[index + 2],
      alpha: pixels[index + 3]
    )
  }

  func countPixels(closeTo color: UIColor, maximumDistance: Double) -> Int {
    let target = PixelColor(color)
    return countPixels { $0.distance(to: target) <= maximumDistance }
  }

  func countPixels(differentFrom color: UIColor, minimumDistance: Double) -> Int {
    let target = PixelColor(color)
    return countPixels { $0.distance(to: target) >= minimumDistance }
  }

  private func countPixels(matching predicate: (PixelColor) -> Bool) -> Int {
    var count = 0

    for index in stride(from: 0, to: pixels.count, by: 4) {
      let color = PixelColor(
        red: pixels[index],
        green: pixels[index + 1],
        blue: pixels[index + 2],
        alpha: pixels[index + 3]
      )
      if predicate(color) {
        count += 1
      }
    }

    return count
  }
}

private struct PixelColor {
  let red: UInt8
  let green: UInt8
  let blue: UInt8
  let alpha: UInt8

  init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
    self.red = red
    self.green = green
    self.blue = blue
    self.alpha = alpha
  }

  init(_ color: UIColor) {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

    self.init(
      red: UInt8(red * 255),
      green: UInt8(green * 255),
      blue: UInt8(blue * 255),
      alpha: UInt8(alpha * 255)
    )
  }

  func isClose(to color: UIColor, maximumDistance: Double = 3) -> Bool {
    distance(to: PixelColor(color)) <= maximumDistance
  }

  func distance(to other: PixelColor) -> Double {
    let redDistance = Double(Int(red) - Int(other.red))
    let greenDistance = Double(Int(green) - Int(other.green))
    let blueDistance = Double(Int(blue) - Int(other.blue))
    return sqrt((redDistance * redDistance) + (greenDistance * greenDistance) + (blueDistance * blueDistance))
  }
}
