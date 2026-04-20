import Foundation

#if os(iOS)
    import WidgetKit
#endif

public enum WidgetReload {
    private static let queue = DispatchQueue(label: "WidgetReload.debounce")
    private static var pendingWorkItem: DispatchWorkItem?
    private static var pendingKinds = Set<String>()
    private static var shouldReloadAll = false

    public enum Kind: CaseIterable {
        case year
        case habits
        case streak

        var widgetKind: String {
            switch self {
            case .year:
                WidgetKinds.year
            case .habits:
                WidgetKinds.habits
            case .streak:
                WidgetKinds.streak
            }
        }
    }

    public static func scheduleAllTimelinesReload(debounce: TimeInterval = 0.5) {
        #if os(iOS)
            queue.async {
                shouldReloadAll = true
                pendingKinds.removeAll()
                schedulePendingReload(debounce: debounce)
            }
        #endif
    }

    public static func scheduleReload(of kinds: Set<Kind>, debounce: TimeInterval = 0.5) {
        #if os(iOS)
            guard !kinds.isEmpty else { return }

            queue.async {
                guard !shouldReloadAll else {
                    schedulePendingReload(debounce: debounce)
                    return
                }

                pendingKinds.formUnion(kinds.map(\.widgetKind))
                schedulePendingReload(debounce: debounce)
            }
        #endif
    }

    public static func scheduleHabitWidgetsReload(debounce: TimeInterval = 0.5) {
        scheduleReload(of: [.habits, .streak], debounce: debounce)
    }

    public static func scheduleYearWidgetReload(debounce: TimeInterval = 0.5) {
        scheduleReload(of: [.year], debounce: debounce)
    }

    #if os(iOS)
        private static func schedulePendingReload(debounce: TimeInterval) {
            pendingWorkItem?.cancel()

            let workItem = DispatchWorkItem {
                if shouldReloadAll {
                    shouldReloadAll = false
                    pendingKinds.removeAll()
                    WidgetCenter.shared.reloadAllTimelines()
                    return
                }

                let kindsToReload = pendingKinds
                pendingKinds.removeAll()
                for kind in kindsToReload {
                    WidgetCenter.shared.reloadTimelines(ofKind: kind)
                }
            }

            pendingWorkItem = workItem
            queue.asyncAfter(deadline: .now() + debounce, execute: workItem)
        }
    #endif
}

public enum WidgetKinds {
    public static let year = "YearWidget"
    public static let habits = "HabitsWidget"
    public static let streak = "StreakWidget"
}
