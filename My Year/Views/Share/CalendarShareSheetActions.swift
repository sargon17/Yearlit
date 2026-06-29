import SharedModels
import SwiftUI
import UIKit

extension CalendarShareSheet {
  var shareMessage: String {
    let calendarName = calendar.name.capitalized
    let period = calendar.cadence == .weekly ? String(localized: "weekly") : String(localized: "daily")
    let signature = "\n\ntracked using yearlit by @tymofyeyev "
    if selectedTemplate == .your365 {
      return String(localized: "Here's my Your 365 progress for \(calendarName)!") + signature
    }
    return String(localized: "Here's my \(period) \(calendarName) progress!") + signature
  }

  var isLockedTemplate: Bool {
    effectiveTemplate.isPremiumOnly && !isPremium
  }

  func shareSelectedTemplate() {
    Task { @MainActor in
      if isLockedTemplate {
        showSaveAlert(String(localized: "Premium card. Upgrade to share this template."))
        return
      }
      guard let image = renderImage() else { return }
      shareImage = image
      isSharing = true
    }
  }

  func saveToPhotos() {
    Task { @MainActor in
      if isLockedTemplate {
        showSaveAlert(String(localized: "Premium card. Upgrade to save this template."))
        return
      }
      guard let image = renderImage() else {
        showSaveAlert(String(localized: "Could not render the image."))
        return
      }
      let result = await SharePhotoSaver.save(image)
      showSaveAlert(result.alertMessage)
    }
  }

  @MainActor
  func renderImage() -> UIImage? {
    let view = cardView(for: effectiveTemplate)
      .aspectRatio(4 / 5, contentMode: .fill)
      .clipped()
    return ShareImageRenderer.render(
      view: view,
      size: sharePointSize,
      colorScheme: colorScheme,
      scale: shareScale
    )
  }

  func showSaveAlert(_ message: String) {
    saveAlertMessage = message
    showingSaveAlert = true
  }
}
