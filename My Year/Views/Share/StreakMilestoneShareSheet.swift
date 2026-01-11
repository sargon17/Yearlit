import Photos
import SharedModels
import SwiftUI
import UIKit

struct StreakMilestoneShareSheet: View {
  let calendar: CustomCalendar
  let milestone: Int
  let currentStreak: Int
  let dates: [Date]

  @Environment(\.colorScheme) private var colorScheme
  @State private var shareImage: UIImage?
  @State private var isSharing: Bool = false
  @State private var showingSaveAlert: Bool = false
  @State private var saveAlertMessage: String = ""

  private let sharePointSize = CGSize(width: 360, height: 450)
  private let shareScale: CGFloat = 3

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        CustomSeparator()
          .padding(.horizontal, -16)

        Spacer(minLength: 12)

        cardView
          .frame(maxWidth: .infinity)

        Spacer(minLength: 12)

        actionButtons
          .padding(.bottom, 24)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
      .navigationTitle("Streak Milestone")
      .navigationBarTitleDisplayMode(.large)
    }
    .presentationDetents([.medium, .large])
    .sheet(isPresented: $isSharing) {
      if let image = shareImage {
        ActivityView(
          activityItems: [image, shareMessage],
          applicationActivities: nil
        )
      }
    }
    .alert("Save Image", isPresented: $showingSaveAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(saveAlertMessage)
    }
  }

  private var cardView: some View {
    StreakMilestoneCardView(
      calendar: calendar,
      milestone: milestone,
      currentStreak: currentStreak,
      dates: dates
    )
    .aspectRatio(4 / 5, contentMode: .fit)
    .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
    .padding(.horizontal, 32)
    .padding(.vertical, 16)
  }

  private var actionButtons: some View {
    HStack {
      HStack(spacing: 2) {
        Button(action: shareMilestone) {
          HStack(spacing: 8) {
            Image(systemName: "square.and.arrow.up")
            Text("Share")
          }
          .font(.system(size: 14, design: .monospaced))
          .foregroundColor(.textPrimary)
          .padding(.vertical, 10)
          .frame(maxWidth: .infinity)
        }
        .sameLevelBorder()
        .foregroundStyle(.textSecondary)

        Button(action: saveToPhotos) {
          HStack(spacing: 8) {
            Image(systemName: "square.and.arrow.down")
            Text("Save to Photos")
          }
          .font(.system(size: 14, design: .monospaced))
          .foregroundColor(.textPrimary)
          .padding(.vertical, 10)
          .frame(maxWidth: .infinity)
        }
        .sameLevelBorder()
        .foregroundStyle(.textSecondary)
      }
      .padding(2)
      .background(getVoidColor(colorScheme: colorScheme))
    }
    .padding(.horizontal)
  }

  private var shareMessage: String {
    let calendarName = calendar.name.capitalized
    return "I just hit a \(milestone)-day streak on \(calendarName)!\n\ntracked using yearlit by @tymofyeyev "
  }

  private func shareMilestone() {
    Task { @MainActor in
      guard let image = renderImage() else { return }
      shareImage = image
      isSharing = true
    }
  }

  private func saveToPhotos() {
    Task { @MainActor in
      guard let image = renderImage() else {
        saveAlertMessage = "Could not render the image."
        showingSaveAlert = true
        return
      }
      let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
      guard status == .authorized || status == .limited else {
        saveAlertMessage = "Photo access denied. Enable Photos permissions in Settings."
        showingSaveAlert = true
        return
      }
      PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAsset(from: image)
      }) { success, error in
        DispatchQueue.main.async {
          if success {
            saveAlertMessage = "Saved to Photos."
          } else {
            saveAlertMessage = error?.localizedDescription ?? "Save failed."
          }
          showingSaveAlert = true
        }
      }
    }
  }

  @MainActor
  private func renderImage() -> UIImage? {
    let view = StreakMilestoneCardView(
      calendar: calendar,
      milestone: milestone,
      currentStreak: currentStreak,
      dates: dates
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
