import AppIntents
import Foundation
import UniformTypeIdentifiers

struct CreateDailyWallpaperIntent: AppIntent {
  static var title: LocalizedStringResource = "Create Daily Wallpaper"
  static var description = IntentDescription("Creates a Yearlit year progress wallpaper for Shortcuts.")
  static var openAppWhenRun = false

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> & ProvidesDialog {
    guard let data = DailyWallpaperRenderer.render()?.pngData() else {
      throw DailyWallpaperError.renderFailed
    }

    let file = DailyWallpaperFileWriter.makeFile(data)

    return .result(
      value: file,
      dialog: "Daily Wallpaper created."
    )
  }
}

enum DailyWallpaperError: Error, CustomLocalizedStringResourceConvertible {
  case renderFailed

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .renderFailed:
      return "Yearlit could not generate the daily wallpaper."
    }
  }
}

private enum DailyWallpaperFileWriter {
  static func makeFile(_ data: Data) -> IntentFile {
    let filename = "yearlit-daily-wallpaper-\(Self.timestamp()).png"
    return IntentFile(data: data, filename: filename, type: .png)
  }

  private static func timestamp() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    return formatter.string(from: Date())
  }
}
