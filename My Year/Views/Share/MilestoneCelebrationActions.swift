import SharedModels
import SwiftUI
import UIKit

extension MilestoneCelebrationSheet {
    var shareMessage: String {
        let calendarName = calendar.name.capitalized
        let unit = calendar.cadence == .weekly ? String(localized: "weeks") : String(localized: "days")
        let signature = "\n\ntracked using yearlit by @tymofyeyev "
        switch kind {
        case .streak:
            let message = String(localized: "I just hit \(milestone) \(unit) in a row on \(calendarName)!")
            return message + signature
        case .showedUp:
            return String(localized: "I just showed up \(milestone) \(unit) on \(calendarName)!") + signature
        case .showedUpMonth:
            let message = String(localized: "I showed up \(milestone) \(unit) this month on \(calendarName)!")
            return message + signature
        case .showedUpYear:
            let message = String(localized: "I showed up \(milestone) \(unit) this year on \(calendarName)!")
            return message + signature
        }
    }

    func shareMilestone() {
        Task { @MainActor in
            guard let image = renderImage() else { return }
            shareImage = image
            isSharing = true
        }
    }

    func saveToPhotos() {
        Task { @MainActor in
            guard let image = renderImage() else {
                showSaveAlert(String(localized: "Could not render the image."))
                return
            }
            let result = await SharePhotoSaver.save(image)
            showSaveAlert(result.alertMessage)
        }
    }

    func stopShowingThisKind() {
        dismiss()
        stopAction.stopShowing(
            kind: kind,
            calendarId: calendar.id,
            milestone: milestone,
            showedUpPeriodKey: showedUpPeriodKey
        )
    }

    func showSaveAlert(_ message: String) {
        saveAlertMessage = message
        showingSaveAlert = true
    }

    @MainActor
    func renderImage() -> UIImage? {
        let view = StreakMilestoneCardView(
            calendar: calendar,
            milestone: milestone,
            currentStreak: currentStreak,
            dates: dates,
            kind: kind
        )
        .aspectRatio(4 / 5, contentMode: .fill)
        .clipped()
        return ShareImageRenderer.render(
            view: view,
            size: sharePointSize,
            colorScheme: colorScheme,
            scale: shareScale
        )
    }
}
