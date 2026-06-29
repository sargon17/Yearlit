import Photos
import UIKit

enum SharePhotoSaveResult: Equatable {
  case saved
  case failed(String)

  var alertMessage: String {
    switch self {
    case .saved:
      return String(localized: "Saved to Photos.")
    case .failed(let message):
      return message
    }
  }
}

enum SharePhotoSaver {
  static func save(_ image: UIImage) async -> SharePhotoSaveResult {
    guard let imageURL = ShareImageRenderer.writeTemporaryJPEG(from: image) else {
      return .failed(String(localized: "Save failed."))
    }

    let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    guard status == .authorized || status == .limited else {
      try? FileManager.default.removeItem(at: imageURL)
      return .failed(String(localized: "Photo access denied. Enable Photos permissions in Settings."))
    }

    return await saveImage(at: imageURL)
  }

  private static func saveImage(at imageURL: URL) async -> SharePhotoSaveResult {
    await withCheckedContinuation { continuation in
      PHPhotoLibrary.shared().performChanges(
        {
          PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: imageURL)
        },
        completionHandler: { success, error in
          try? FileManager.default.removeItem(at: imageURL)

          if success {
            continuation.resume(returning: .saved)
          } else {
            continuation.resume(
              returning: .failed(error?.localizedDescription ?? String(localized: "Save failed."))
            )
          }
        }
      )
    }
  }
}
