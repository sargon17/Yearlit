import Photos
import SharedModels
import SwiftUI
import UIKit

enum CalendarShareTemplate: String, CaseIterable, Identifiable {
  case yearCard

  var id: String { rawValue }

  var title: String {
    switch self {
    case .yearCard:
      return "Year Card"
    }
  }

  var subtitle: String {
    switch self {
    case .yearCard:
      return "Full-year grid + stats"
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
    VStack(spacing: 16) {
      header

      templatePicker

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
      .frame(maxWidth: .infinity)
      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
      .padding(.horizontal)

      actionButtons
    }
    .padding(.vertical, 12)
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

  private var header: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Share")
          .font(.system(size: 22, design: .monospaced))
          .foregroundColor(Color("text-primary"))
          .fontWeight(.bold)
        Text("Pick a template for \(calendar.name.capitalized)")
          .font(.system(size: 12, design: .monospaced))
          .foregroundColor(Color("text-tertiary"))
      }
      Spacer()
      Button("Close") {
        dismiss()
      }
      .font(.system(size: 12, design: .monospaced))
      .foregroundColor(Color("text-tertiary"))
    }
    .padding(.horizontal)
  }

  private var templatePicker: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(CalendarShareTemplate.allCases) { template in
          Button(action: { selectedTemplate = template }) {
            VStack(alignment: .leading, spacing: 6) {
              Text(template.title)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(Color("text-primary"))
                .fontWeight(.bold)
              Text(template.subtitle)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Color("text-tertiary"))
            }
            .padding(12)
            .frame(minWidth: 160, alignment: .leading)
            .background(
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(selectedTemplate == template ? Color("surface-primary") : Color("surface-muted"))
            )
            .overlay(
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                  selectedTemplate == template
                    ? Color(calendar.color).opacity(0.6)
                    : Color("devider-top").opacity(0.6),
                  lineWidth: 1
                )
            )
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal)
    }
  }

  private var actionButtons: some View {
    HStack(spacing: 12) {
      Button(action: shareSelectedTemplate) {
        HStack(spacing: 8) {
          Image(systemName: "square.and.arrow.up")
          Text("Share")
        }
        .font(.system(size: 14, design: .monospaced))
        .foregroundColor(Color("text-primary"))
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
      }
      .buttonStyle(.plain)
      .background(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(Color("surface-primary"))
      )

      Button(action: saveToPhotos) {
        HStack(spacing: 8) {
          Image(systemName: "square.and.arrow.down")
          Text("Save")
        }
        .font(.system(size: 14, design: .monospaced))
        .foregroundColor(Color("text-primary"))
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
      }
      .buttonStyle(.plain)
      .background(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(Color("surface-primary"))
      )
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
