import Photos
import RevenueCatUI
import SharedModels
import SwiftUI
import UIKit

enum CalendarShareTemplate: String, CaseIterable, Identifiable {
    case yearCard
    case minimalGrid
    case streakFocus
    case performance
    case your365

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .yearCard:
            return String(localized: "Year Card")
        case .minimalGrid:
            return String(localized: "Minimal Grid")
        case .streakFocus:
            return String(localized: "Streak Focus")
        case .performance:
            return String(localized: "Performance")
        case .your365:
            return String(localized: "Your 365")
        }
    }

    var subtitle: String {
        switch self {
        case .yearCard:
            return String(localized: "Full-year grid + stats")
        case .minimalGrid:
            return String(localized: "Clean grid only")
        case .streakFocus:
            return String(localized: "Streaks + grid strip")
        case .performance:
            return String(localized: "Trends and progress")
        case .your365:
            return String(localized: "Personal habit-year card")
        }
    }

    var isPremiumOnly: Bool {
        switch self {
        case .performance:
            return true
        case .yearCard, .minimalGrid, .streakFocus, .your365:
            return false
        }
    }
}

struct CalendarShareSheet: View {
    let calendar: CustomCalendar
    let year: Int
    let dates: [Date]
    let statsBundle: StatsBundle?
    let isPremium: Bool

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: CalendarShareTemplate = .yearCard
    @State private var shareImage: UIImage?
    @State private var isSharing: Bool = false
    @State private var isPaywallPresented: Bool = false
    @State private var showingSaveAlert: Bool = false
    @State private var saveAlertMessage: String = ""
    @State private var didTrackShareSheetViewed: Bool = false
    private var your365Snapshot: Your365Snapshot? {
        guard calendar.cadence == .daily else { return nil }
        return calendar.makeYour365Snapshot(
            completedDates: your365CompletedDates(for: calendar),
            today: Date()
        )
    }

    private let sharePointSize = CGSize(width: 360, height: 450)
    private let shareScale: CGFloat = 3
    private let previewHorizontalPadding: CGFloat = 32
    private let previewVerticalPadding: CGFloat = 16

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

    private var cardPager: some View {
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

    private func previewCardSize(for availableSize: CGSize) -> CGSize {
        let availableWidth = max(0, availableSize.width)
        let cardWidth = min(sharePointSize.width, availableWidth)
        return CGSize(
            width: cardWidth,
            height: cardWidth * sharePointSize.height / sharePointSize.width
        )
    }

    private var actionButtons: some View {
        HStack {
            HStack(spacing: 2) {
                Button(action: shareSelectedTemplate) {
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
    }

    private var resolvedStats: CalendarStats {
        statsBundle?.basic ?? computeFallbackStats(for: calendar)
    }

    private var resolvedCompletionRateTrailingLongWindow: Double {
        statsBundle?.completionRateTrailingLongWindow ?? 0
    }

    private var resolvedAverageProgressTrailingShortWindow: Double {
        statsBundle?.averageProgressTrailingShortWindow ?? 0
    }

    private var resolvedAverageProgressTrailingLongWindow: Double {
        statsBundle?.averageProgressTrailingLongWindow ?? 0
    }

    private var resolvedBestWeekday: Int? {
        statsBundle?.bestWeekday
    }

    private var shareMessage: String {
        let calendarName = calendar.name.capitalized
        let period = calendar.cadence == .weekly ? String(localized: "weekly") : String(localized: "daily")
        if selectedTemplate == .your365 {
            return String(localized: "Here's my Your 365 progress for \(calendarName)!\n\ntracked using yearlit by @tymofyeyev ")
        }
        return String(localized: "Here's my \(period) \(calendarName) progress!\n\ntracked using yearlit by @tymofyeyev ")
    }

    private var effectiveTemplate: CalendarShareTemplate {
        let templates = availableShareTemplates(for: calendar, today: Date())
        return templates.contains(selectedTemplate) ? selectedTemplate : .yearCard
    }

    private var cardData: ShareCardData {
        ShareCardData(
            calendar: calendar,
            year: year,
            dates: dates,
            your365Snapshot: your365Snapshot,
            isYour365FirstYear: calendar.isWithinFirstYear(today: Date()),
            stats: resolvedStats,
            completionRateTrailingLongWindow: resolvedCompletionRateTrailingLongWindow,
            averageProgressTrailingShortWindow: resolvedAverageProgressTrailingShortWindow,
            averageProgressTrailingLongWindow: resolvedAverageProgressTrailingLongWindow,
            bestWeekday: resolvedBestWeekday,
            currentPeriodCount: resolvedCurrentPeriodCount,
            trackingType: calendar.trackingType
        )
    }

    private func shareSelectedTemplate() {
        Task { @MainActor in
            if isLockedTemplate {
                saveAlertMessage = String(localized: "Premium card. Upgrade to share this template.")
                showingSaveAlert = true
                return
            }
            guard let image = renderImage() else { return }
            shareImage = image
            isSharing = true
        }
    }

    private func saveToPhotos() {
        Task { @MainActor in
            if isLockedTemplate {
                saveAlertMessage = String(localized: "Premium card. Upgrade to save this template.")
                showingSaveAlert = true
                return
            }
            guard let image = renderImage() else {
                saveAlertMessage = String(localized: "Could not render the image.")
                showingSaveAlert = true
                return
            }
            guard let imageURL = ShareImageRenderer.writeTemporaryJPEG(from: image) else {
                saveAlertMessage = String(localized: "Save failed.")
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
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: imageURL)
            }) { success, error in
                try? FileManager.default.removeItem(at: imageURL)
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

    @MainActor
    private func renderImage() -> UIImage? {
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

    @ViewBuilder
    private func cardView(for template: CalendarShareTemplate) -> some View {
        let base: AnyView = {
            switch template {
            case .yearCard:
                return AnyView(
                    YearCardShareView(
                        calendar: calendar,
                        year: year,
                        dates: dates,
                        stats: resolvedStats,
                        completionRateTrailingLongWindow: resolvedCompletionRateTrailingLongWindow,
                        currentPeriodCount: resolvedCurrentPeriodCount,
                        trackingType: calendar.trackingType
                    )
                )
            case .minimalGrid:
                return AnyView(MinimalGridShareView(data: cardData))
            case .streakFocus:
                return AnyView(StreakFocusShareView(data: cardData))
            case .performance:
                return AnyView(PerformanceShareView(data: cardData))
            case .your365:
                return AnyView(Your365ShareView(data: cardData))
            }
        }()

        if template.isPremiumOnly && !isPremium {
            base
                .blur(radius: 12)
                .overlay(premiumOverlay)
        } else {
            base
        }
    }

    private var premiumOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.25))
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.textPrimary)
                Text("Premium")
                    .font(AppFont.mono(14))
                    .foregroundColor(.textPrimary)
            }
        }
    }

    private var isLockedTemplate: Bool {
        effectiveTemplate.isPremiumOnly && !isPremium
    }

    private func computeFallbackStats(for calendar: CustomCalendar) -> CalendarStats {
        let activeDays = calendar.entries.values.filter { entry in
            switch calendar.trackingType {
            case .binary:
                return entry.completed
            case .counter, .multipleDaily:
                return entry.count > 0
            }
        }.count

        let totalCount = calendar.entries.values.reduce(0) { $0 + $1.count }
        let maxCount = calendar.entries.values.map { $0.count }.max() ?? 0

        let localCalendar = LocalDayCalendar.calendar
        let longestStreak = WidgetStreak.longestStreak(calendar: calendar, calendarSystem: localCalendar)
        let currentStreak = WidgetStreak.currentStreak(calendar: calendar, today: Date(), calendarSystem: localCalendar).streak

        return CalendarStats(
            activeDays: activeDays,
            totalCount: totalCount,
            maxCount: maxCount,
            longestStreak: longestStreak,
            currentStreak: currentStreak
        )
    }

    private var resolvedCurrentPeriodCount: Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        guard year == currentYear else { return 0 }
        let today = Calendar.current.startOfDay(for: Date())
        return entry(for: calendar, date: today)?.count ?? 0
    }
}

func availableShareTemplates(for calendar: CustomCalendar, today: Date) -> [CalendarShareTemplate] {
    let your365Snapshot = calendar.cadence == .daily
        ? calendar.makeYour365Snapshot(
            completedDates: your365CompletedDates(for: calendar),
            today: today
        )
        : nil

    return CalendarShareTemplate.allCases.filter { template in
        switch template {
        case .your365:
            return your365Snapshot != nil
        case .yearCard, .minimalGrid, .streakFocus, .performance:
            return true
        }
    }
}
