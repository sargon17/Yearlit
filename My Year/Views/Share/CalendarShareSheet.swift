import RevenueCatUI
import SharedModels
import SwiftUI
import UIKit

struct CalendarShareSheet: View {
    let calendar: CustomCalendar
    let year: Int
    let dates: [Date]
    let statsBundle: StatsBundle?
    let isPremium: Bool

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State var selectedTemplate: CalendarShareTemplate = .yearCard
    @State var shareImage: UIImage?
    @State var isSharing: Bool = false
    @State var isPaywallPresented: Bool = false
    @State var showingSaveAlert: Bool = false
    @State var saveAlertMessage: String = ""
    @State var didTrackShareSheetViewed: Bool = false

    let sharePointSize = CGSize(width: 360, height: 450)
    let shareScale: CGFloat = 3
    let previewHorizontalPadding: CGFloat = 32
    let previewVerticalPadding: CGFloat = 16

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CustomSeparator()
                    .padding(.horizontal, -16)

                Spacer(minLength: 12)

                cardPager
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 12)

                actionButtons
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
            .navigationTitle(effectiveTemplate.title)
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                selectedTemplate = effectiveTemplate
            }
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
                    Analytics.shared.trackShareSheetViewed(type: .calendar)
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
        .sheet(isPresented: $isPaywallPresented) {
            PremiumPaywallSheet(trigger: .shareGate)
        }
    }

    var cardPager: some View {
        GeometryReader { proxy in
            let cardSize = previewCardSize(for: proxy.size)

            TabView(selection: $selectedTemplate) {
                ForEach(availableShareTemplates(for: calendar, today: Date())) { template in
                    cardView(for: template)
                        .frame(width: cardSize.width, height: cardSize.height)
                        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tag(template)
                        .onTapGesture {
                            guard template.isPremiumOnly, !isPremium else { return }
                            isPaywallPresented = true
                        }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
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

    var actionButtons: some View {
        ShareActionButtonGroup(
            onShare: shareSelectedTemplate,
            onSave: saveToPhotos
        )
        .padding(.horizontal)
    }

    var effectiveTemplate: CalendarShareTemplate {
        let templates = availableShareTemplates(for: calendar, today: Date())
        return templates.contains(selectedTemplate) ? selectedTemplate : .yearCard
    }
}
