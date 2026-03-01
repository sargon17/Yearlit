import CoreMotion
import Photos
import SharedModels
import SwiftUI
import UIKit

struct StreakMilestoneShareSheet: View {
    let calendar: CustomCalendar
    let milestone: Int
    let currentStreak: Int
    let kind: MilestoneKind
    let dates: [Date]

    @Environment(\.colorScheme) private var colorScheme
    @State private var shareImage: UIImage?
    @State private var isSharing: Bool = false
    @State private var showingSaveAlert: Bool = false
    @State private var saveAlertMessage: String = ""
    @State private var isCardVisible: Bool = false
    @StateObject private var motion = MotionTiltManager()

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
            .navigationTitle("Milestone")
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
        switch kind {
        case .streak:
            return "I just hit \(milestone) days in a row on \(calendarName)!\n\ntracked using yearlit by @tymofyeyev "
        case .showedUp:
            return "I just showed up \(milestone) days on \(calendarName)!\n\ntracked using yearlit by @tymofyeyev "
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
