import SharedModels
import SwiftUI
import UIKit

struct AppleHealthImportPreviewSection: View {
  let metric: AppleHealthMetric
  let selectedColor: Color
  @Binding var dailyTarget: Int
  let previewValues: [Date: Int]?
  let isLoadingPreview: Bool
  let needsSettings: Bool
  let onRetry: () -> Void

  @Environment(\.openURL) private var openURL

  private var importedDayCount: Int {
    previewValues?.count ?? 0
  }

  private var completedDayCount: Int {
    guard let previewValues else { return 0 }
    return AppleHealthMetricEntryMapper.entries(from: previewValues, target: dailyTarget)
      .values
      .filter(\.completed)
      .count
  }

  private var averageValue: Int? {
    guard let values = previewValues?.values, !values.isEmpty else { return nil }
    return Int((Double(values.reduce(0, +)) / Double(values.count)).rounded())
  }

  private var targetSuggestions: [Int] {
    var suggestions = [metric.defaultTarget]
    if let averageValue, averageValue > 0 {
      suggestions.append(averageValue)
    }
    return Array(Set(suggestions))
      .filter { $0 > 0 }
      .sorted()
  }

  var body: some View {
    CustomSection(label: "Import Preview") {
      VStack(spacing: 2) {
        previewContent
      }
      .padding(.all, 2)
      .sameLevelGroupBackground()
    }
  }

  @ViewBuilder
  private var previewContent: some View {
    if isLoadingPreview {
      loadingRow
    } else if let previewValues {
      if previewValues.isEmpty {
        emptyRow
      } else {
        loadedPreviewRows
      }
    } else {
      retryRows
    }
  }

  private var loadingRow: some View {
    HStack(spacing: 8) {
      ProgressView()
        .tint(.textPrimary)
      Text("Reading Apple Health")
        .labelStyle(type: .secondary)
      Spacer()
    }
    .padding()
    .sameLevelBorder(isFlat: true)
  }

  private var emptyRow: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("No current-year data found.")
        .labelStyle(type: .secondary)
      Text("Yearlit needs at least one Apple Health value to create this Calendar.")
        .font(.footnote)
        .foregroundStyle(.textTertiary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .sameLevelBorder(isFlat: true)
  }

  @ViewBuilder
  private var loadedPreviewRows: some View {
    previewRow(title: "Imported days", value: importedDayCount.formatted(.number))
    previewRow(title: "Completed at target", value: completedDayCount.formatted(.number))
    if let averageValue {
      previewRow(title: "Average imported day", value: averageValue.formatted(.number))
    }

    if targetSuggestions.count > 1 {
      targetSuggestionsRow
    }
  }

  private var targetSuggestionsRow: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Target suggestions")
        .labelStyle(type: .secondary)

      HStack(spacing: 8) {
        ForEach(targetSuggestions, id: \.self) { target in
          Button {
            dailyTarget = target
          } label: {
            Text(target.formatted(.number))
              .font(.footnote.weight(.bold))
              .padding(.horizontal, 10)
              .padding(.vertical, 8)
              .frame(minWidth: 64)
          }
          .sameLevelBorder(isFlat: true)
          .foregroundStyle(target == dailyTarget ? selectedColor : .textSecondary)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .sameLevelBorder(isFlat: true)
  }

  private var retryRows: some View {
    VStack(spacing: 10) {
      Button("Retry Apple Health Import", action: onRetry)
        .frame(maxWidth: .infinity, alignment: .center)
        .fontWeight(.bold)
        .padding()
        .sameLevelBorder()

      if needsSettings {
        Button("Open Settings", action: openSettings)
          .frame(maxWidth: .infinity, alignment: .center)
          .fontWeight(.bold)
          .padding()
          .sameLevelBorder()
      }
    }
    .foregroundStyle(.textSecondary)
  }

  private func previewRow(title: LocalizedStringKey, value: String) -> some View {
    HStack {
      Text(title)
        .labelStyle(type: .secondary)
      Spacer()
      Text(value)
        .fontWeight(.bold)
        .foregroundStyle(.textPrimary)
    }
    .padding()
    .sameLevelBorder(isFlat: true)
  }

  private func openSettings() {
    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
    openURL(settingsURL)
  }
}
