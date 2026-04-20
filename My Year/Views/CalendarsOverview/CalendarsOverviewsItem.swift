//
//  CalendarsOverviewsItem.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 01/08/25.
//

import Garnish
import SharedModels
import SwiftDate
import SwiftUI

struct CalendarsOverviewsItem: View {
    let calendar: CustomCalendar
    @ObservedObject var store: CustomCalendarStore
    @State private var showDeleteConfirmation = false
    @Environment(\.colorScheme) private var colorScheme

    private let latestSlotsCount = 56
    private let rowsCount = 4
    private var localCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }

    private var todayStart: Date {
        localCalendar.startOfDay(for: today)
    }

    private var today: Date {
        Date()
    }

    var latestSlots: [Date] {
        let component: Calendar.Component = calendar.cadence == .weekly ? .weekOfYear : .day
        let anchor = calendar.cadence == .weekly ? LocalDayCalendar.startOfWeek(for: todayStart) : todayStart
        let start = localCalendar.date(byAdding: component, value: -(latestSlotsCount - 1), to: anchor) ?? anchor
        return (0 ..< latestSlotsCount).compactMap { offset in
            localCalendar.date(byAdding: component, value: offset, to: start)
        }
    }

    var body: some View {
        ui
            .modifier(
                ContextOrDragModifier(
                    calendar: calendar,
                    store: store,
                    showDeleteConfirmation: $showDeleteConfirmation
                )
            )
            .alert("Delete Calendar?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    store.deleteCalendar(id: calendar.id)
                    cancelNotifications(for: calendar)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete '\(calendar.name)'? This action cannot be undone.")
            }
    }
}

extension CalendarsOverviewsItem {
    var ui: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(calendar.name.capitalized)
                .font(.system(size: 14, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            latestSlotsView
                .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
                .aspectRatio(latestGridAspectRatio, contentMode: .fit)

            Text("[\(calendar.trackingType.description)]".lowercased())
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.trailing, 16)
    }

    var latestSlotsView: some View {
        GeometryReader { geometry in
            let spacing = 6.0
            let totalHeight = geometry.size.height
            let totalSpacing = spacing * max(CGFloat(rowsCount) - 1.0, 0.0)
            let itemSize = max(0, (totalHeight - totalSpacing) / CGFloat(rowsCount))
            let colors = latestSlotColors
            LazyHGrid(
                rows: Array(repeating: GridItem(.fixed(itemSize), spacing: spacing), count: rowsCount),
                spacing: spacing
            ) {
                ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                    VisualEntry(
                        width: itemSize,
                        color: color
                    )
                }
            }
        }
    }
}

extension CalendarsOverviewsItem {
    private var columnsCount: Int {
        max(1, Int(ceil(Double(latestSlotsCount) / Double(rowsCount))))
    }

    private var latestGridAspectRatio: CGFloat {
        CGFloat(columnsCount) / CGFloat(rowsCount)
    }

    private var latestSlotColors: [Color] {
        let cachePrefix = "\(calendar.id.uuidString)|"
        CacheStore.shared.removeMatching(scope: .overviewSlots) { identifier in
            identifier.hasPrefix(cachePrefix) && identifier != latestSlotsCacheIdentifier
        }

        let cacheKey = CacheKey(scope: .overviewSlots, identifier: latestSlotsCacheIdentifier)
        if let cached: [Color] = CacheStore.shared.get(cacheKey) { return cached }

        let colors = buildLatestSlotColors()
        CacheStore.shared.set(cacheKey, value: colors)
        return colors
    }

    private var latestSlotsCacheIdentifier: String {
        let snapshot = store.snapshot
        let daySeedKey = dayKey(for: todayStart)
        let schemeKey = colorScheme == .dark ? "dark" : "light"
        let timeZoneKey = TimeZone.autoupdatingCurrent.identifier
        return "\(calendar.id.uuidString)|\(snapshot.dataVersion)|\(calendar.cadence.rawValue)|\(daySeedKey)|\(latestSlotsCount)|\(schemeKey)|\(timeZoneKey)"
    }

    private func buildLatestSlotColors() -> [Color] {
        let inactiveColor = inactiveDayColor()
        let activeColor = activeDayColor()
        let maxCount = calendar.trackingType == .counter ? getMaxCount(calendar: calendar) : 1

        return latestSlots.map { day -> Color in
            let bucketDate = calendar.bucketDate(for: day)
            let todayBucket = calendar.bucketDate(for: todayStart)
            if bucketDate > todayBucket { return inactiveColor }
            guard let entry = calendar.entry(for: day) else { return activeColor }

            switch calendar.trackingType {
            case .binary:
                return entry.completed ? Color(calendar.color) : activeColor
            case .counter:
                if entry.count > 0 {
                    let ratio = max(0.1, Double(entry.count) / Double(max(maxCount, 1)))
                    return GarnishColor.blend(.surfaceMuted, with: Color(calendar.color), ratio: ratio)
                }
                return activeColor
            case .multipleDaily:
                if entry.count > 0 {
                    let opacity = min(1, max(0.2, Double(entry.count) / Double(calendar.dailyTarget)))
                    return Color(calendar.color).opacity(opacity)
                }
                return activeColor
            }
        }
    }
}

struct VisualEntry: View {
    let width: CGFloat
    let color: Color

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: width, height: width)
            .cornerRadius(2)
    }
}
