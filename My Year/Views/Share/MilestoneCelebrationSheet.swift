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

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State var shareImage: UIImage?
    @State var isSharing: Bool = false
    @State var showingSaveAlert: Bool = false
    @State var saveAlertMessage: String = ""
    @State var isCardVisible: Bool = false
    @State var didTrackShareSheetViewed: Bool = false
    @StateObject var motion = MotionTiltManager()

    let stopAction = MilestoneCelebrationStopAction()
    let sharePointSize = CGSize(width: 360, height: 450)
    let shareScale: CGFloat = 3
    let previewHorizontalPadding: CGFloat = 32
    let previewVerticalPadding: CGFloat = 16

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

    var cardView: some View {
        GeometryReader { proxy in
            let cardSize = previewCardSize(for: proxy.size)

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
            .frame(width: cardSize.width, height: cardSize.height)
            .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
            .rotation3DEffect(.degrees(motion.pitch), axis: (x: 1, y: 0, z: 0), perspective: 0.8)
            .rotation3DEffect(.degrees(motion.roll), axis: (x: 0, y: 1, z: 0), perspective: 0.8)
            .scaleEffect(isCardVisible ? 1 : 0.88)
            .opacity(isCardVisible ? 1 : 0)
            .offset(y: isCardVisible ? 0 : 28)
            .blur(radius: isCardVisible ? 0 : 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: sharePointSize.height)
        .padding(.horizontal, previewHorizontalPadding)
        .padding(.vertical, previewVerticalPadding)
    }

    func previewCardSize(for availableSize: CGSize) -> CGSize {
        let availableWidth = max(0, availableSize.width)
        let cardWidth = min(sharePointSize.width, availableWidth)
        return CGSize(
            width: cardWidth,
            height: cardWidth * sharePointSize.height / sharePointSize.width
        )
    }

    @ViewBuilder
    var actionButtons: some View {
        VStack(spacing: 12) {
            ShareActionButtonGroup(
                onShare: shareMilestone,
                onSave: saveToPhotos
            )
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

}
