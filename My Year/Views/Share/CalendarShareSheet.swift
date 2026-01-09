import Photos
import SharedModels
import SwiftUI
import UIKit

enum CalendarShareTemplate: String, CaseIterable, Identifiable {
  case yearCard
  case yearCardAlt

  var id: String { rawValue }

  var title: String {
    switch self {
    case .yearCard:
      return "Year Card"
    case .yearCardAlt:
      return "Year Card 2"
    }
  }

  var subtitle: String {
    switch self {
    case .yearCard:
      return "Full-year grid + stats"
    case .yearCardAlt:
      return "Alt layout preview"
    }
  }
}

struct CalendarShareSheet: View {
  let calendar: CustomCalendar
  let year: Int
  let dates: [Date]
  let statsBundle: StatsBundle?

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.dismiss) private var dismiss
  @State private var selectedTemplate: CalendarShareTemplate = .yearCard
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

        cardPager
          .frame(maxWidth: .infinity)

        Spacer(minLength: 12)

        actionButtons
          .padding(.bottom, 24)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
      .navigationTitle(selectedTemplate.title)
      .navigationBarTitleDisplayMode(.large)
    }
    .presentationDetents([.medium, .large])
    .sheet(isPresented: $isSharing) {
      if let image = shareImage {
        ActivityView(
          activityItems: [image, "yearlit • \(calendar.name.capitalized)"],
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

  private var cardPager: some View {
    TabView(selection: $selectedTemplate) {
      YearCardShareView(
        calendar: calendar,
        year: year,
        dates: dates,
        stats: resolvedStats,
        completionRate30d: resolvedCompletionRate,
        todaysCount: resolvedTodaysCount,
        trackingType: calendar.trackingType
      )
      .aspectRatio(4 / 5, contentMode: .fit)
      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
      .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
      .padding(.horizontal, 32)
      .padding(.vertical, 16)
      .tag(CalendarShareTemplate.yearCard)

      YearCardShareView(
        calendar: calendar,
        year: year,
        dates: dates,
        stats: resolvedStats,
        completionRate30d: resolvedCompletionRate,
        todaysCount: resolvedTodaysCount,
        trackingType: calendar.trackingType
      )
      .aspectRatio(4 / 5, contentMode: .fit)
      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
      .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
      .padding(.horizontal, 32)
      .padding(.vertical, 16)
      .tag(CalendarShareTemplate.yearCardAlt)
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
  }

  private var actionButtons: some View {
    HStack {
      HStack(spacing: 2) {

      Button(action: shareSelectedTemplate) {
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

  private var resolvedStats: CalendarStats {
    statsBundle?.basic ?? computeFallbackStats(for: calendar)
  }

  private var resolvedCompletionRate: Double {
    statsBundle?.completionRate30d ?? 0
  }

  private func shareSelectedTemplate() {
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
    let view = YearCardShareView(
      calendar: calendar,
      year: year,
      dates: dates,
      stats: resolvedStats,
      completionRate30d: resolvedCompletionRate,
      todaysCount: resolvedTodaysCount,
      trackingType: calendar.trackingType
    )
    return ShareImageRenderer.render(
      view: view,
      size: sharePointSize,
      colorScheme: colorScheme,
      scale: shareScale
    )
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

    var localCalendar = Calendar(identifier: .gregorian)
    localCalendar.locale = Locale(identifier: "en_US_POSIX")
    localCalendar.timeZone = .autoupdatingCurrent
    let allTimeSuccessByDay = buildAllTimeSuccessMap(
      cal: localCalendar,
      todayLocal: Date(),
      calendars: [calendar]
    )
    let (longestStreak, currentStreak) = computeStreaks(cal: localCalendar, allTimeSuccessByDay)

    return CalendarStats(
      activeDays: activeDays,
      totalCount: totalCount,
      maxCount: maxCount,
      longestStreak: longestStreak,
      currentStreak: currentStreak
    )
  }

  private var resolvedTodaysCount: Int {
    let currentYear = Calendar.current.component(.year, from: Date())
    guard year == currentYear else { return 0 }
    let today = Calendar.current.startOfDay(for: Date())
    return calendar.entries[dayKey(for: today)]?.count ?? 0
  }
}
