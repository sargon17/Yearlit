import CoreMotion
import Photos
import SharedModels
import SwiftUI
import UIKit

struct MilestoneCelebrationSheet: View {
    let calendar: CustomCalendar
    let milestone: Int
    let currentStreak: Int
    let kind: MilestoneKind
    let dates: [Date]
    let allowsStopShowing: Bool
    let showedUpPeriodKey: String?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?
    @State private var isSharing: Bool = false
    @State private var showingSaveAlert: Bool = false
    @State private var saveAlertMessage: String = ""
    @State private var isCardVisible: Bool = false
    @State private var didTrackShareSheetViewed: Bool = false
    @StateObject private var motion = MotionTiltManager()

    private let stopAction = MilestoneCelebrationStopAction()
    private let sharePointSize = CGSize(width: 360, height: 450)
    private let shareScale: CGFloat = 3

    init(
        calendar: CustomCalendar,
        milestone: Int,
        currentStreak: Int,
        kind: MilestoneKind,
        dates: [Date],
        allowsStopShowing: Bool = true,
        showedUpPeriodKey: String?
    ) {
        self.calendar = calendar
        self.milestone = milestone
        self.currentStreak = currentStreak
        self.kind = kind
        self.dates = dates
        self.allowsStopShowing = allowsStopShowing
        self.showedUpPeriodKey = showedUpPeriodKey
    }

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
            .navigationTitle("Milestone celebration")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            isCardVisible = false
            motion.start()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.72)) {
                    isCardVisible = true
                }
            }
        }
        .onDisappear {
            isCardVisible = false
            motion.stop()
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $isSharing) {
            if let image = shareImage {
                ActivityView(
                    activityItems: [image, shareMessage],
                    applicationActivities: nil
                )
                .onAppear {
                    guard !didTrackShareSheetViewed else { return }
                    didTrackShareSheetViewed = true
                    Analytics.shared.trackShareSheetViewed(type: .recap)
                }
                .onDisappear {
                    didTrackShareSheetViewed = false
                }
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
            dates: dates,
            kind: kind,
            glareOffset: CGSize(
                width: motion.roll * 3,
                height: -motion.pitch * 3
            )
        )
        .aspectRatio(4 / 5, contentMode: .fit)
        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
        .rotation3DEffect(.degrees(motion.pitch), axis: (x: 1, y: 0, z: 0), perspective: 0.8)
        .rotation3DEffect(.degrees(motion.roll), axis: (x: 0, y: 1, z: 0), perspective: 0.8)
        .scaleEffect(isCardVisible ? 1 : 0.88)
        .opacity(isCardVisible ? 1 : 0)
        .offset(y: isCardVisible ? 0 : 28)
        .blur(radius: isCardVisible ? 0 : 10)
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 2) {
                    Button(action: shareMilestone) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(AppFont.mono(14))
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
                        .font(AppFont.mono(14))
                        .foregroundColor(.textPrimary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                    }
                    .sameLevelBorder()
                    .foregroundStyle(.textSecondary)
                }
                .padding(2)
                .sameLevelGroupBackground()
            }
            .padding(.horizontal)

            if allowsStopShowing {
                Button(role: .destructive, action: stopShowingThisKind) {
                    Text("Stop showing this kind")
                        .font(AppFont.mono(14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var shareMessage: String {
        let calendarName = calendar.name.capitalized
        let unit = calendar.cadence == .weekly ? String(localized: "weeks") : String(localized: "days")
        let signature = "\n\ntracked using yearlit by @tymofyeyev "
        switch kind {
        case .streak:
            return String(localized: "I just hit \(milestone) \(unit) in a row on \(calendarName)!") + signature
        case .showedUp:
            return String(localized: "I just showed up \(milestone) \(unit) on \(calendarName)!") + signature
        case .showedUpMonth:
            return String(localized: "I showed up \(milestone) \(unit) this month on \(calendarName)!") + signature
        case .showedUpYear:
            return String(localized: "I showed up \(milestone) \(unit) this year on \(calendarName)!") + signature
        }
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
                saveAlertMessage = String(localized: "Could not render the image.")
                showingSaveAlert = true
                return
            }
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                saveAlertMessage = String(localized: "Photo access denied. Enable Photos permissions in Settings.")
                showingSaveAlert = true
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        saveAlertMessage = String(localized: "Saved to Photos.")
                    } else {
                        saveAlertMessage = error?.localizedDescription ?? String(localized: "Save failed.")
                    }
                    showingSaveAlert = true
                }
            }
        }
    }

    private func stopShowingThisKind() {
        dismiss()
        stopAction.stopShowing(
            kind: kind,
            calendarId: calendar.id,
            milestone: milestone,
            showedUpPeriodKey: showedUpPeriodKey
        )
    }

    @MainActor
    private func renderImage() -> UIImage? {
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

private final class MotionTiltManager: ObservableObject {
    @Published var pitch: Double = 0
    @Published var roll: Double = 0

    private let manager = CMMotionManager()
    private let maxAngle: Double = 6
    private let smoothing: Double = 0.12
    private var referenceGravity: CMAcceleration?

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1 / 60
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let gravity = motion.gravity
            if referenceGravity == nil {
                referenceGravity = gravity
            }
            let ref = referenceGravity ?? gravity
            let dx = gravity.x - ref.x
            let dy = gravity.y - ref.y
            let targetRoll = clamp(dx * maxAngle * 1.4, maxAngle: maxAngle)
            let targetPitch = clamp(-dy * maxAngle * 1.4, maxAngle: maxAngle)
            pitch = lerp(from: pitch, to: targetPitch, t: smoothing)
            roll = lerp(from: roll, to: targetRoll, t: smoothing)
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        referenceGravity = nil
    }

    private func clamp(_ value: Double, maxAngle: Double) -> Double {
        min(maxAngle, max(-maxAngle, value))
    }

    private func lerp(from: Double, to: Double, t: Double) -> Double {
        from + (to - from) * t
    }
}
