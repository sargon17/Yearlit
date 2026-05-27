import Testing
import UIKit

@testable import My_Year

@MainActor
struct DailyWallpaperRendererTests {
  @Test func renderProducesVisibleWallpaperPixels() throws {
    let image = try #require(DailyWallpaperRenderer.render())
    let cgImage = try #require(image.cgImage)

    #expect(image.size.width > 0)
    #expect(image.size.height > 0)
    #expect(countBrightPixels(in: cgImage) > 1_000)
  }

  @Test func renderProducesVisibleWallpaperPixelsForEachTemplateAndTheme() throws {
    for template in DailyWallpaperTemplate.allCases {
      for theme in DailyWallpaperTheme.allCases {
        let image = try #require(
          DailyWallpaperRenderer.render(
            settings: DailyWallpaperSettings(
              template: template,
              theme: theme,
              accentColorName: "qs-emerald",
              message: "One honest day at a time"
            )))
        let cgImage = try #require(image.cgImage)

        #expect(image.size.width > 0)
        #expect(image.size.height > 0)
        #expect(countBrightPixels(in: cgImage) > 1_000)
      }
    }
  }

  private func countBrightPixels(in image: CGImage) -> Int {
    let width = image.width
    let height = image.height
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    guard
      let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else {
      return 0
    }

    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

    var count = 0
    for index in stride(from: 0, to: pixels.count, by: 4) {
      let red = pixels[index]
      let green = pixels[index + 1]
      let blue = pixels[index + 2]
      if max(red, green, blue) > 80 {
        count += 1
      }
    }
    return count
  }
}
